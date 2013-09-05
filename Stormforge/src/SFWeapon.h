//
//  SFWeapon.h
//  ZombieArcade
//
//  Created by Adam Iredale on 11/11/09.
//  Copyright 2009 Stormforge Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SFGameObject.h"
#import "SFAmmo.h"
#import "SFImage.h"
#import "SFSound.h"
#import "SFStack.h"
#import "SFTouchEvent.h"

#define DEBUG_SFWEAPON 0

@interface SFWeapon : SFGameObject <PScoreObject> {
	//the base weapon class
    SFSound *_sndReload, *_sndFire, *_sndDryFire, *_sndDraw;
	int _ammoInClip;
	int _spareAmmo;
	unsigned int _nextFireTime;
	BOOL _dry;
    SFAmmo *_ammo;
    id<SFWeaponDelegate> _delegate;
    float _decapChance;
    float _shotsFired;
    float _randomFirePitch[3];
}
-(int)ammoInt:(NSString*)key;
-(id)slotNumber;
-(void)fire:(vec3)hitPos atTarget:(SF3DObject*)atTarget;
//reload
-(BOOL)reload;
-(BOOL)reload:(BOOL)silent;
//draw sound
-(void)draw;
-(BOOL)isDry;
-(CGPoint)statusIconOffset;
-(CGPoint)hudIconOffset;
-(void)cleanSceneAmmo;
-(float)decapChance;
-(float)shotsFired;
-(void)setShotsFired:(float)shotsFired;

@end
