//
//  SFTargetLogic.h
//  ZombieArcade
//
//  Created by Adam Iredale on 23/11/09.
//  Copyright 2009 Stormforge Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SFGameLogic.h"
#import "SFProtocol.h"
#import "SF3DObject.h"

typedef enum {
	SF_TARGETLOGIC_NOP,
	SF_TARGETLOGIC_WAIT,
	SF_TARGETLOGIC_BUSY
} SF_TARGETLOGIC_STATE;

#define objectiveActionAttack @"oaAttack"
#define objectiveActionIdle @"oaIdle"
#define objectiveActionMoveOn @"oaMoveOn"

@interface SFTargetLogic : SFGameLogic {
	//the smarts of the target - a superclass
	unsigned char _state; //the state of us
	int _staleCount;
    SFStack *_objectives;
    SFStack *_objectiveActions;
    float _ragdollStayTime;
    float _forwardSpeed, _turnAccuracy, _hopStrength, _turnSpeed;
    float _forwardSpeedDelta, _damageAmountDelta;
    float _baseDamageAmount;
    BOOL _enemyAcquired;
}
-(SF3DObject*)target;
-(void)setMovementInfo:(NSDictionary*)movementInfo;
-(void)makeChoices; //called every frame or so to tell us to decide what to do
-(BOOL)isStale;
-(void)noteStaleMove;
-(void)forceStale;
-(void)resetStaleCount;
-(void)enemyAcquired:(id)enemy;
-(void)enemyLost;
-(void)pushObjective:(id)objective objectiveAction:(NSString*)objectiveAction;
-(float)damageAmount;
-(float)ragdollStayTime;
-(int)getMaxStaleCount;
-(void)clearObjectives;

@end
