//
//  SFStack.h
//  ZombieArcade
//
//  Created by Adam Iredale on 1/03/10.
//  Copyright 2010 Stormforge Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SFObject.h"

@interface SFStack : SFObject {
    //a thread-safe stack
    BOOL _uniqueObjects;
    NSMutableArray *_stack;
    BOOL _fifo;
    int _stackCount;
}

-(id)initStack:(BOOL)uniqueObjects useFifo:(BOOL)fifo;
-(id)peek;
-(BOOL)push:(id)object;
-(void)pop;
-(id)dump;
-(void)clear;
-(BOOL)isEmpty;

@end
