//
//  SFOperationQueue.h
//  ZombieArcade
//
//  Created by Adam Iredale on 22/03/10.
//  Copyright 2010 Stormforge Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SFObject.h"
#import "SFGL.h"

#define DEBUG_SFOPERATIONQUEUE 0

@interface SFOperationQueue : SFObject {
    BOOL _cancelOnClean;
    EAGLContext *_glContext;
    NSOperationQueue *_queue;
    BOOL _cleaningUp;
}

-(id)initQueue:(BOOL)serialOnly;
-(id)initQueue:(BOOL)serialOnly cancelOnClean:(BOOL)cancelOnClean;
-(SFOperation*)addOperation:(id)target selector:(SEL)sel object:(id)obj;
-(SFOperation*)addOperation:(id)target selector:(SEL)sel object:(id)obj priority:(NSOperationQueuePriority)priority;
-(SFOperation*)addOperation:(id)target selector:(SEL)sel object:(id)obj priority:(NSOperationQueuePriority)priority threadPriority:(float)threadPriority;
-(SFOperation*)addOperation:(SFOperation *)operation priority:(NSOperationQueuePriority)priority;
-(SFOperation*)addOperation:(SFOperation *)operation priority:(NSOperationQueuePriority)priority threadPriority:(float)threadPriority;
-(void)setGlContext:(EAGLContext*)glContext;
-(void)cancelAllOperations;
-(NSArray*)operations;
-(void)waitUntilAllOperationsAreFinished;

@end
