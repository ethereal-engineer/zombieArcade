//
//  SFGLManager.m
//  ZombieArcade
//
//  Created by Adam Iredale on 15/02/10.
//  Copyright 2010 Stormforge Software. All rights reserved.
//

#import "SFGLManager.h"
#import "SFUtils.h"
#import "SFGameEngine.h"

#define USE_ONE_CONTEXT 1

static SFGLManager *gSFGLManager = nil;

@implementation SFGLManager

-(id)initWithDictionary:(NSDictionary *)dictionary{
    self = [super initWithDictionary:dictionary];
    if (self != nil) {
        _glQueue = [[SFOperationQueue alloc] initQueue:YES];
        _baseContext = [SFGameEngine glContext];
        _shareGroup = [_baseContext sharegroup];
    }
    return self;
}

-(void)cleanUp{
    [_glQueue cleanUp];
    [_glQueue release];
    [super cleanUp];
}

-(id)newContext{
    return [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1 sharegroup:_shareGroup];
}

-(id)quickSharedContext{
    return [[self newContext] autorelease];
}

+(id)quickSharedContext{
    return [[self alloc] quickSharedContext];
}

+(SFGameSingleton**)getGameSingletonPointer{
    return &gSFGLManager;
}

@end
