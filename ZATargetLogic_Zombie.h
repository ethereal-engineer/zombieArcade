//
//  ZATargetLogic_Zombie.h
//  ZombieArcade
//
//  Created by Adam Iredale on 23/11/09.
//  Copyright 2009 Stormforge Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SFTargetLogic.h"
#import "SF3DObject.h"

#define DEBUG_SFTARGETLOGIC_ZOMBIE 0

@interface ZATargetLogic_Zombie : SFTargetLogic {
	//the smarts of the zombie characters
	SF3DObject *_currentDestination; //where we are going to..
    NSString *_currentAction;
	SFVec *_lastLoc;
    int _maxStaleCount;
    BOOL _atTarget;
    float _furthestDistance;
    float _lastAngle;
}

-(void)targetSleep:(int)sleepSeconds;

@end
