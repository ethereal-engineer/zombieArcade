//
//  SFOggFile.m
//  ZombieArcade
//
//  Created by Adam Iredale on 24/02/10.
//  Copyright 2010 Stormforge Software. All rights reserved.
//

#import "SFOggFile.h"
#import "SFUtils.h"
#import "SFDebug.h"

#define OGG_DEFAULT_PAGE_SIZE 4096

@implementation SFOggFile

-(void)setupDecoders{
    //children to set up their decoders here as they will be used in the
    //next part of init...
}

-(id)initWithSFStream:(SFStream *)stream dictionary:(NSDictionary *)dictionary{
    self = [super initWithSFStream:stream dictionary:dictionary];
    if (self != nil) {
        _oggStreams = [[NSMutableDictionary alloc] init];
        [self setupDecoders];
        [self oggStreamsFromStream];
    }
    return self;
}

-(void)cleanUp{
    [_oggStreams release];
    [super cleanUp];
}

-(id)streamForPageSerial:(ogg_page*)page{
    //if it doesn't exist it will be created!
    int pageSerial = ogg_page_serialno(page);
    id pageSerialNumber = [NSNumber numberWithInt:pageSerial];
    id oggStream = [_oggStreams objectForKey:pageSerialNumber];
    if (!oggStream) {
        oggStream = [[SFOggStream alloc] initWithSerial:pageSerial];
        [_oggStreams setObject:oggStream forKey:pageSerialNumber];
        sfDebug(TRUE, "Added new stream %u to ogg file %s", pageSerial, [[self description] UTF8String]);
    }
    return oggStream;
}

-(BOOL)addOggPage:(ogg_page*)page{
    //adds a page to our stream list - if this is the beginning of a new stream,
    return [[self streamForPageSerial:page] addOggPage:page];
}

-(BOOL)syncBufferToOggPage{
    //dumps the sync buffer into an ogg page then adds it to our
    //page list IFF there is a full page - otherwise returns NO
    ogg_page page;
    if (ogg_sync_pageout(&_syncState, &page)) {
        return [self addOggPage:&page];
    }
    return NO;
}

-(int)readManyOggPages:(int)length{
    //reads as many ogg pages as possible from the length of bytes given
    ogg_page oggPage;
    
    int bytesRead, pagesRead = 0;
    
    sfDebug(TRUE, "Reading %u bytes into as many ogg pages as possible", length);

    //read data from the input stream into the sync buffer
    //until we can't read any more
    NSUInteger bufferLength = length;
    unsigned char *buffer = (unsigned char*)ogg_sync_buffer(&_syncState, bufferLength);
    bytesRead = _stream->read(buffer, bufferLength);
    if (bytesRead == 0) {
        //EOF
        sfDebug(TRUE, "Stream EOF...(this is ok)");
        return 0;
    } else {
        if (ogg_sync_wrote(&_syncState, bytesRead) != 0) {
            sfDebug(TRUE, "Error confirming bytes read.");
            return -1;
        }
    }
                
    while ([self syncBufferToOggPage]) {
        ++pagesRead;
    }; 
    
    sfDebug(TRUE, "%u pages read into file stream %s.", pagesRead, [self UTF8Description]);
    
    //return the actual bytes read
    return bytesRead;
}

-(void)oggStreamsFromStream{
    //init our sync state
    if (ogg_sync_init(&_syncState) != 0){
        sfDebug(TRUE, "Error initialising ogg sync.");
        return;
    }
}

@end
