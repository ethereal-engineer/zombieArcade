//
//  SFVideo.h
//  ZombieArcade
//
//  Created by Adam Iredale on 24/02/10.
//  Copyright 2010 Stormforge Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SFOggFile.h"
#import "SFProtocol.h"
#import "SFImage.h"
#import "SFOggStream.h"
#import "SFTheoraDecoder.h"

#define SF_VIDEO_BUFFER             2
#define SF_VIDEO_BUFFER_BITS		3
#define SF_VIDEO_BUFFER_SIZE		8092

@interface SFVideo : SFOggFile {
    
    NSMutableDictionary *_decoders;
    
    SFImage *_currentFrame;
    
    BOOL _isPlaying, _repeat, _lastPage, _streamBuffered, _needFrame, _hasFrame;
    
	float				_d_time;
	float				_t_ratio;
    
	float				_u_time;
	float				_u_ratio;
    
	unsigned char		*_buf[SF_VIDEO_BUFFER];
    
    id  _videoDecoder;
    
	int					_b0[ SF_MAX_PATH ];
	int					_b1[ SF_MAX_PATH ];
	int					_b2[ SF_MAX_PATH ];
	int					_b3[ SF_MAX_PATH ];
}

-(BOOL)nextFrame;
-(BOOL)bufferStream:(id)stream;

@end
