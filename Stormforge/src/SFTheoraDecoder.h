//
//  SFTheoraStream.h
//  ZombieArcade
//
//  Created by Adam Iredale on 25/02/10.
//  Copyright 2010 Stormforge Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SFOggStream.h"
#import "SFObject.h"
#import "SFDefines.h"

@interface SFTheoraDecoder : SFObject {
    //ONE DECODER PER STREAM PLEASE!
    BOOL _decoderIsTarnished;
    int _headerCount;
    BOOL _headersComplete;
    theora_info _theoraInfo;
    theora_comment _theoraComment;
    theora_state _stateInfo;
    int _lvlMax, _lvl;
    int                 _inc;   
    float               _frameRate;
	int					_v_time;
	int					_v_frame;
    
    SFOggStream *_stream;
}

-(id)initWithOggStream:(SFOggStream*)stream dictionary:(NSDictionary*)dictionary;
-(BOOL)decodeStream:(void *)dataOut;
-(BOOL)headersComplete;
-(theora_info*)theoraInfo;
-(float)frameRate;

@end
