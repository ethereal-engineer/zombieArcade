//
//  SFOggStream.h
//  ZombieArcade
//
//  Created by Adam Iredale on 5/02/10.
//  Copyright 2010 Stormforge Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SFObject.h"
#import "ogg.h"
#import "SFStream.h"

#define DEBUG_SFOGGSTREAM 0

@interface SFOggStream : SFObject {
    int _pageSerialNo;
    ogg_stream_state _streamState;
}

-(id)initWithSerial:(int)pageSerialNumber;
+(NSDictionary*)streamToOggStreams:(NSStream*)inStream;
+(NSDictionary*)fileToOggStreams:(NSString *)fileName;
-(int)read:(SFStream*)stream length:(int)length;
-(int)getOggPacket:(ogg_packet*)packet;
-(ogg_stream_state*)streamState;
-(NSNumber*)serial;
-(void)resetStream;
@end
