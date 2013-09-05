/*
 *  SFHumanoidRagdoll.mm
 *  ZombieArcade
 *
 *  Created by Adam Iredale on 17/04/10.
 *  Copyright 2010 Stormforge Software. All rights reserved.
 *
 */

#include "SFHumanoidRagdoll.h"
#include "SFDebug.h"

#define NO_WRISTS 1

#ifndef M_PI
#define M_PI       3.14159265358979323846
#endif

#ifndef M_PI_2
#define M_PI_2     1.57079632679489661923
#endif

#ifndef M_PI_4
#define M_PI_4     0.785398163397448309616
#endif

SFHumanoidRagdoll::SFHumanoidRagdoll(){
    memset(&_joints[0], 0, sizeof(btTypedConstraint *) * rpkAll);
    memset(&_bodies[0], 0, sizeof(btRigidBody *) * rpkAll);
}

SFHumanoidRagdoll::~SFHumanoidRagdoll(){
    //destroy all the joints we made
    for (int i = 0; i < rpkAll; ++i) {
        if (_joints[i] == nil) {
            continue;
        }
        delete _joints[i];
        _joints[i] = nil;
    }
}

void SFHumanoidRagdoll::publishRagdoll(SFPhysicsWorld *world){
    //adds all these constraints to the physics world
    this->_world = world;
    for (int i = 0; i < rpkAll; ++i) {
        if (_bodies[i] == nil) {
            continue;
        }
        _world->addObject(_bodies[i]);
        if (_joints[i] != nil) {
            if (_joints[i]->getUserConstraintType() == jsIntact) {
                //don't add it if it's broken
                _world->addConstraint(_joints[i], false);
            } else {
                sfDebug(TRUE, "Skipped joint %d - broken", i);
            }
        }
    }
}

void SFHumanoidRagdoll::unPublishRagdoll(){
    for (int i = 0; i < rpkAll; ++i) {
        if (_joints[i] != nil) {
            _world->removeConstraint(_joints[i]);
            _joints[i]->setUserConstraintType(jsIntact);
        }
        if (_bodies[i] == nil) {
            continue;
        }
        _world->removeObject(_bodies[i]);
    }
}

void SFHumanoidRagdoll::arrangePart(SFRagdollPartKind rpk, float x, float y, float z){
    btTransform transform;
    btRigidBody *body = _bodies[rpk];
    transform.setIdentity();
    transform.setOrigin(btVector3(x, y, z));
    body->setCenterOfMassTransform(transform);
    body->getMotionState()->setWorldTransform(transform);
}

void SFHumanoidRagdoll::joinParts(SFRagdollPartKind partKindA, 
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
                                  float limitZ){

    btTransform localA, localB;
    
    localA.setIdentity();
    localB.setIdentity();
    
    btTypedConstraint *joint;
    
    switch (jointKind) {
        case rjkCone:
            localA.getBasis().setEulerZYX(0, 0, eulerA);
            localB.getBasis().setEulerZYX(0, 0, eulerB);
            break;
        case rjkHinge:
            localA.getBasis().setEulerZYX(0, eulerA, 0);
            localB.getBasis().setEulerZYX(0, eulerB, 0);
            break;
        default:
            sfAssert(false, "Joint Kind unknown");
            break;
    }
    
    localA.setOrigin(btVector3(originAX, originAY, originAZ));
    localB.setOrigin(btVector3(originBX, originBY, originBZ));
    
    switch (jointKind) {
        case rjkCone:
            joint = new btConeTwistConstraint(*_bodies[partKindA],
                                              *_bodies[partKindB],
                                              localA,
                                              localB);
            ((btConeTwistConstraint*)joint)->setLimit(limitX, limitY, limitZ);
            break;
        case rjkHinge:
            joint = new btHingeConstraint(*_bodies[partKindA],
                                          *_bodies[partKindB],
                                          localA,
                                          localB);
            ((btHingeConstraint*)joint)->setLimit(limitX, limitY);
            break;
        default:
            break;
    }
    
    //set constraint refs so we can delete this constraint later
    //_bodies[partKindA]->addConstraintRef(joint);
    //_bodies[partKindB]->addConstraintRef(joint);
    
    //default it as intact
    joint->setUserConstraintType(jsIntact);
    
    _joints[partKindA] = joint;

}    

void SFHumanoidRagdoll::addBodyPart(btRigidBody *part, SFRagdollPartKind rpk){
    _bodies[rpk] = part;
    //set the sleeping thresholds
    part->getCollisionShape()->setMargin(0.03);
    part->setFriction(1.0f);
    //part->setLinearFactor(btVector3(0.0f,0.0f,0.0f));
    //part->setSleepingThresholds(1.0f, 2.0f);
}

void SFHumanoidRagdoll::buildRagdoll(){
    //we have all the parts - now we just link them up with constraints,
    //ready to hit the world whenever
    
    //we need to take into account the dimensions of these parts and
    //arrange their locations etc with respect to those - later
    
    //the body we are making looks a little like this:
    //
    //              0
    //      -   -   O   -   -
    //              v
    //          |       |
    //          |       |
    //          -       -
    //
    //where the only thing protruding forward is the feet
    
    
    // move the rigid bodies into the right positions
    // later this will be proportional and calculated
#if NO_WRISTS
    this->arrangePart(rpkForearmL,   0.35f,   -0.038f,    0.155f); 
    this->arrangePart(rpkForearmR,  -0.35f,   -0.038f,    0.155f);
#else
    this->arrangePart(rpkForearmL,   0.3f,   -0.038f,    0.155f); 
    this->arrangePart(rpkForearmR,  -0.3f,   -0.038f,    0.155f);
    this->arrangePart(rpkHandL,      0.4f,   -0.038f,    0.155f);
    this->arrangePart(rpkHandR,     -0.4f,   -0.038f,    0.155f);
#endif
    this->arrangePart(rpkBicepL,     0.15f,  -0.038f,    0.155f);
    this->arrangePart(rpkBicepR,    -0.15f,  -0.038f,    0.155f);
    this->arrangePart(rpkChest,      0.0f,   -0.038f,    0.105f);
    this->arrangePart(rpkFootL,      0.09f,  -0.088f,   -0.445f);
    this->arrangePart(rpkFootR,     -0.09f,  -0.088f,   -0.445f);
    this->arrangePart(rpkHead,       0.0f,   -0.051f,    0.464f);
    this->arrangePart(rpkLegL,       0.09f,  -0.038f,   -0.345f); 
    this->arrangePart(rpkLegR,      -0.09f,  -0.038f,   -0.345f);
    this->arrangePart(rpkMidriff,    0.0f,   -0.038f,   -0.095f);
    this->arrangePart(rpkThighL,     0.085f, -0.038f,   -0.245f);
    this->arrangePart(rpkThighR,    -0.085f, -0.038f,   -0.245f);
    
    // now that all the parts are in the right spots, we can
    // join them
#if NO_WRISTS
    this->joinParts(rpkForearmL,    rpkBicepL,      rjkCone,   M_PI,     M_PI,    -0.1f,  0.0f,   0.0f,   0.1f,   0.0f,   0.0f,   1.0f,   1.0f,   1.0f);
    this->joinParts(rpkForearmR,    rpkBicepR,      rjkCone,   M_PI,     M_PI,     0.1f,  0.0f,   0.0f,  -0.1f,   0.0f,   0.0f,   1.0f,   1.0f,   1.0f);
#else
    this->joinParts(rpkForearmL,    rpkBicepL,      rjkHinge,   M_PI_2,     M_PI_2,    -0.05f,  0.0f,   0.0f,   0.1f,   0.0f,   0.0f,   1.0f,   1.0f,   1.0f);
    this->joinParts(rpkForearmR,    rpkBicepR,      rjkHinge,   M_PI_2,     M_PI_2,     0.05f,  0.0f,   0.0f,  -0.1f,   0.0f,   0.0f,   1.0f,   1.0f,   1.0f);
    this->joinParts(rpkHandL,       rpkForearmL,    rjkHinge,   M_PI_2,     M_PI_2,    -0.05f,  0.0f,   0.0f,   0.05f,  0.0f,   0.0f,   1.0f,   1.0f,   1.0f);
    this->joinParts(rpkHandR,       rpkForearmR,    rjkHinge,   M_PI_2,     M_PI_2,     0.05f,  0.0f,   0.0f,  -0.05f,  0.0f,   0.0f,   1.0f,   1.0f,   1.0f);
#endif
    this->joinParts(rpkBicepL,      rpkChest,       rjkCone,    M_PI_2,     M_PI_2,    -0.1f,   0.0f,   0.0f,   0.05f,  0.0f,   0.05f,  1.0f,   1.0f,   1.0f);
    this->joinParts(rpkBicepR,      rpkChest,       rjkCone,    M_PI_2,     M_PI_2,     0.1f,   0.0f,   0.0f,  -0.05f,  0.0f,   0.05f,  1.0f,   1.0f,   1.0f);
    this->joinParts(rpkFootL,       rpkLegL,        rjkHinge,   M_PI_2,     M_PI_2,     0.0f,   0.05f,  0.05f,  0.0f,   0.0f,  -0.05f,  1.0f,   1.0f,   1.0f);
    this->joinParts(rpkFootR,       rpkLegR,        rjkHinge,   M_PI_2,     M_PI_2,     0.0f,   0.05f,  0.05f,  0.0f,   0.0f,  -0.05f,  1.0f,   1.0f,   1.0f);
    this->joinParts(rpkLegL,        rpkThighL,      rjkHinge,   M_PI_2,     M_PI_2,     0.0f,   0.0f,   0.05f,  0.05f,  0.0f,  -0.05f,  1.0f,   1.0f,   1.0f);
    this->joinParts(rpkLegR,        rpkThighR,      rjkHinge,   M_PI_2,     M_PI_2,     0.0f,   0.0f,   0.05f,  0.05f,  0.0f,  -0.05f,  1.0f,   1.0f,   1.0f);
    this->joinParts(rpkThighL,      rpkMidriff,     rjkCone,    M_PI_4,     M_PI_4,     0.0f,   0.0f,   0.05f,  0.085f, 0.0f,  -0.1f,   1.0f,   1.0f,   1.0f);
    this->joinParts(rpkThighR,      rpkMidriff,     rjkCone,    M_PI_4,     M_PI_4,     0.0f,   0.0f,   0.05f, -0.085f, 0.0f,  -0.1f,   1.0f,   1.0f,   1.0f);
    this->joinParts(rpkHead,        rpkChest,       rjkCone,    M_PI_2,     M_PI_2,     0.0f,   0.0f,  -0.25f,  0.0f,   0.01f,  0.1f,   1.0f,   1.0f,   1.0f);
    this->joinParts(rpkMidriff,     rpkChest,       rjkCone,    M_PI_2,     M_PI_2,     0.0f,   0.0f,   0.1f,   0.0f,   0.0f,  -0.1f,   1.0f,   1.0f,   1.0f);
}

void SFHumanoidRagdoll::breakRagdoll(SFRagdollPartKind rpk){
    //remove any joints to this part from the world
    //find all the joints for this body part and
    //break them (ie. set them as broken and remove them from the world)
    for (int i = 0; i < rpkAll; ++i) {
        if (_joints[i] == NULL) {
            continue;
        }
        btCollisionObject *bodyA, *bodyB, *bodyC;
        bodyA = &_joints[i]->getRigidBodyA();
        bodyB = &_joints[i]->getRigidBodyB();
        bodyC = _bodies[rpk];
        if (bodyC == nil) {
            continue;
        }
        if ((btRigidBody::upcast(bodyA)->getUserPointer() == btRigidBody::upcast(bodyC)->getUserPointer()) or
            (btRigidBody::upcast(bodyB)->getUserPointer() == btRigidBody::upcast(bodyC)->getUserPointer())){
            _joints[i]->setUserConstraintType(jsBroken);
        }
    }
}
