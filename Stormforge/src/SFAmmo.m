//
//  SFAmmo.m
//  ZombieArcade
//
//  Created by Adam Iredale on 12/11/09.
//  Copyright 2009 Stormforge Software. All rights reserved.
//

#import "SFAmmo.h"
#import "SFSceneLogic.h"
#import "SFUtils.h"
#import "SFSceneManager.h"
#import "SFTarget.h"

@implementation SFAmmo

-(id)weapon{
    return _firedFromWeapon;
}

-(void)precacheSounds:(NSMutableArray *)sounds{
    [super precacheSounds:sounds];
    [sounds addObject:_hitSound];
}

-(id)initCopyWithDictionary:(NSDictionary *)dictionary{
    self = [super initCopyWithDictionary:dictionary];
    if (self != nil) {
        _baseDamageAmount = 1.0f; //hardcoded for now
        _isLive = YES;
        _scoreManager = [self scom];
    }
    return self;
}

-(void)setup3dObject{
    [super setup3dObject];
    if (!_hitSound) {
        _hitSound = [[self getBlenderInfo:@"hitSound"] copy];
    }
}

-(void)setImpulseVector:(SFVec*)impulseVector hitPosition:(SFVec*)hitPosition{
    //once submitted, these vectors should not be deleted - they will be cleaned up later
    if (_fakeImpulse) {
        delete _fakeImpulse;
    }
    if (_fakeHitPosition) {
        delete _fakeHitPosition;
    }
    _fakeImpulse = impulseVector;
    _fakeHitPosition = hitPosition;
    _isFake = YES;
}

-(SFVec*)impulseVector{
    return _fakeImpulse;
}

-(SFVec*)hitPosition{
    return _fakeHitPosition;
}

-(void)cleanUp{
	[_firedFromWeapon release];
	_firedFromWeapon = nil;
    [_hitSound release];
    _hitSound = nil;
    if (_fakeImpulse) {
      //  delete _fakeImpulse;
        _fakeImpulse = nil;
    }
    if (_fakeHitPosition) {
      //  delete _fakeHitPosition;
        _fakeHitPosition = nil;
    }
    [super cleanUp];
}

-(void)setWeapon:(id)aWeapon{
    [_firedFromWeapon release];
	_firedFromWeapon = [aWeapon retain];
}

-(void)setHitSound:(NSString*)hitSound{
    [_hitSound release];
    _hitSound = [[NSString alloc] initWithString:hitSound];
}

-(void)postCopySetup:(id)aCopy{
    [super postCopySetup:aCopy];
    [(SFAmmo*)aCopy setDefaultRemoveAfter:[self getBlenderFloat:@"ttl"]];
    [aCopy setHitSound:_hitSound];
}

-(void)setDefaultRemoveAfter:(float)removeAfter{
    _defaultRemoveAfter = removeAfter;
}

-(void)prepareObject{
    [super prepareObject];
    _isLive = YES;
    //[self enableCollisions:YES];
    if (!_defaultRemoveAfter) {
        _defaultRemoveAfter = [self getBlenderFloat:@"ttl"];
    }
    [self removeAfter:_defaultRemoveAfter];
}

-(void)didHit:(SF3DObject *)victim{
    [super didHit:victim];
	//disable any further callbacks for us
    [self enableCollisions:NO];
	//play the hit noise if there is one
	if (!_isLive) {
		return; //only if we are live
	}
    if (_hitSound) {
        //SLOW METHOD!!!
        [self playFXSound:_hitSound];
    }
	_isLive = NO;
    [_scoreManager ammoHitTarget:self target:victim firedFromWeapon:_firedFromWeapon];
}

-(float)getScoreMultiplier{
	return [_firedFromWeapon getScoreMultiplier];
}

-(void)hitWorld:(id)worldObject{
	[super hitWorld:worldObject];
    if (!_isLive) {
        return;
    }
	//disable any further callbacks for us
    [self enableCollisions:NO];
	_isLive = NO;
    [_scoreManager ammoMissedTarget:self firedFromWeapon:_firedFromWeapon];
}

+(BOOL)enableCollisionCallback{
	return YES;
}

+(id)getCollisionClass{
	//all ammo should say that they are ammo
	return [SFAmmo class];
}

@end
