//
//  SFOperationQueue.m
//  ZombieArcade
//
//  Created by Adam Iredale on 22/03/10.
//  Copyright 2010 Stormforge Software. All rights reserved.
//

#import "SFOperationQueue.h"
#import "SFUtils.h"

@implementation SFOperationQueue

-(id)initQueue:(BOOL)serialOnly cancelOnClean:(BOOL)cancelOnClean{
    self = [self initWithDictionary:nil];
    if (self != nil) {
        _queue = [[NSOperationQueue alloc] init];
        if (serialOnly) {
            [_queue setMaxConcurrentOperationCount:1];
        }
        _cancelOnClean = cancelOnClean;
    }
    return self;
}

-(id)initQueue:(BOOL)serialOnly{
    self = [self initQueue:serialOnly cancelOnClean:NO];
    return self;
}

-(void)waitUntilAllOperationsAreFinished{
    [_queue waitUntilAllOperationsAreFinished];
}

-(void)cleanUp{
    _cleaningUp = YES;
    if (_cancelOnClean) {
        [_queue cancelAllOperations];
    }
    [self waitUntilAllOperationsAreFinished];
    [_queue release];
    [_glContext release];
    [super cleanUp];
}

-(NSArray*)operations{
    return [_queue operations];
}

-(SFOperation*)addOperation:(SFOperation *)operation priority:(NSOperationQueuePriority)priority threadPriority:(float)threadPriority{
    if (_cleaningUp) {
        return operation;
    }
    [operation setThreadPriority:threadPriority];
    [operation setQueuePriority:priority];
    [operation setGlContext:_glContext];
    [_queue addOperation:operation];
    return operation;
}

-(SFOperation*)addOperation:(id)target selector:(SEL)sel object:(id)obj priority:(NSOperationQueuePriority)priority threadPriority:(float)threadPriority{
    SFOperation *newOp = [[[SFOperation alloc] initWithTarget:target selector:sel object:obj] autorelease];
    return [self addOperation:newOp priority:priority threadPriority:threadPriority];
}

-(SFOperation*)addOperation:(SFOperation *)operation priority:(NSOperationQueuePriority)priority{
    return [self addOperation:operation priority:priority threadPriority:THREAD_PRIORITY_NORMAL];
}

-(SFOperation*)addOperation:(id)target selector:(SEL)sel object:(id)obj priority:(NSOperationQueuePriority)priority{
    return [self addOperation:target selector:sel object:obj priority:priority threadPriority:THREAD_PRIORITY_NORMAL];
}

-(SFOperation*)addOperation:(id)target selector:(SEL)sel object:(id)obj{
    return [self addOperation:target selector:sel object:obj priority:NSOperationQueuePriorityNormal];
}

-(void)setGlContext:(EAGLContext*)glContext{
    _glContext = [glContext retain];
}

-(void)cancelAllOperations{
    [_queue cancelAllOperations];
}

@end
