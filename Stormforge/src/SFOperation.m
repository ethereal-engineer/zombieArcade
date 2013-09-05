//
//  SFOperation.m
//  ZombieArcade
//
//  Created by Adam Iredale on 27/01/10.
//  Copyright 2010 Stormforge Software. All rights reserved.
//

#import "SFOperation.h"
#import "SFUtils.h"
#import "SFGameEngine.h"
#import "SFDebug.h"

@implementation SFOperation

-(BOOL)isConcurrent{
    return NO;
}

-(id)initWithTarget:(id)target selector:(SEL)sel object:(id)arg{
    self = [self init];
    if (self != nil) {
        _target = [target retain];
        _selector = sel;
        _implementation = [_target methodForSelector:_selector];
        imp = (void (*)(id, SEL, id))_implementation;
        if (arg != nil) {
            _object = [arg retain];
        }
#if DEBUG_SFOPERATION
        _preDesc = [[self description] retain];
#endif
    }
    return self;
}

-(void)setRequiresAL:(BOOL)requiresAL{
    _requiresAL = requiresAL;
}

-(BOOL)getRequiresAL{
    return _requiresAL;
}

#if DEBUG_SFOPERATION
-(NSString*)description{
    if (_preDesc) {
        return _preDesc;
    }
    id fmtString = @"%s, %s - (%s)";
    id targetString;
    if (_target == self) {
        targetString = @"self";
    } else {
        targetString = [_target description];
    }
    
	return [NSString stringWithFormat: fmtString, 
            			sel_getName(_selector),
			[targetString UTF8String],
            [[super description] UTF8String]];
}
#endif

-(id)init{
	
    static float gUniqueId = 0.0f;
    
    self = [super init];
    @synchronized([SFOperation class]){
        _uniqueId = gUniqueId;
        ++gUniqueId;
    }
    _threadPriority = 0.5;
	return self;
}

-(BOOL)getRequiresGl{
    return _requiresGl;
}

-(void)setThreadPriority:(float)priority{
    //only useful before we run...
    _threadPriority = priority;
}

-(void)setGlContext:(id)context{
    _useContext = [context retain];
}

-(void)main{
	NSAutoreleasePool *aPool;
    aPool = [[NSAutoreleasePool alloc] init];
    if (_threadPriority != THREAD_PRIORITY_NORMAL) {
        [NSThread setThreadPriority:_threadPriority];
    }
    //if (_requiresGl) {
    [EAGLContext setCurrentContext:[_useContext retain]];
    //}
    if (_requiresAL) {
        SFAL::instance()->ensureContext();
    }
#if DEBUG_SFOPERATION
    sfDebug(DEBUG_SFOPERATION, "Executing %s", [[self description] UTF8String]);
    u_int64_t compTime = [SFUtils getAppTime];
#endif
    imp(_target, _selector, _object);
#if DEBUG_SFOPERATION
    sfDebug(DEBUG_SFOPERATION, "Executed %s (%ums)", [[self description] UTF8String], [SFUtils getAppTimeDiff:compTime]);
#endif
#if DEBUG_SFOPERATION_COMPLETE
    sfDebug(DEBUG_SFOPERATION_COMPLETE, "Finishing %s", [[self description] UTF8String]);
    compTime = [SFUtils getAppTime];
#endif
    //de-prioritise the cleaning
    if (_threadPriority != THREAD_PRIORITY_NORMAL) {
        [NSThread setThreadPriority:THREAD_PRIORITY_NORMAL];
    }
#if DEBUG_SFOPERATION_COMPLETE
    compTime = [SFUtils getAppTimeDiff:compTime];
    sfDebug(DEBUG_SFOPERATION_COMPLETE, "%s Finished, cleaning+draining... (%ums)", [[self description] UTF8String], compTime);
    compTime = [SFUtils getAppTime];
#endif    
    [self cleanUp];
    //if (_requiresGl) {
    [EAGLContext setCurrentContext:nil];
    [_useContext release];
    // }
    [aPool drain];
#if DEBUG_SFOPERATION_COMPLETE
    compTime = [SFUtils getAppTimeDiff:compTime];
    NSAutoreleasePool *quickPool = [[NSAutoreleasePool alloc] init];
    sfDebug(DEBUG_SFOPERATION_COMPLETE, "%s Clean complete (%ums)", [[self description] UTF8String], compTime);
    [quickPool drain];
    [_preDesc release];
#endif
}

-(void)cleanUp{
    //top level
    [_target release];
    if (_object) {
        [_object release];
    }
#if DEBUG_SFOPERATION_COMPLETE == 0
    [_preDesc release];
#endif
}

-(void)setRequiresGl:(BOOL)requiresGl{
    _requiresGl = requiresGl;
}

@end
