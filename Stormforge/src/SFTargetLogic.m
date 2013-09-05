//
//  SFTargetLogic.m
//  ZombieArcade
//
//  Created by Adam Iredale on 23/11/09.
//  Copyright 2009 Stormforge Software. All rights reserved.
//

#import "SFTargetLogic.h"
#import "SFTarget.h"
#import "SFSceneManager.h"
#import "SFUtils.h"
#import "SFDebug.h"

#define DEFAULT_STALE_MAX 2;

@implementation SFTargetLogic

-(void)clearObjectives{
    [_objectives clear];
    [_objectiveActions clear];
}

-(void)pushObjective:(id)objective objectiveAction:(NSString*)objectiveAction{
    //pushes an objective on our 
    //objective stack
    [_objectives push:objective];
    [_objectiveActions push:objectiveAction];
}

-(float)damageAmount{
    return [[self scom] getGradeScaledAmount:_baseDamageAmount delta:_damageAmountDelta];
}

-(void)forceStale{
    //force the target to change objectives
    _staleCount = DEFAULT_STALE_MAX + 1;
}

-(void)setMovementInfo:(NSDictionary*)movementInfo{
    //set how fast we move etc
    _forwardSpeed = [[movementInfo objectForKey:@"forwardSpeed"] floatValue];
    _forwardSpeedDelta = [[movementInfo objectForKey:@"forwardSpeedDelta"] floatValue];
    _turnSpeed = [[movementInfo objectForKey:@"turnSpeed"] floatValue];
    _turnAccuracy = [[movementInfo objectForKey:@"turnAccuracy"] floatValue];
    //damage amount is measured in units of damage per second of contact, so it is divided by
    //the fps - so is the delta
    _baseDamageAmount = [[movementInfo objectForKey:@"damageAmount"] floatValue] / [[self scene] timeToRenderPasses:1.0f];
    _damageAmountDelta = [[movementInfo objectForKey:@"damageAmountDelta"] floatValue] / [[self scene] timeToRenderPasses:1.0f];
    _hopStrength = [[movementInfo objectForKey:@"hopStrength"] floatValue];
    _ragdollStayTime = [[movementInfo objectForKey:@"ragdollStayTime"] floatValue];
    //if there is an override friction or restitution set, use it
    NSNumber *overridePhysFloat = [movementInfo objectForKey:@"friction"];
    if (overridePhysFloat) {
        sfDebug(TRUE, "Friction override present %.2f", [overridePhysFloat floatValue]);
        [[self target] getRigidBody]->setFriction([overridePhysFloat floatValue]);
    }
    overridePhysFloat = [movementInfo objectForKey:@"restitution"];
    if (overridePhysFloat) {
        sfDebug(TRUE, "Restitution override present %.2f", [overridePhysFloat floatValue]);
        [[self target] getRigidBody]->setRestitution([overridePhysFloat floatValue]);
    }
}

-(float)ragdollStayTime{
    return _ragdollStayTime;
}

-(void)makeChoices{
	//children classes to implement
}

-(void)noteStaleMove{
	++_staleCount;
}

-(BOOL)isStale{
	return _staleCount > [self getMaxStaleCount];
}

-(void)resetStaleCount{
	_staleCount = 0;
}

-(int)getMaxStaleCount{
	return DEFAULT_STALE_MAX;
}

-(void)enemyAcquired:(id)enemy{
    _enemyAcquired = YES;
}

-(void)enemyLost{
    _enemyAcquired = NO;
}

-(void)cleanUp{
    [_objectives release];
    [_objectiveActions release];
    [super cleanUp];
}

-(SF3DObject*)target{
    return [self getDrone];
}

-(id)initWithDrone:(id)drone dictionary:(NSDictionary*)dictionary{
	self = [super initWithDrone:drone dictionary:dictionary];
	if (self != nil) {
        _objectives = [[SFStack alloc] initStack:NO useFifo:NO];
        _objectiveActions = [[SFStack alloc] initStack:NO useFifo:NO];
        _state = SF_TARGETLOGIC_NOP;
	}
	return self;
}


@end
