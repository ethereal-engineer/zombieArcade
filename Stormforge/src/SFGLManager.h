//
//  SFGLManager.h
//  ZombieArcade
//
//  Created by Adam Iredale on 15/02/10.
//  Copyright 2010 Stormforge Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SFGameSingleton.h"
#import "SFGL.h"
#import "SFStack.h"
#import "SFOperationQueue.h"

@interface SFGLManager : SFGameSingleton {
    //one place to manage the complexities of gl
    SFOperationQueue *_glQueue;
    EAGLContext *_baseContext;
    EAGLSharegroup *_shareGroup;
}
+(id)quickSharedContext;

@end
