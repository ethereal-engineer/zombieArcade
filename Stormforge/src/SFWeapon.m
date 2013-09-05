//
//  SFWeapon.m
//  ZombieArcade
//
//  Created by Adam Iredale on 11/11/09.
//  Copyright 2009 Stormforge Software. All rights reserved.
//

#import "SFWeapon.h"
#import "SFSceneManager.h"
#import "SFUtils.h"
#import "SFSceneLogic.h"
#import "SFTarget.h"
#import "SFGameEngine.h"
#import "SFDebug.h"

@implementation SFWeapon

-(BOOL)hasClip{
	//needs a clip if the clipsize is larger than 0
	return [self ammoInt:@"clipSize"] > 0;
}

-(float)getScoreMultiplier{
	return [[self objectInfoForKey:@"scoreMultiplier"] floatValue];
}

-(id)ammoInfo:(NSString*)key{
    return [[self objectInfoForKey:@"ammo"] objectForKey:key];
}

-(int)ammoInt:(NSString*)key{
    return [[self ammoInfo:key] intValue];
}

-(id)soundInfo:(NSString*)soundName{
    return [[self objectInfoForKey:@"sound"] objectForKey:soundName];
}

-(CGPoint)mainIconOffset{
    return CGPointFromString([self objectInfoForKey:@"icon"]);
}

-(BOOL)needsAmmo{
	//needs ammo if ammo used per fire is > 0
	return [self ammoInt:@"perShot"] > 0;
}

-(BOOL)ammoAvailable{
	//true if ammo is available
	if ([self hasClip]) {
		return (_ammoInClip >= [self ammoInt:@"perShot"]);
	} else {
		return (([SFSceneManager sceneHasInfiniteAmmo]) or (_spareAmmo >= [self ammoInt:@"perShot"]));
	}

}

-(void)resetWeapon{
	//start the gun fresh
	
	//allow firing immediately
	_nextFireTime = 0;
	//start with a full clip
	_ammoInClip = [self ammoInt:@"clipSize"];
	//start with the default ammo spare
	_spareAmmo = [self ammoInt:@"startSpare"];
    //the chance of taking something off with this
    _decapChance = [[self objectInfoForKey:@"decapChance"] floatValue];
}

-(BOOL)canFire{
	//can only fire when gun is ready...
	if (_nextFireTime > [SFGameEngine renderId]) {
        sfDebug(TRUE, "Next fire time is %u - can't fire!", _nextFireTime);
		return false;
	}

	//return true if we can fire
	if ([self needsAmmo]) {
		if ([self ammoAvailable]) {
			_dry = false;
			return true;
		} else {
			//play the dry fire sound
			_dry = true;
            [_sndDryFire playAsAmbient:NO];
            [_delegate weaponDidDryFire:self];
			return false;
		}

	}
	//otherwise, all good!
	return true;
}

-(void)takeAmmo{
	//use a round
	if ([self needsAmmo]) {
		if ([self hasClip]) {
			_ammoInClip -= [self ammoInt:@"perShot"];
		} else if (![SFSceneManager sceneHasInfiniteAmmo]) {
			_spareAmmo -= [self ammoInt:@"perShot"];

		}

	}
}

-(void)fireFakeAmmo:(vec3)hitPos direction:(SFVec*)direction atTarget:(SF3DObject*)atTarget{
	//this weapon fires things so fast (or small) that the phys engine would be pissing itself to keep up
	//on the iPhone - so we shortcut it.
    sfDebug(TRUE, "Faking Ammo...");
    SFAmmo *ammo = [[SFAmmo alloc] initWithTokens:nil dictionary:nil];
    [ammo setScene:[[self sm] currentScene]];
    [ammo setWeapon:self];
	[ammo hide];
	
    //faked decayed firepower!
    SFVec *hitPosVec = new SFVec(hitPos);
    SFCamera* currentCamera = [[[self sm] currentScene] camera];
    float dist = [currentCamera handTransform]->loc()->distanceFrom(hitPosVec);
    float firePower = [[self objectInfoForKey:@"firePower"] floatValue];
    //we decay a portion of the firepower to give that added satisfaction to 
    //close shots
    firePower = (firePower * 0.6f) + (firePower * 0.4f / powf(1.0f + ABS(dist), 2));
    direction->scale(firePower);
    sfDebug(TRUE, "firePower scaled by %.2f", firePower);
    //submit the new vectors here - they will be cleaned up
    //when the ammo is cleaned up
    [ammo setImpulseVector:direction hitPosition:hitPosVec];
    //fake an event to the scene logic
    [[[self sm] currentLogic] handleObjectCollision:ammo object2:atTarget];
    //release the fake ammo
    [ammo release];
    delete hitPosVec;
}


-(void)fireRealAmmo:(id)newRound direction:(SFVec*)direction{
    
    [newRound setWeapon:self];
    
    [[[self sm] currentScene] spawnObject:newRound withTransform:[[[[self sm] currentScene] camera] handTransform] adjustZAxis:NO];
    
	//the decay here is handled by friction etc
	float firePower = [[self objectInfoForKey:@"firePower"] floatValue];
    direction->scale(firePower);
    
    [newRound getRigidBody]->setLinearVelocity(direction->getBtVector3());
    vec3 fireRot = Vec3Make([self ammoInt:@"spinX"], [self ammoInt:@"spinY"], [self ammoInt:@"spinZ"]);
    if ([self ammoInt:@"randomRotation"] > 0) {
        fireRot.x = ([SFUtils getRandomPositiveInt:fireRot.x]);
        fireRot.y = ([SFUtils getRandomPositiveInt:fireRot.y]);
        fireRot.z = ([SFUtils getRandomPositiveInt:fireRot.z]);
    }
    [newRound getRigidBody]->setAngularVelocity(btVector3(fireRot.x, fireRot.y, fireRot.z));
}

-(void)fire:(vec3)hitPos atTarget:(SF3DObject*)atTarget{
	
	if (![self canFire]) {
		return;
	}
    
	[self takeAmmo];
	
    ++_shotsFired;
    
    //play the sound and init the delay
    [_sndFire setPitch:_randomFirePitch[[SFUtils getRandomPositiveInt:3]]];
    [_sndFire playAsAmbient:NO];
    _nextFireTime = [SFGameEngine renderId] + [[[self sm] currentScene] timeToRenderPasses:[[self objectInfoForKey:@"fireDelay"] floatValue]];
    
    //get the direction that we are firing in
    SFVec *firePoint = new SFVec(hitPos);
	SFVec *direction = [[[[self sm] currentScene] camera] handTransform]->loc()->directionTo(firePoint);
	delete firePoint;
    
	//now we know the direction to fire in
	//we get a bullet copy of ours
	
	//if we use fake ammo (i.e. phys engine can't keep up with ammo speed)
	//then we do this differently

    //if this is a fake we don't borrow a round
    if (![self ammoInfo:@"model"]) {
        //if we have no target there's no point in faking this part
        if (atTarget) {
            [self fireFakeAmmo:hitPos direction:direction atTarget:atTarget];
        }
    } else {
        id newRound = [_ammo findSpawnableObject];
        [_ammo prepareObject];
        sfAssert(newRound != nil, "No ammo available");
        [self fireRealAmmo:newRound direction:direction];
    }
    delete direction;
    [_delegate weaponDidFire:self];
}

-(void)setShotsFired:(float)shotsFired{
    _shotsFired = shotsFired;
}

-(void)notifyWeaponReady{
    [_delegate weaponDidFinishReloading:self];
}

-(BOOL)reload:(BOOL)silent{
    u_int64_t reloadStartTime = [SFGameEngine renderId];
	if (_ammoInClip == [self ammoInt:@"clipSize"]) {
		return true; //don't reload if full
	}
	if (_spareAmmo == 0) {
		//we have no more ammo!  Can't reload - 
		//need a general "CANT RELOAD" sound
		//should also disable the weapon for selection etc
		return false;
	} else {
		_dry = false;
        float soundTime = [_sndReload soundLength];
		if (!silent) {
            [_sndReload playAsAmbient:NO];
            sfDebug(DEBUG_SFWEAPON, "Reload delay is %.2fs", soundTime);
            _nextFireTime = reloadStartTime + [[[self sm] currentScene] timeToRenderPasses:soundTime];
		}
        [self performSelector:@selector(notifyWeaponReady) withObject:nil afterDelay:soundTime];
        [_delegate weaponDidStartReloading:self reloadTime:soundTime];
		//take ammo from our spare stash
		int iLoadingAmmoCount = MIN([self ammoInt:@"clipSize"], _spareAmmo);
		iLoadingAmmoCount = MIN(iLoadingAmmoCount, [self ammoInt:@"clipSize"] - _ammoInClip);
		if (![SFSceneManager sceneHasInfiniteAmmo]) {
			_spareAmmo -= iLoadingAmmoCount;
		}
		_ammoInClip += iLoadingAmmoCount;
        
        [self cleanSceneAmmo];
		return true;
	}
}

-(void)cleanUp{
    [_sndDraw release];
    [_sndFire release];
    [_sndDryFire release];
    [_sndReload release];
    [super cleanUp];
}

-(BOOL)reload{
	return [self reload:NO];
}

-(CGPoint)hudIconOffset{
    return CGPointFromString([self objectInfoForKey:@"hudIcon"]);
}

-(CGPoint)statusIconOffset{
    //get the icon offset in the atlas for this weapon's status
    CGPoint statusIcon =  CGPointFromString([self objectInfoForKey:@"statusIcon"]);
    //then we add how many bullets we have in our clip to the X factor
    statusIcon.x += _ammoInClip;
    return statusIcon;
}

-(void)soundPrecachingComplete{
    [super soundPrecachingComplete];
    //assign all the sounds we precached
    _sndDraw = [[_sounds objectForKey:[self soundInfo:@"draw"]] retain];
    _sndFire = [[_sounds objectForKey:[self soundInfo:@"fire"]] retain];
    _sndDryFire = [[_sounds objectForKey:[self soundInfo:@"dry"]] retain];
    _sndReload = [[_sounds objectForKey:[self soundInfo:@"reload"]] retain];
}

-(void)precacheSounds:(NSMutableArray *)sounds{
    [super precacheSounds:sounds];
    [sounds addObject:[self soundInfo:@"draw"]];
    [sounds addObject:[self soundInfo:@"dry"]];
    [sounds addObject:[self soundInfo:@"reload"]];
    [sounds addObject:[self soundInfo:@"fire"]];
}

-(void)precacheObjects:(NSMutableArray *)objects{
    [super precacheObjects:objects];
    //precache clipsize ammo
    if (![self ammoInfo:@"model"]) {
        return;
    }
    //get the ammo for this weapon and duplicate it 
    //to our clip size
    _ammo = [[[self rm] getItem:[self ammoInfo:@"model"] itemClass:[SFAmmo class] tryLoad:YES] retain];
    [_ammo precache];
    [_ammo replicate:[self ammoInt:@"clipSize"]];
    [[[self sm] currentScene] appendSceneObject:_ammo];
    //make sure next time we recreate it
    [[self rm] removeItem:_ammo];
}

-(void)cleanSceneAmmo{
    //set all our ammo and duplicates to "out" of the world in the next render
    if (!_ammo) {
        return;
    }
    SFAmmo *ammo = _ammo;
    do {
        [ammo removeFromWorld];
        ammo = (SFAmmo*)[ammo nextDuplicate];
    } while (ammo != nil);
}

-(id)slotNumber{
    return [self objectInfoForKey:@"slotNumber"]; //NSNumber
}

-(id)initWithDictionary:(NSDictionary *)dictionary{
	self = [super initWithDictionary:dictionary];
	if (self != nil) {
        [self resetWeapon];
        _delegate = (id<SFWeaponDelegate>)[self scom];
        float firePitches[3] = {1.0f, 1.01f, 1.02f};
        memcpy(&_randomFirePitch, &firePitches, sizeof(firePitches));
	}
	return self;
}

-(BOOL)isDry{
    return _dry;
}

-(float)decapChance{
    return _decapChance;
}

-(void)draw{
    //add a delay after drawing (you can't fire while drawing a weapon!!)
    u_int64_t drawStartTime = [SFGameEngine renderId];
    float soundTime = [_sndDraw soundLength];
    [_sndDraw playAsAmbient:NO];
    _nextFireTime = drawStartTime + [[[self sm] currentScene] timeToRenderPasses:soundTime];
}

-(float)shotsFired{
    return _shotsFired;
}

@end
