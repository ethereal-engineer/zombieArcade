//
//  SFTarget.m
//  ZombieArcade
//
//  Created by Adam Iredale on 16/11/09.
//  Copyright 2009 Stormforge Software. All rights reserved.
//

#import "SFTarget.h"
#import "SFUtils.h"
#import "SFRagdoll.h"
#import "SFAmmo.h"
#import "SFScene.h"
#import "SFDebug.h"

#define USE_RAGDOLLS 1

@implementation SFTarget

@synthesize _isFriendly;
@synthesize _logic;

-(void)setup3dObject{
    [super setup3dObject];
#if USE_RAGDOLLS
    //get ragdoll
    if (!_masterRagdoll) {
        _masterRagdoll = [[[self rm] getItem:[self getBlenderInfo:@"ragdoll"] itemClass:[SFRagdoll class] tryLoad:YES] retain];
    }
#endif
}

-(void)prepareObject{
    _isLive = YES;
    [super prepareObject];
#if USE_RAGDOLLS
    _ragdoll = [[_masterRagdoll findSpawnableObject] retain];
    if (!_ragdoll){
        return;
    }
    [_ragdoll reserve];
    [_ragdoll setupForObject:self stayTime:[_logic ragdollStayTime] + [[[self sm] currentLogic] extraRagdollTime]];
#endif
}

-(void)addObjectToWorld:(SFPhysicsWorld*)physicsWorld{
#if USE_RAGDOLLS
    if (!_ragdoll) {
        //can't add it until we have a ragdoll!!!
        sfDebug(TRUE, "Not enough ragdolls to add %s to world yet", [self UTF8Name]);
        return;
    }
#endif
    [super addObjectToWorld:physicsWorld];
}

-(id)initCopyWithDictionary:(NSDictionary*)dictionary{
	self = [super initCopyWithDictionary:dictionary];
	if (self != nil) {
        _requiresActionAnimation = YES;
        _actionState = OBJECT_IDLE;
        _gradeScaleFactor = 1.0f;
        _SIO2objectanimation = (SFObjectAnimationStruct *) calloc(1, sizeof(SFObjectAnimationStruct));
        //hardcoding!!!
        _attackSoundName = @"growl.ogg";
	}
	return self;
}

-(id)initWithTokens:(SFTokens*)tokens dictionary:(NSDictionary *)dictionary{
    self = [super initWithTokens:tokens dictionary:dictionary];
    if (self != nil){
        [self setupLogic];
    }
    return self;
}

-(void)setupLogic{
    if (!_logicClassName) {
        [self setLogicClassName:[[self objectInfoForKey:@"blenderInfo"] objectForKey:@"logicClass"]];
    }
    _logic = [SFGameLogic logicObjectWithDrone:self dictionary:nil];
}

-(float)getCalculatedDamageAmount{
	//returns the amount of damage that this target does upon attack
	return [_logic damageAmount];
}

-(void)cleanUp{
#if USE_RAGDOLLS
    [_masterRagdoll release];
#endif
	[_logic cleanUp];
    [_logic release];
    [super cleanUp];
}

-(void)spawnRagdoll{
    //the target has died - spawn the ragdoll
    [_scene spawnObject:_ragdoll withTransform:_transform adjustZAxis:NO];
}

-(void)instantKill{
    //die instantly and relinquish ragdoll
    if (!_isLive) {
        return;
    }
    _isLive = NO;
    if (_ragdoll) {
        [_ragdoll unReserve];
        [_ragdoll release];
        _ragdoll = nil;
    }
    [self removeAfter:0];
}

-(void)objectDidDie:(float)finalDamageAmount fromInflictor:(id)inflictor{
#if USE_RAGDOLLS
    if (([inflictor isFake]) and (_ragdoll != nil)) {
        [_ragdoll simulatePhysicsHit:inflictor];
    }
    [self spawnRagdoll];
    [_ragdoll release];
    _ragdoll = nil;
#endif
    [super objectDidDie:finalDamageAmount fromInflictor:inflictor];
}

-(void)lockAngularMovement{
	[self getRigidBody]->setAngularFactor(btVector3(0.0f, 0.0f, 0.0f));
}

-(void)lockLinearMovement{
	[self getRigidBody]->setLinearFactor(btVector3(0.0f, 0.0f, 1.0f));
}

-(void)unlockAngularMovement{
	[self getRigidBody]->setAngularFactor(btVector3(0.0f, 0.0f, 1.0f));
}

-(void)unlockLinearMovement{
	[self getRigidBody]->setLinearFactor(btVector3(1.0f, 1.0f, 1.0f));
}

-(void)moveForward:(float)speed{
	//only if on ground
    [super moveForward:speed];
	if (!_onGround) {
		return;
	}
	//play the walking animation
	if (_actionState != OBJECT_WALKING) {
		//sfDebug(TRUE, "Walking...");
		[self playAction:[self getActionName:@"walk"] loopAction:YES randomStart:YES];
		_actionState = OBJECT_WALKING;
	}
	[self unlockLinearMovement];
	[self stopAngularMovement];
	[self lockAngularMovement];
    SFVec *forwardVelocity = _transform->dir()->copy();
    forwardVelocity->scale(speed);
	//move fwd		
	[self wakePhysics];
    [self getRigidBody]->setLinearVelocity(forwardVelocity->getBtVector3());
    _onGround = false;
    delete forwardVelocity;
}

-(void)resetObject{
    [super resetObject];
    //wipe our objectives - we are dead
    [[self logic] clearObjectives];
}

-(SFTargetLogic*)logic{
    return _logic;
}

-(void)unlockMovement{
	//unlock movement axes (for uprights, that is)
	[self unlockAngularMovement];
	[self unlockLinearMovement];
}

-(void)didHit:(SF3DObject *)victim{
    [super didHit:victim];
    //we are hitting someone! - let the logic know
    [_logic enemyAcquired:victim];
}

-(void)startTurn:(float)radians steps:(int)steps{
    if (!_onGround) {
        return;
    }
    //stop walking velocity and begin turning
	//stop
	[self stopLinearMovement];
	//lock
	[self lockLinearMovement];
	//unlock
	[self unlockAngularMovement];
	//spin
	[self wakePhysics];
    [super startTurn:radians steps:steps];
    _onGround = NO;
}


-(BOOL)updateAI{
    if ((_worldState == wsExists) and _isLive) {
        [_logic makeChoices];
        return YES;
    } else if (_worldState != wsDoesNotExist) {
        //says that we have processed logic ok
        //considering that we will be added next 
        //render
        return YES;
    }
    return NO;
}

+(BOOL)takesDamageFrom:(Class)attackerClass{
    if (attackerClass == [SFAmmo class]) {
        return YES;
    }
    return NO;
}

+(NSArray*)getCollisionInterestClasses{
	return [NSArray arrayWithObjects:[SFTarget class], [SFAmmo class], nil];
}

+(BOOL)enableCollisionCallback{
	return YES;
}

+(id)getCollisionClass{
	//all targets should say that they are targets
	return [SFTarget class];
}

-(void)setMasterRagdoll:(SFRagdoll*)masterRagdoll{
    _masterRagdoll = [masterRagdoll retain];
}

-(void)postCopySetup:(id)aCopy{
    [super postCopySetup:aCopy];
#if USE_RAGDOLLS
    [aCopy setMasterRagdoll:_masterRagdoll];
#endif
    [aCopy setLogicClassName:_logicClassName];
    [aCopy setupLogic];
}

@end
