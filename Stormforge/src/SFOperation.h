//
//  SFOperation.h
//  ZombieArcade
//
//  Created by Adam Iredale on 27/01/10.
//  Copyright 2010 Stormforge Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SFDefines.h"

#define DEBUG_SFOPERATION 0
#define DEBUG_SFOPERATION_COMPLETE 0

@interface SFOperation : NSOperation {
	NSMutableDictionary *_debugReport;
    id _target;
    IMP _implementation;
    SEL _selector;
    id _object;
    void (*imp)(id, SEL, id);
    BOOL _executing, _finished, _requiresGl, _requiresAL;
    float _uniqueId;
    float _threadPriority;
    id _useContext;
    int _notReadyCount;
    NSString *_preDesc;
}

-(id)initWithTarget:(id)target selector:(SEL)sel object:(id)arg;

-(void)cleanUp;
-(void)setRequiresGl:(BOOL)requiresGl;
-(BOOL)getRequiresGl;
-(void)setRequiresAL:(BOOL)requiresAL;
-(BOOL)getRequiresAL;
-(void)setThreadPriority:(float)priority;
-(void)setGlContext:(id)context;

@end
