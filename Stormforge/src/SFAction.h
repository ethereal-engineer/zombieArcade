//
//  SFAction.h
//  ZombieArcade
//
//  Created by Adam Iredale on 5/03/10.
//  Copyright 2010 Stormforge Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SFLoadableGameObject.h"
#import "SFDefines.h"

@interface SFAction : SFLoadableGameObject {
    
	unsigned int _bufferOffset, _currentFrame;
    unsigned int		_n_frame;
	unsigned int		_s_frame;
	SFFrameStruct		**_frames;
}

-(unsigned int)frameSize;
-(unsigned int)numFrames;
-(SFFrameStruct**)frames;

@end
