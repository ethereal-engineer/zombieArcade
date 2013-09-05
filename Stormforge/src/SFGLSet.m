//
//  SFGLSet.m
//  ZombieArcade
//
//  Created by Adam Iredale on 1/03/10.
//  Copyright 2010 Stormforge Software. All rights reserved.
//

#import "SFGLSet.h"


@implementation SFGLSet

-(BOOL)getState:(unsigned short)index{
    return _set[index];
}

-(void)setState:(unsigned short)index state:(BOOL)state{
    _set[index] = state;
}

-(id)trueSummary{
    //returns an autoreleased NSArray that contains NSNumbers
    //for every index of ours that is set to TRUE/YES/1 etc
    NSMutableArray *trueSum = [[[NSMutableArray alloc] initWithCapacity:GL_SET_SIZE] autorelease];
    for (int i = 0; i < GL_SET_SIZE; ++i) {
        if (_set[i]) {
            [trueSum addObject:[NSNumber numberWithUnsignedShort:i]];
        }
    }
    return trueSum;
}

@end
