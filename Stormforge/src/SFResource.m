//
//  SFSIO2Resource.m
//  ZombieArcade
//
//  Created by Adam Iredale on 13/11/09.
//  Copyright 2009 Stormforge Software. All rights reserved.
//

#import "SFResource.h"
#import "SFUTils.h"
#import "SF3DObject.h"
#import "SFGameEngine.h"
#import "SFSound.h"
#import "SFMaterial.h"
#import "SFCamera.h"
#import "SFLamp.h"
#import "SFStreamObjectFactory.h"
#import "SFRagdoll.h"
#import "SFStream.h"
#import "SFDebug.h"

#define PRECACHE_ALL_STREAMS 1 //instead of reading from file, copy to memory first

@implementation SFResource

-(id)initWithDictionary:(NSDictionary*)dictionary{
	self = [super initWithDictionary:dictionary];
	if (self != nil) {
        _resourceQueue = [[SFOperationQueue alloc] initQueue:YES];
        [_resourceQueue setGlContext:[SFGameEngine glContext]];
        _loadTasks = [[SFStack alloc] initStack:NO useFifo:YES];
        _itemGroups = [[NSMutableDictionary alloc] init];
        id filename = [self objectInfoForKey:@"filename"];
        if (filename) {
            [self setName:[self objectInfoForKey:@"filename"]];
#if DEBUG_SFOPERATIONQUEUE
            [_resourceQueue setName:[@"resourceQ" stringByAppendingString:[self name]]];
#endif
        }
        _itemDictionaries = [[NSMutableDictionary alloc] init];
	}
	return self;
}

-(void)emptyResource{
    //empties everything but does not clean up
    [_itemDictionaries removeAllObjects];
    [_itemGroups removeAllObjects];
}

-(void)cleanItems{
    //run clean on all the items
    NSEnumerator *dictObjects = [_itemDictionaries objectEnumerator];
    for (id objectKind in dictObjects) {
        NSEnumerator *kindObjects = [objectKind objectEnumerator];
        for (id anObject in kindObjects) {
            [anObject cleanUp];
        }
        [objectKind removeAllObjects];
    }
    [_itemDictionaries removeAllObjects];
}

-(void)cleanUp{
    [_resourceQueue release];
    [self cleanItems];
    [_itemDictionaries release];
    [_itemGroups release];
    [_loadTasks release];
    //tell our resource manager that this resource can go
    [[self rm] removeResource:[self objectInfoForKey:@"filename"]];
    [super cleanUp];
}

-(NSMutableDictionary*)dictionaryForClass:(Class)itemClass{
    id dict = [_itemDictionaries objectForKey:itemClass];
	if (!dict) {
        //no change - create it!
        dict = [[NSMutableDictionary alloc] init];
        [_itemDictionaries setObject:dict forKey:itemClass];
        [dict release];
    }
    return dict;
}

-(void)printStats{
	sfDebug(DEBUG_SFRESOURCE, "%s Resource Stats:", [self UTF8Name]);
	sfDebug(DEBUG_SFRESOURCE, "============================");
	for (NSString *dictionaryKind in _itemDictionaries) {
        id dict = [_itemDictionaries objectForKey:dictionaryKind];
		sfDebug(DEBUG_SFRESOURCE, "%s: %u", [[dictionaryKind description] UTF8String], [dict count]);
        for (id objectName in dict) {
            sfDebug(DEBUG_SFRESOURCE, " * %s", [objectName UTF8String]);
        }
	}

}

-(void)bindAllImages{
	//for each material, bind the texture image to it
	NSEnumerator *enumerator = [[_itemDictionaries objectForKey:[SFMaterial class]] objectEnumerator];
	for (SFMaterial *mat in enumerator) {
		[mat bindImages:self];
	}

}

-(void)bindObjectIpos{
	NSEnumerator *enumerator = [[_itemDictionaries objectForKey:[SF3DObject class]] objectEnumerator];
	for (SF3DObject *object in enumerator) {
		[object bindIpo];//pass self when this is actually used
	}

}

//better code reuse if designed with common interfaces instead (later)
//also - we could group this better by doing all object binding, camera binding etc at once

-(void)bindCameraIpos{
	NSEnumerator *enumerator = [[_itemDictionaries objectForKey:[SFCamera class]] objectEnumerator];
	for (SFCamera *cam in enumerator) {
        [cam bindIpo];//pass self when this is actually used
	}

}

-(void)bindLampIpos{
	NSEnumerator *enumerator = [[_itemDictionaries objectForKey:[SFLamp class]] objectEnumerator];
	for (SFLamp *lamp in enumerator) {
        [lamp bindIpo];//pass self when this is actually used
	}

}

-(void)bindAllMaterials{
	//for all objects that have materials - bind them to the respective vertex groups
	NSEnumerator *enumerator = [[_itemDictionaries objectForKey:[SF3DObject class]] objectEnumerator];
	for (SF3DObject *object in enumerator) {
        [object bindMaterials:self];
	}	
}

-(void)precacheAll{
	NSEnumerator *enumerator = [[_itemDictionaries objectForKey:[SF3DObject class]] objectEnumerator];
	for (SF3DObject *object in enumerator) {
        [object precache];
	}    
}

-(void)bindAllMatrix{
	//matrices... but whatever - apply the matrix that each object has
	NSEnumerator *enumerator = [[_itemDictionaries objectForKey:[SF3DObject class]] objectEnumerator];
	for (SF3DObject *object in enumerator) {
		[object transform]->compileMatrix();
	}

}

-(NSString*)archiveGetCurrentFileNameAndInfo:(unzFile)archive fileInfo:(unz_file_info*)fileInfo{
    char fileName[SF_MAX_CHAR] = {""}; //zero a buffer quickly
    unzGetCurrentFileInfo(archive,
                          fileInfo,
                          fileName,
                          SF_MAX_CHAR,
                          NULL, 0,
                          NULL, 0 );
    return [NSString stringWithUTF8String:fileName];
}

-(BOOL)archiveContainedFileIsNonZero:(unz_file_info)fileInfo{
    return fileInfo.uncompressed_size > 0;
}

-(SFStream*)archiveGetCurrentFileAsStream:(unzFile)archive 
                                      uncompressedSize:(size_t)uncompressedSize 
                                      filename:(NSString*)filename 
                            useNativeStreaming:(BOOL)useNativeStreaming{

    if( unzOpenCurrentFilePassword(archive, NULL ) != UNZ_OK ){
        sfDebug(DEBUG_SFRESOURCE, "Unable to extract file.");
        unzClose(archive);
        return nil;
    }
    
    SFStream *aStream;
    
    if (useNativeStreaming) {
        //native streaming extracts the file to a temporary directory then
        //streams it from there as required - useful for LOW memory situations
        //or large files
        id tempFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:filename];
        
        //if the file has already been extracted we can skip extraction!
        NSDictionary *tempFileInfo = [[NSFileManager defaultManager] attributesOfItemAtPath:tempFilePath error:NULL];
        if ((!tempFileInfo) or ([[tempFileInfo objectForKey:NSFileSize] intValue] != uncompressedSize)) {
            
            [[NSFileManager defaultManager] createDirectoryAtPath:[tempFilePath stringByDeletingLastPathComponent]
                                      withIntermediateDirectories:YES
                                                       attributes:nil
                                                            error:NULL];
            
            NSOutputStream *unzippedFile = [[NSOutputStream alloc] initToFileAtPath:tempFilePath append:NO];
            
            [unzippedFile open];
            
            uint8_t buffer[8096];
            int bytesRead;
            
            unsigned int maxReadSize = MIN(8096, uncompressedSize);
            
            do {
                bytesRead = unzReadCurrentFile(archive, &buffer, maxReadSize);
                if (bytesRead > 0) {
                    [unzippedFile write:(const uint8_t*)&buffer maxLength:bytesRead];
                }
            } while (bytesRead > 0);
            
            [unzippedFile close];
            [unzippedFile release];
        }
        //THEN we stream the extracted file
        aStream = new SFStream();
        aStream->openFile((char*)[tempFilePath UTF8String]);
    } else {
        aStream = new SFStream();
        aStream->openBuffer((char*)[filename UTF8String], uncompressedSize);
        unsigned char *buffer = aStream->readPtr(0);
        while(unzReadCurrentFile(archive, buffer, uncompressedSize) > 0 ){};
    }

    unzCloseCurrentFile(archive);
    
    return aStream;
}


-(BOOL)archiveMoveToNextFile:(unzFile)archive{
    return (unzGoToNextFile(archive) == UNZ_OK);
}

-(void)removeMemoryItem:(id)object{
    //just remove the object from our stores
    [[self dictionaryForClass:[object class]] removeObjectForKey:[object name]];
}

-(void)addLoadTask:(SEL)sel object:(id)obj{
    SFOperation *opLoadTask = [[SFOperation alloc] initWithTarget:self
                                                         selector:sel
                                                           object:obj];
    [_loadTasks push:opLoadTask];
    [opLoadTask release];
    //this will be released later once achieved
}

-(void)setupLoadTasks{
    //set up tasks to be taken a bit at a time
    unz_global_info archiveInfo;
    
	unzFile archive = [self archiveOpen:&archiveInfo];
    if (!archive) {
        return;
    }
    
    [self archiveMoveToFirstFile:archive];
    
    //create a job for each file to be created into an object
    //this allows the loading screen to get a refresh in every now and then
    for (int i = 0; i < archiveInfo.number_entry; ++i) {
        [self addLoadTask:@selector(extractSingleItem:) object:[NSValue valueWithPointer:archive]];
    }
    
    //then set up jobs for binding etc
    
    //images
    [self addLoadTask:@selector(bindAllImages) object:nil];
    
    //ipos
	[self addLoadTask:@selector(bindObjectIpos) object:nil];
	[self addLoadTask:@selector(bindCameraIpos) object:nil];
    [self addLoadTask:@selector(bindLampIpos) object:nil];
	
    //materials
    [self addLoadTask:@selector(bindAllMaterials) object:nil];
    [self addLoadTask:@selector(bindAllMatrix) object:nil];
}

-(BOOL)isReady{
    return _fullyLoaded;
}

-(BOOL)loadDelta{
    //we should load a little of all things unless we are fully loaded
    if (_fullyLoaded) {
        return NO;
    }
    if (!_loadTasksSetupOk) {
        [self setupLoadTasks];
        _loadTasksSetupOk = YES;
    }
    if (![_loadTasks isEmpty]) {
        //if there is a load op waiting we must handle it carefully as it is designed to
        //explode after use
        SFOperation *operation = [[_loadTasks peek] retain];
        [_loadTasks pop];
        [_resourceQueue addOperation:operation priority:NSOperationQueuePriorityNormal];
        [operation release];
        //wait for the tasks to complete...
        [_resourceQueue waitUntilAllOperationsAreFinished];
    } else {
        [_resourceQueue cleanUp];
        _fullyLoaded = YES;
    }
    return YES;
}

-(NSArray*)getItemGroup:(NSString*)groupPrefix{
    //check if we have loaded this group before
    return [_itemGroups objectForKey:groupPrefix];
}

-(id)loadItemGroup:(NSString*)itemPrefix itemClass:(Class)itemClass{
    
	//gets as many items as it can find of the format <itemPrefix><integer>.<fileextension>
	//that have been bundled into these resources
	
	sfDebug(DEBUG_SFRESOURCE, "Preloading item group %s...", [itemPrefix UTF8String]);
	
	unsigned int iCountId = 0;

	id anItem;
	
	NSMutableArray *itemArray = [[[NSMutableArray alloc] init] autorelease];
	
	do {
        //we don't want the dir at this stage...(lastpathcomponent)
		anItem = [[self getItem:[[itemClass fileName:itemPrefix offset:iCountId] lastPathComponent]
                     itemClass:itemClass
                       tryLoad:YES] retain];
		
		if (anItem) {
			[itemArray addObject:anItem];
		}
		[anItem release];
		++iCountId;
		//keep going until the number chain is broken
	} while (anItem != nil);
	
	[_itemGroups setObject:itemArray forKey:itemPrefix];
    return itemArray;
}

-(NSArray*)getItemGroup:(NSString*)groupPrefix itemClass:(Class)itemClass{
    id group = nil;
   // @synchronized(_itemGroups){
        group = [self getItemGroup:groupPrefix];
        if (!group) {
            group = [self loadItemGroup:groupPrefix itemClass:itemClass];
        }
   // }
    return group;
}

-(id)getItemFromMemory:(NSString*)itemName itemClass:(Class)itemClass{
	return [[self dictionaryForClass:itemClass] objectForKey:itemName];
}

-(void)archiveMoveToFirstFile:(unzFile)archive{
    unzGoToFirstFile(archive);
}

-(unzFile)archiveOpen:(unz_global_info*)archiveInfo{
    char *archiveFile = (char*)[[SFUtils getFilePathFromBundle:[self name]] UTF8String];
    unzFile archive = unzOpen(archiveFile);
	sfAssert(archive != nil, "Unable to open archive %s\n", archiveFile);
    unzGetGlobalInfo(archive, archiveInfo);
    return archive;
}

-(void*)archiveClose:(unzFile)archive{
    unzClose(archive);
    return nil;
}

-(BOOL)archiveJumpToFile:(unzFile)archive filename:(NSString*)filename{
    return (unzLocateFile(archive, [filename UTF8String], 1 ) == UNZ_OK);
}

-(void)addMemoryItem:(id)newItem{
    //add an item loaded from disk so it is now readily available
    [[self dictionaryForClass:[newItem class]] setObject:newItem forKey:[newItem name]];
}

-(void)duplicateMemoryItem:(NSString*)itemName itemClass:(Class)itemClass count:(int)count{
    //make a duplicate of one of our in-memory items and give it a unique name
    //- if it isn't yet loaded, load the original THEN duplicate it
    id originalItem = [self getItem:itemName itemClass:itemClass tryLoad:YES];
    sfAssert(originalItem != nil, "No original item to duplicate!");
    for (int i = 0; i < count; ++i) {
        NSString *newItemName = [[originalItem name] stringByAppendingFormat:@"%u", i];
        id duplicateItem = [originalItem copy];
        [duplicateItem setName:newItemName];
        [self addMemoryItem:duplicateItem];    
    }
}

-(void)extractSingleItem:(NSValue*)archiveValue{
    unzFile archive = [archiveValue pointerValue];
    
    unz_file_info fileInfo;
    NSString *fileName = [self archiveGetCurrentFileNameAndInfo:archive
                                                       fileInfo:&fileInfo];
    //skip 0 byte files
    if (![self archiveContainedFileIsNonZero:fileInfo]) {
        return;
    }
    SFStream *aStream = [self archiveGetCurrentFileAsStream:archive
                                            uncompressedSize:fileInfo.uncompressed_size
                                                    filename:fileName
                                          useNativeStreaming:NO];
    if (aStream) {
        id newObject = [SFStreamObjectFactory newObjectFromStream:aStream dictionary:nil];
        [self addMemoryItem:newObject];
        [newObject release];
        aStream = NULL; //the factory/object must decide (on freeing) as they may need streaming...
    }
    
    //move to the next file or close the archive
    //obviously this must be done sequentially
    if (![self archiveMoveToNextFile:archive]){
        [self archiveClose:archive];
    }
}

-(SFStream*)itemFromArchive:(NSString*)filename itemClass:(Class)itemClass dictionary:(NSDictionary*)dictionary{
    
    unz_global_info archiveInfo;
    
	unzFile archive = [self archiveOpen:&archiveInfo];
    if (!archive) {
        return nil;
    }
    
	if (![self archiveJumpToFile:archive filename:filename]){
        sfDebug(DEBUG_SFRESOURCE, "Can't find %s in archive %s.", [filename UTF8String], [[self objectInfoForKey:@"filename"] UTF8String]);
        [self archiveClose:archive];
        return nil;
    }
    sfDebug(DEBUG_SFRESOURCE, "Found %s in archive %s.", [filename UTF8String], [[self objectInfoForKey:@"filename"] UTF8String]);
    
    unz_file_info fileInfo;
    NSString *fileName = [self archiveGetCurrentFileNameAndInfo:archive fileInfo:&fileInfo];
    SFStream *aStream = [self archiveGetCurrentFileAsStream:archive
                                           uncompressedSize:fileInfo.uncompressed_size
                                                   filename:fileName
                                         useNativeStreaming:[dictionary objectForKey:@"nativeStreaming"] != nil];
    archive = [self archiveClose:archive];
    return aStream;
}

-(BOOL)isArchivedResource{
    //it's an archive if it has an extension in the filename
    return ![[[self objectInfoForKey:@"filename"] pathExtension] isEqualToString:@""];
}

-(id)getItemFromDisk:(NSString*)filename itemClass:(Class)itemClass dictionary:(NSDictionary*)dictionary{
    //fetches an item from the disk archives
    //or directly from disk
    
	if (!filename) {
		return nil;
	}
    
    SFStream *aStream = nil;
    
    if ([self isArchivedResource]) {
        aStream = [self itemFromArchive:filename itemClass:itemClass dictionary:dictionary];
    } else {
        NSString *fullFileName = [SFUtils getFilePathFromBundle:[filename lastPathComponent]];
        if (fullFileName) {
            aStream = new SFStream();
            aStream->openFile((char*)[fullFileName UTF8String]);
#if PRECACHE_ALL_STREAMS
            aStream->bufferEntireFile();
#endif
        }
    }

    
    if (!aStream) {
        return nil;
    }
    
    //all compatible classes have this initializer and it is their responsibility
    //to eventually free the stream
    id newItem = [SFStreamObjectFactory newObjectFromStream:aStream dictionary:dictionary classOverride:itemClass];
    
    //wash our hands of the stream
    aStream = NULL;
    
    //add to us
    [self addMemoryItem:newItem];
    //[[[self sm] currentScene] addMemoryItem:newItem];
    
    //this item was loaded on demand - tell it to resolve it's dependencies
    [newItem resolveDependantItems:self];
    
    [newItem release];
    //return our shiny new toy
    return newItem;
}

-(id)getItemEnumerator:(Class)itemClass{
    return [[self dictionaryForClass:itemClass] objectEnumerator];
}

-(id)getItem:(NSString*)itemName itemClass:(Class)itemClass tryLoad:(BOOL)tryLoad dictionary:(NSDictionary*)dictionary{
    id gotItem = [self getItemFromMemory:itemName itemClass:itemClass];
    if (gotItem == nil){
        if (tryLoad) {
            gotItem = [self getItemFromDisk:[itemClass fileName:itemName] itemClass:itemClass dictionary:nil];
        }
    }
    return gotItem;
}

-(id)getItem:(NSString*)itemName itemClass:(Class)itemClass tryLoad:(BOOL)tryLoad{
    return [self getItem:itemName itemClass:itemClass tryLoad:tryLoad dictionary:nil];
}

-(id)getItem:(NSString*)itemName itemClass:(Class)itemClass{
    return [self getItem:itemName itemClass:itemClass tryLoad:NO];
}

//convenience
-(id)get3DObject:(NSString*)objectName{
    return [self getItem:objectName itemClass:[SF3DObject class] tryLoad:NO];
}

@end
