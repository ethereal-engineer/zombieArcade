//
//  SFTheoraStream.m
//  ZombieArcade
//
//  Created by Adam Iredale on 25/02/10.
//  Copyright 2010 Stormforge Software. All rights reserved.
//

#import "SFTheoraDecoder.h"
#import "SFUtils.h"
#import "SFDebug.h"

#define THEORA_HEADER_COUNT 3

@implementation SFTheoraDecoder

-(id)initWithOggStream:(SFOggStream*)stream dictionary:(NSDictionary*)dictionary{
    self = [self initWithDictionary:dictionary];
    if (self != nil) {
        theora_info_init(&_theoraInfo);
        theora_comment_init(&_theoraComment);
        _stream = [stream retain];
    }
    return self;
}

-(void)cleanUp{
    [_stream release];
    _stream = nil;
    [super cleanUp];
}

-(void)markStreamAsNonTheora{
    //put a message in there so we can tell others
    [_stream setObjectInfo:@"YES" forKey:@"nonTheora"];
}

-(BOOL)decoderIsTarnished{
    return _decoderIsTarnished;
}

-(void)decodeHeaders{
    int headerResult, gotPacket;
    ogg_packet aPacket;
    
    do {
        //get a packet
        gotPacket = [_stream getOggPacket:&aPacket];
        if (gotPacket < 1) {
            //we can't get data for the header, so we aren't done yet
            //tell the fetcher to get more...
            sfDebug(TRUE, "Decoder needs more data for headers...");
            return;
        }
        headerResult = theora_decode_header(&_theoraInfo, &_theoraComment, &aPacket);
        if (headerResult == 0) {
            ++_headerCount;
            sfDebug(TRUE, "Read theora header %d/3", _headerCount);
        } else if (headerResult == OC_NOTFORMAT) {
            //this is NOT a theora stream - let it be known!
            sfDebug(TRUE, "This is not a theora stream!");
            //clean up the stream state so it can be
            //read by another decoder perhaps
            [self markStreamAsNonTheora];
            _decoderIsTarnished = YES;
            [_stream resetStream];
            return;
        } //otherwise we just move on...
    } while (_headerCount < THEORA_HEADER_COUNT);
    
    //once we are done reading the headers, we setup our data pointers etc
    if (theora_decode_init(&_stateInfo, &_theoraInfo) != 0) {
        sfDebug(TRUE, "Error initialising theora decoder.");
        _decoderIsTarnished = YES;
        [_stream resetStream];
        return; 
    }
    
    theora_control(&_stateInfo, TH_DECCTL_GET_PPLEVEL_MAX, &_lvlMax, sizeof(_lvlMax));
    _lvl = _lvlMax;
    theora_control(&_stateInfo, TH_DECCTL_SET_PPLEVEL, &_lvl, sizeof(_lvl));
    
    _frameRate = (_theoraInfo.fps_numerator / _theoraInfo.fps_denominator );
    
    sfDebug(TRUE, "Framerate is %f", _frameRate);
    
    //NOW the header is OK
    [self willChangeValueForKey:@"headersComplete"];
    _headersComplete = YES;
    [self didChangeValueForKey:@"headersComplete"];
}

-(float)frameRate{
    return _frameRate;
}

-(theora_info*)theoraInfo{
    return &_theoraInfo;
}

-(BOOL)decodeYUV:(yuv_buffer*)yuv{
    //decodes a single YUV buffer and returns
    
    ogg_packet aPacket;
	
    BOOL YUVReady = NO;
    int gotPacket;
    
    do {
        
        gotPacket = [_stream getOggPacket:&aPacket];
        if (gotPacket <= 0) {
            break;
        }
        
        if (_inc) {
            _lvl += _inc;
            
            theora_control(&_stateInfo, TH_DECCTL_SET_PPLEVEL, &_lvl, sizeof(_lvl));
            _inc = 0;
        }
        
        sfDebug(TRUE, "GranulePos was %d", _stateInfo.granulepos);
        
        if (aPacket.granulepos >= 0) {
            theora_control(&_stateInfo, TH_DECCTL_SET_GRANPOS, &aPacket.granulepos, sizeof(aPacket.granulepos));
        }
        
        sfDebug(TRUE, "GranulePos set to %d", _stateInfo.granulepos);
        
        if (theora_decode_packetin(&_stateInfo, &aPacket) == 0) {
            _v_time = (int)theora_granule_time( &_stateInfo, _stateInfo.granulepos );
            
            sfDebug(TRUE, "Granule time is %d", _v_time);
            
            ++_v_frame;
            
            if (theora_decode_YUVout(&_stateInfo, yuv ) != 0){
                sfDebug(TRUE, "Error decoding YUV output.");
            } else {
                sfDebug(TRUE, "Frame %d decoded to YUV ok", _v_frame);
                YUVReady = YES;
            }
        }
    } while (!YUVReady);
    return YUVReady;
}

-(BOOL)headersComplete{
    return _headersComplete;
}

-(BOOL)decodeStream:(void*)dataOut{
    yuv_buffer *yuv = (yuv_buffer*)dataOut;
    
    if (_decoderIsTarnished) {
        sfDebug(TRUE, "I should not be used - I am tarnished!");
        return NO;
    }
    //decodes the stream as much as we can
    if (_headerCount < THEORA_HEADER_COUNT){
        [self decodeHeaders];
        if (![self headersComplete]){
            return NO; //don't continue if we still haven't got headers
        };
    };
    //headers decoded, let's go with data...
	return [self decodeYUV:yuv];
}

@end
