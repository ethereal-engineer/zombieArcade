//
//  SFAction.m
//  ZombieArcade
//
//  Created by Adam Iredale on 5/03/10.
//  Copyright 2010 Stormforge Software. All rights reserved.
//

#import "SFAction.h"


@implementation SFAction

-(void)bufferFloats:(float*)floats floatCount:(int)floatCount jumpSize:(int)jumpSize{
    for (int i = 0; i < floatCount; ++i) {
        memcpy(&_frames[_currentFrame]->buf[_bufferOffset], &floats[i], sizeof(float));
        _bufferOffset += jumpSize;
    }
}

SFFrameStruct *frameInit( unsigned int frameNo,
                         unsigned int size )
{
	SFFrameStruct *frame = ( SFFrameStruct * )calloc( 1, sizeof( SFFrameStruct ) );
    
	frame->frame = frameNo;
    
	frame->buf = (unsigned char *)malloc(size);
    
	return frame;
}


SFFrameStruct *frameFree(SFFrameStruct *frame)
{
	free(frame->buf);
	frame->buf = NULL;
    
	free(frame);
    
	return NULL;
}

+(NSString*)fileDirectory{
    return @"action";
}

-(unsigned int)frameSize{
    return _s_frame;
}

-(unsigned int)numFrames{
    return _n_frame;
}

-(SFFrameStruct**)frames{
    return _frames;
}


-(BOOL)loadInfo:(SFTokens*)tokens{
    
    if (tokens->tokenIs("fv") or tokens->tokenIs("fn")) {
        //[self bufferFloatFromString:value jumpSize:4];
        [self bufferFloats:tokens->valueAsFloats(3) floatCount:3 jumpSize:4];
        return YES;
    }
    
    if (tokens->tokenIs("f")) {
        unsigned int frameNo = tokens->valueAsFloats(1)[0];
        ++_currentFrame;
        _frames[_currentFrame] = frameInit(frameNo, _s_frame);
        _bufferOffset = 0;
        return YES;
    }
    
    if (tokens->tokenIs("nf")) {
        float *floats = tokens->valueAsFloats(2);
        _n_frame = floats[0];
        _s_frame = floats[1];
        _frames = (SFFrameStruct**)malloc(_n_frame * sizeof(SFFrameStruct));
        _currentFrame = -1;
        return YES;
    }
    
	return NO;
}

-(void)render{
    
}

@end
