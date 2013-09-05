//
//  SFRagdoll.h
//  ZombieArcade
//
//  Created by Adam Iredale on 17/11/09.
//  Copyright 2009 Stormforge Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SF3DObjectGroup.h"
#import "SFHumanoidRagdoll.h"

#define DEBUG_SFRAGDOLL 0

@interface SFRagdoll : SF3DObjectGroup {
    SFHumanoidRagdoll *_hrd;
}

-(void)setupForObject:(id)object stayTime:(float)stayTime;
-(void)buildRagdoll;

@end
