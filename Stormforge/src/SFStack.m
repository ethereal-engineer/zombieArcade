//
//  SFStack.m
//  ZombieArcade
//
//  Created by Adam Iredale on 1/03/10.
//  Copyright 2010 Stormforge Software. All rights reserved.
//

#import "SFStack.h"


@implementation SFStack

-(id)initStack:(BOOL)uniqueObjects useFifo:(BOOL)fifo{
    self = [self initWithDictionary:nil];
    if (self != nil) {
        _uniqueObjects = uniqueObjects;
        _stack = [[NSMutableArray alloc] init];
        _fifo = fifo;
    }
    return self;
}

-(void)cleanUp{
    [self clear];
    [_stack release];
    [super cleanUp];
}

-(id)dump{
    //dumps the whole stack for processing - useful if we want to ensure that no more get added
    if (!_stackCount) {
        return nil;
    }
    NSArray *dumper = [NSArray arrayWithArray:_stack];
    [self clear];
    return dumper;
}

-(void)clear{
    _stackCount = 0;
    [_stack removeAllObjects];
}

-(BOOL)push:(id)object{
    BOOL pushedOk = NO;
    if (_uniqueObjects and [_stack containsObject:object]) {
        pushedOk = NO;
    } else {
        [_stack addObject:object];
        pushedOk = YES;
        ++_stackCount;
    }      
    return pushedOk;
}

-(void)pop{
    if (!_stackCount) {
        return;
    }
    if (_fifo) {
        [_stack removeObjectAtIndex:0];
    } else {
        [_stack removeLastObject];
    }
    --_stackCount;
}

-(id)peek{
    //have a peek at the top stack object (instantaneous, not locked)
    if (!_stackCount) {
        return nil;
    }
    if (_fifo) {
        return [_stack objectAtIndex:0];
    }
    return [_stack lastObject];
}

-(BOOL)isEmpty{
    //quick check - no sync
    return _stackCount == 0;
}

@end
