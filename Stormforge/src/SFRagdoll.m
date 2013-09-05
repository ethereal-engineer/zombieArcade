//
//  SFRagdoll.m
//  ZombieArcade
//
//  Created by Adam Iredale on 17/11/09.
//  Copyright 2009 Stormforge Software. All rights reserved.
//

#import "SFRagdoll.h"
#import "SFConstraint.h"
#import "SFUtils.h"
#import "SFSceneManager.h"
#import "SFGameEngine.h"
#import "SFTransform.h"
#import "SFMaterial.h"
#import "SFDebug.h"
#import "SFAmmo.h"

#define RAGDOLL_SEVERING_FORCE 61 //the force it takes to break a constraint
//#define RAGDOLL_FADE_TIME 3.0f

@implementation SFRagdoll

-(id)initCopyWithDictionary:(NSDictionary *)dictionary{
    self = [super initCopyWithDictionary:dictionary];
    if (self != nil) {
        _hrd = new SFHumanoidRagdoll();
    }
    return self;
}

-(void)cleanUp{
    if (_hrd) {
        delete _hrd;
        _hrd = NULL;
    }
    [super cleanUp];
}

-(void)setupForObject:(id)object stayTime:(float)stayTime{
    //called before we are spawned
    //this allows us to copy materials etc
    NSEnumerator *parts = [_subObjects objectEnumerator];
	for (id part in parts) {
        //set each part's materials to the target's materials of the same name
        for (NSString *vertGroupName in [part vertexGroups]) {
            SFVertexGroup *sourceGroup = [object vertexGroupByName:vertGroupName];
            if (sourceGroup) {
                //if the part vertex group needs a mat, make it
                SFVertexGroup *partVertGroup = [[part vertexGroups] objectForKey:vertGroupName];
                SFMaterial *partVertGroupMat = [[SFMaterial alloc] initWithName:@"dynMat" dictionary:nil];
                [partVertGroup setMaterial:partVertGroupMat];
                [[sourceGroup material] cloneMaterial:partVertGroupMat];
                [partVertGroupMat release];
            }
        }
	}
    //ok... materials are copied
    //now set how many renders before we sod off
    [self removeAfter:stayTime];
}

-(void)addObject:(id)object objectId:(int)objectId{
    [super addObject:object objectId:objectId];
    _hrd->addBodyPart([object getRigidBody], (SFRagdollPartKind)objectId);
}

-(void)addPart:(NSString*)partKind partName:(NSString*)partName{
    //as soon as we have the part name, load it!
    int partKindId = [[partKind substringFromIndex:4] intValue];
    id newPart = [[self rm] getItem:partName itemClass:[SF3DObject class] tryLoad:YES];
    if (newPart) {
        sfDebug(DEBUG_SFRAGDOLL, "Adding part %s...", [partName UTF8String]);
        [self addObject:newPart objectId:partKindId];
    } else {
        //it might be a left/right pair
        id newLeftPart = [[self rm] getItem:[partName stringByAppendingString:@".l"] itemClass:[SF3DObject class] tryLoad:YES];
        id newRightPart = [[self rm] getItem:[partName stringByAppendingString:@".r"] itemClass:[SF3DObject class] tryLoad:YES];
        if ((newLeftPart) and (newRightPart)) {
            sfDebug(DEBUG_SFRAGDOLL, "Adding L-R parts %s.l and %s.r...", [partName UTF8String], [partName UTF8String]);
            [self addObject:newLeftPart objectId:partKindId];
            [self addObject:newRightPart objectId:partKindId + 1];
        }
    }
}

-(void)buildRagdoll{
    _hrd->buildRagdoll();
}

-(void)addObjectToWorld:(SFPhysicsWorld *)physicsWorld{
    [super addObjectToWorld:physicsWorld];
    _hrd->publishRagdoll(physicsWorld);
}

-(BOOL)loadInfo:(SFTokens*)tokens{
    //ok - in this we want parts
    if (tokens->tokenStartsWith("part")) {
        [self addPart:[NSString stringWithUTF8String:tokens->tokenName()] 
             partName:[NSString stringWithUTF8String:tokens->valueAsString()]];
        return YES;
    } else {
        return [super loadInfo:tokens];
    }
}

-(void)removeObjectFromWorld:(SFPhysicsWorld *)physicsWorld{
    [super removeObjectFromWorld:physicsWorld];
    _hrd->unPublishRagdoll();
    NSEnumerator *enumerator = [_subObjects objectEnumerator];
	for (id part in enumerator) {
        [part resetToOriginalTransform];
	}
}

-(void)prepareObject{
    [super prepareObject];
    NSEnumerator *enumerator = [_subObjects objectEnumerator];
	for (id part in enumerator) {
        [part prepareObject];
	}
}

-(void)sleepPhysics{
    [super sleepPhysics];
    NSEnumerator *enumerator = [_subObjects objectEnumerator];
	for (id part in enumerator) {
        [part sleepPhysics];
	}
}

-(void)wakePhysics{
    [super wakePhysics];
    NSEnumerator *enumerator = [_subObjects objectEnumerator];
	for (id part in enumerator) {
        [part wakePhysics];
	}
}

-(void)simulatePhysicsHit:(SFAmmo*)inflictor{
    SFVec *hitPosition = [inflictor hitPosition];
    SFVec *impulseVector = [inflictor impulseVector];
    //in the case that we are hit we only want the part nearest the hit being affected
	float dist = 9999.0;
	float lowdist;
	id hitPart;
    NSNumber *hitPartId;
	for (NSNumber *partId in _subObjects) {
		SF3DObject *part = [_subObjects objectForKey:partId];
        //get the closest part to the hit point
		//very approximate - only works from object centres, not individual vertices
		lowdist = [part transform]->loc()->distanceFrom(hitPosition);
		if (lowdist < dist){
			dist = lowdist;
			hitPart = part;
            hitPartId = partId;
		}
	}
    float forceLength = impulseVector->magnitude();
    
	if ([SFUtils getRandomPositiveInt:10] <= ([[inflictor weapon] decapChance] * 10)) {
#if DEBUG_SFRAGDOLL
		sfDebug(DEBUG_SFRAGDOLL, "Severing limb %s", [[hitPart name] UTF8String]);
#endif
        _hrd->breakRagdoll((SFRagdollPartKind)[hitPartId intValue]);
        [hitPart getRigidBody]->applyTorqueImpulse(btVector3(forceLength / -2.0f, 0.0, 0.0));
        SFVec *scaledForce = impulseVector->copy();
        scaledForce->scale(0.5f);
        [hitPart getRigidBody]->applyCentralImpulse(scaledForce->getBtVector3());
        delete scaledForce;
	} else {
        [hitPart getRigidBody]->applyCentralImpulse(impulseVector->getBtVector3());
    }
	hitPart = nil;
}

-(void)postCopySetup:(id)aCopy{
    [super postCopySetup:aCopy];
    [aCopy buildRagdoll];
}

@end
