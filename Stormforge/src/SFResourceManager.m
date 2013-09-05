//
//  SFSIO2ResourceManager.m
//  ZombieArcade
//
//  Created by Adam Iredale on 7/12/09.
//  Copyright 2009 Stormforge Software. All rights reserved.
//

#import "SFResourceManager.h"
#import "SFResource.h"
#import "SFUtils.h"
#import "SFSound.h"
#import "SFDebug.h"
#import "SFStreamObjectFactory.h"

static SFResourceManager *gSFResourceManager = NULL;

@implementation SFResourceManager

-(id)init
{
	self = [super init];
	if (self != nil) {
        _resources = [[NSMutableDictionary alloc] init];
        _blackList = [[NSMutableDictionary alloc] init];
        _itemGroups = [[NSMutableDictionary alloc] init];
	}
	return self;
}

-(NSArray*)getItemGroup:(NSString*)groupPrefix itemClass:(Class)itemClass{
    id group = nil;
    //@synchronized(_itemGroups){
        group = [self getItemGroup:groupPrefix];
        if (!group) {
            group = [self loadItemGroup:groupPrefix itemClass:itemClass];
        }
   // }
    return group;
}

-(NSArray*)getItemGroup:(NSString*)groupPrefix{
    //check if we have loaded this group before
    return [_itemGroups objectForKey:groupPrefix];
}

-(void)removeItem:(NSObject *)item{
    //if this item exists in our resources, remove it from memory
    NSArray *resources = [[self getResourcesForClass:[item class]] retain];
    NSEnumerator *enumerator = [resources objectEnumerator];
    for (NSDictionary *resourceInfo in enumerator) {
		SFResource *resource = [self getResourceWithDictionary:resourceInfo];
        [resource removeMemoryItem:item];
    }
    [resources release];
}

-(id)loadItemGroup:(NSString*)itemPrefix itemClass:(Class)itemClass{
    
	//gets as many items as it can find of the format <itemPrefix><integer>.<fileextension>
	//that have been bundled into these resources
	
	sfDebug(DEBUG_SFRESOURCEMANAGER, "Preloading meta object group %s...", [itemPrefix UTF8String]);
    
    NSMutableArray *metaGroup = [[NSMutableArray alloc] init];
    
	NSArray *_resourcesForType = [self getResourcesForClass:itemClass];
	NSEnumerator *enumerator = [_resourcesForType objectEnumerator];
    //first check preloaded
	for (NSDictionary *resourceInfo in enumerator) {
		SFResource *resource = [self getResourceWithDictionary:resourceInfo];
		if (resource) {
            id resourceGroup = [resource getItemGroup:itemPrefix itemClass:itemClass];
            if (resourceGroup){
                [metaGroup addObjectsFromArray:resourceGroup];
            }
        } else {
			sfDebug(DEBUG_SFRESOURCEMANAGER, "Error retreiving resource %s!", [[resourceInfo description] UTF8String]);
		}
	}
    [_itemGroups setObject:metaGroup forKey:itemPrefix];
    [metaGroup release];
    return metaGroup;
}

-(void)addRequestToBlackList:(NSString*)itemName itemClass:(Class)itemClass{
    //if an item has been requested and found not to exist then we don't want to
    //search through all the files on disk every time it is requested (such as optional
    //image files etc).  Instead, the request will be added to a blacklist
    //so that if it is requested again, we quickly return nil and do no
    //further processing
    [_blackList setObject:itemClass forKey:itemName];
}

-(BOOL)requestIsBlacklisted:(NSString*)itemName itemClass:(Class)itemClass{
    id blackListItem = [_blackList objectForKey:itemName];
    if (!blackListItem) {
        return NO;
    }
    return blackListItem  == itemClass;
}

-(NSArray*)getResourcesForClass:(Class)itemClass{
	//because we can have multiple resources for a given type
	//we find all the resources registered for this type and
	//return their dictionaries 
	return [[self gi] getResourceArray:itemClass];
}

-(id)newOnceOffItemFromDisk:(NSString*)filename itemClass:(Class)itemClass dictionary:(NSDictionary*)dictionary{
    //in the case that we want to load an item from disk and don't want it 
    //to be re-used by anyone else but ourselves (and then we free it)
    //use this routine - good for scene music and other once-offs
    SFStream *aStream;
    
    NSString *fullFileName = [SFUtils getFilePathFromBundle:[filename lastPathComponent]];
    if (fullFileName) {
        aStream = new SFStream();
        aStream->openFile((char*)[fullFileName UTF8String]);
#if PRECACHE_ALL_STREAMS
        aStream->bufferEntireFile();
#endif
    }

    sfAssert(aStream != nil, "Unable to find once-off item %s", [fullFileName UTF8String]);

    //all compatible classes have this initializer and it is their responsibility
    //to eventually free the stream
    return [SFStreamObjectFactory newObjectFromStream:aStream dictionary:dictionary classOverride:itemClass];
}

-(id)getItem:(NSString*)itemName itemClass:(Class)itemClass tryLoad:(BOOL)tryLoad dictionary:(NSDictionary*)dictionary{
    //provided we have a non-nil item name, this routine will search
	//all resources that have expressed an interest in the item type
	//that is, all resources that have this kind of item type in them
    
    //thread safe for fast access
    
    //might make this even faster later with a most used objects cache
    
	if ((!itemName) or ([self requestIsBlacklisted:itemName itemClass:itemClass])) {
		return nil;
	}
    
	id gotItem = nil;
	NSArray *resourcesForType = [self getResourcesForClass:itemClass];
	NSEnumerator *enumerator = [resourcesForType objectEnumerator];
    //first check preloaded
	for (NSDictionary *resourceInfo in enumerator) {
		SFResource *resource = [self getResourceWithDictionary:resourceInfo];
		if (resource) {
            @synchronized(resource){
                gotItem = [[resource getItemFromMemory:itemName itemClass:itemClass] retain];
            }
            if (gotItem) {
                sfDebug(DEBUG_SFRESOURCEMANAGER, "Got %s from memory", [itemName UTF8String]);
                break;
            }
        } else {
			sfDebug(DEBUG_SFRESOURCEMANAGER, "Error retreiving resource %s!", [[resourceInfo description] UTF8String]);
		}
	}
   // gotItem = [[[[self sm] currentScene] getItemFromMemory:itemName itemClass:itemClass] retain];
    //if we didn't get it from preloaded, try loading it (if allowed)
    if ((!gotItem) and (tryLoad)) {
        //refresh the enumerator
        enumerator = [resourcesForType objectEnumerator];
        for (NSDictionary *resourceInfo in enumerator) {
            SFResource *resource = [self getResourceWithDictionary:resourceInfo];
            if (resource) {
                @synchronized(resource){
                    gotItem = [[resource getItemFromMemory:itemName itemClass:itemClass] retain];
                   // gotItem = [[[[self sm] currentScene] getItemFromMemory:itemName itemClass:itemClass] retain];
                    if (gotItem){
                        sfDebug(DEBUG_SFRESOURCEMANAGER, "%s was loaded while waiting...", [itemName UTF8String]);
                        break;
                    }
                    gotItem = [[resource getItemFromDisk:[itemClass fileName:itemName]
                                                  itemClass:itemClass 
                                                 dictionary:dictionary] retain];
                }
                if (gotItem) {
                    sfDebug(DEBUG_SFRESOURCEMANAGER, "Got %s from disk", [itemName UTF8String]);
                    break;
                }
            }
        }
    }
	
	if (!gotItem) {
		if (tryLoad) {
			sfDebug(DEBUG_SFRESOURCEMANAGER, "Item %s not found in any relevant resource (disk included) - ITEM BLACKLISTED", [itemName UTF8String]);
            [self addRequestToBlackList:itemName itemClass:itemClass];
		} else {
			sfDebug(DEBUG_SFRESOURCEMANAGER, "Item %s not found preloaded in any relevant resource", [itemName UTF8String]);
		}
	}
	[gotItem release];
	return gotItem;
}

-(id)getItem:(NSString*)itemName itemClass:(Class)itemClass tryLoad:(BOOL)tryLoad{
    return [self getItem:itemName itemClass:itemClass tryLoad:tryLoad dictionary:nil];
}

-(id)getItem:(NSString*)itemName itemClass:(Class)itemClass{
    //by default, no load is tried
    return [self getItem:itemName itemClass:itemClass tryLoad:NO];
}

-(void)clearitemGroups{
    @synchronized(_itemGroups){
        [_itemGroups removeAllObjects];
    }
}

-(void)cleanUp{
    NSArray *cleanResources;
    @synchronized(_resources){
        cleanResources = [NSArray arrayWithArray:[_resources allValues]];
    }
    for (id resource in cleanResources){
        [resource cleanUp];
    }
    @synchronized(_blackList){
        [_blackList removeAllObjects];
    }
    [_resources release];
    [_itemGroups release];
    [_blackList release];
    [super cleanUp];
}

-(void)removeResource:(id)resourceKey{
    //when a resource is cleaned up, we should remove it from here so it can be recreated later
    //we should also clear all object groups
    if (!resourceKey) {
        return;
    }
    @synchronized(_resources){
        [_resources removeObjectForKey:resourceKey];
    }
    [self clearitemGroups];
}

-(id)getResourceWithDictionary:(NSDictionary*)resourceInfo{
	//we will assume that the resource info dictionary has the key: filename in it
	//and use the fiename as our way of indexing
    SFResource *resource;
	@synchronized(_resources){
        resource = [_resources objectForKey:[resourceInfo objectForKey:@"filename"]];
        
        if (!resource) {	
            //the resource hasn't yet been loaded from disk
            //so we create it and load it here
            id altClass = [resourceInfo objectForKey:@"objectClass"];
            if (altClass) {
                resource = [[[SFUtils getNamedClassFromBundle:altClass] alloc] initWithDictionary:resourceInfo];
            } else {
                resource = [[SFResource alloc] initWithDictionary:resourceInfo];
            }
            
            //and add it for future use
            [_resources setObject:resource forKey:[resourceInfo objectForKey:@"filename"]];
            [resource release];
        }
    }
	return resource;
}

-(void)flushResources{
    //empty them all
    //this should happen between scenes
    [_resources removeAllObjects];
    [_itemGroups removeAllObjects];
}

+(SFGameSingleton**)getGameSingletonPointer{
	return &gSFResourceManager;
}

@end
