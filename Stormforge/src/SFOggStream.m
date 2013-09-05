//
//  SFOggStream.m
//  ZombieArcade
//
//  Created by Adam Iredale on 5/02/10.
//  Copyright 2010 Stormforge Software. All rights reserved.
//

#import "SFOggStream.h"
#import "SFUtils.h"
#import "SFDebug.h"

#define OGG_DEFAULT_PAGE_SIZE 4096;

@implementation SFOggStream

-(id)initWithSerial:(int)pageSerialNumber{
    self = [self initWithDictionary:nil];
    if (self != nil) {
        _pageSerialNo = pageSerialNumber;
        if (ogg_stream_init(&_streamState, pageSerialNumber) != 0){
            sfDebug(TRUE, "Error initialising ogg stream.");
        }
    }
    return self;
}

-(void)resetStream{
    sfDebug(TRUE, "Resetting stream %s...", [self UTF8Description]);
    ogg_stream_reset(&_streamState);
}

-(NSNumber*)serial{
    return [NSNumber numberWithInt:_pageSerialNo];
}

-(BOOL)addOggPage:(ogg_page*)page{
    //add a page of ogg data to our stream
    if (ogg_stream_pagein(&_streamState, page) != 0) {
        sfDebug(TRUE, "Error adding ogg page.");
        return NO;
    }
    sfDebug(TRUE, "Added page (hlen:%u blen:%u) to stream %u", page->header_len, page->body_len, _pageSerialNo);
    return YES;
}

-(ogg_stream_state*)streamState{
    return &_streamState;
}

-(int)getOggPacket:(ogg_packet*)packet{
    //read a packet from the stream so that
    //we can use it with vorbis or theora
    //to decode (woo hoo!)
    
    //return values:
    // -1: error - missing a page (gap in data)!
    // 0: need more pages for this packet
    // !0: ok - packet is ready
#if DEBUG_SFOGGSTREAM
    sfDebug(TRUE, "Stream#:%u", _pageSerialNo);
    sfDebug(TRUE, "PrePacketNo:%d", _streamState.packetno);
#endif
    int result = (ogg_stream_packetout(&_streamState, packet));
#if DEBUG_SFOGGSTREAM
    sfDebug(TRUE, "PostPacketNo:%d", _streamState.packetno);
switch (result) {
    case -1:
        sfDebug(TRUE, "Missing page!");
        break;
    case 0:
        sfDebug(TRUE, "Need more pages for this packet!");
        break;
    default:
        sfDebug(TRUE, "Returning OK packet...");
        break;
}    
#endif
    return result;
}

@end
