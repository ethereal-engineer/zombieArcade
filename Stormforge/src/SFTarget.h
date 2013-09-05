//
//  SFTarget.h
//  ZombieArcade
//
//  Created by Adam Iredale on 16/11/09.
//  Copyright 2009 Stormforge Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SF3DObject.h"
#import "SFRagdoll.h"
#import "SFTargetLogic.h"

@interface SFTarget : SF3DObject {
	//a target is basically an AI character or object
	//that the player has to interact with in some way
	//each target always corresponds to an SIO2 object
	BOOL _isFriendly;
	SFTargetLogic *_logic; //the logic controller for this target;
	float _gradeScaleFactor;
    id _ragdoll, _masterRagdoll;
    id _borrower;
}

-(BOOL)updateAI;
-(void)setMasterRagdoll:(SFRagdoll*)masterRagdoll;
-(void)setupLogic;
-(SFTargetLogic*)logic;
-(void)instantKill;

@property (nonatomic, readonly) BOOL _isFriendly;
@property (nonatomic, retain) SFTargetLogic *_logic;

@end
