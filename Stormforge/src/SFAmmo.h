//
//  SFAmmo.h
//  ZombieArcade
//
//  Created by Adam Iredale on 12/11/09.
//  Copyright 2009 Stormforge Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SF3DObject.h"
#import "SFScoreManager.h"

@interface SFAmmo : SF3DObject <PScoreObject> {
	//projectile ammunition class
	id _firedFromWeapon; //track back
    SFVec *_fakeImpulse, *_fakeHitPosition;
    NSString *_hitSound;
    id <SFAmmoDelegate> _scoreManager;
    float _defaultRemoveAfter;
}

-(SFVec*)impulseVector;
-(SFVec*)hitPosition;
-(void)setImpulseVector:(SFVec*)impulseVector hitPosition:(SFVec*)hitPosition;
-(void)setWeapon:(id)aWeapon;
-(void)setHitSound:(NSString*)hitSound;
-(void)setDefaultRemoveAfter:(float)removeAfter;
-(id)weapon;

@end
