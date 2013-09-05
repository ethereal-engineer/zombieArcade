//
//  SFGLSet.h
//  ZombieArcade
//
//  Created by Adam Iredale on 1/03/10.
//  Copyright 2010 Stormforge Software. All rights reserved.
//

#import <Foundation/Foundation.h>

#define GL_SET_SIZE 65536

@interface SFGLSet : NSObject {
    //a fast set capable of 16 bits
    BOOL _set[GL_SET_SIZE];
}

-(BOOL)getState:(unsigned short)index;
-(void)setState:(unsigned short)index state:(BOOL)state;
-(id)trueSummary;

@end
