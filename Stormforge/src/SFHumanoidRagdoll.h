/*
 *  SFHumanoidRagdoll.h
 *  ZombieArcade
 *
 *  Created by Adam Iredale on 17/04/10.
 *  Copyright 2010 Stormforge Software. All rights reserved.
 *
 */

//this class is a storage place and a setup point for unique parts
//that become a ragdoll

#include "SFObj.h"
#include "btBulletDynamicsCommon.h"
#include "btSoftRigidDynamicsWorld.h"
#include "btTypedConstraint.h"
#include "btTransform.h"
#include "SFPhysicsWorld.h"

typedef enum {
    rpkHead,        //0
    rpkChest,       //1
    rpkMidriff,     //2
    rpkBicepL,      //3
    rpkBicepR,      //4
    rpkForearmL,    //5
    rpkForearmR,    //6
    rpkHandL,       //7
    rpkHandR,       //8
    rpkThighL,      //9
    rpkThighR,      //10
    rpkLegL,        //11
    rpkLegR,        //12
    rpkFootL,       //13
    rpkFootR,       //14
    rpkAll
} SFRagdollPartKind;

typedef enum {
    rjkHinge,
    rjkCone
} SFRagdollJointKind;

typedef enum {
    jsIntact,
    jsBroken
} SFJointState;

class SFHumanoidRagdoll : SFObj {
    btRigidBody *_bodies[rpkAll];
    btTypedConstraint *_joints[rpkAll];
    SFPhysicsWorld *_world;
protected:
    void arrangePart(SFRagdollPartKind rpk, float x, float y, float z);
    void joinParts(SFRagdollPartKind partKindA, 
                   SFRagdollPartKind partKindB, 
                   SFRagdollJointKind jointKind,
                   float eulerA, 
                   float eulerB,
                   float originAX,
                   float originAY,
                   float originAZ,
                   float originBX,
                   float originBY,
                   float originBZ,
                   float limitX,
                   float limitY,
                   float limitZ);
public:
    SFHumanoidRagdoll();
    ~SFHumanoidRagdoll();
    void addBodyPart(btRigidBody *part, SFRagdollPartKind rpk);    //add each part as we get them 
    void buildRagdoll();                                        //when all parts are added, we build the ragdoll
    void publishRagdoll(SFPhysicsWorld *world);
    void unPublishRagdoll();
    void breakRagdoll(SFRagdollPartKind rpk);
};