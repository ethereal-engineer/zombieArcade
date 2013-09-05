//
//  SFPhysicsWorld.h
//  ZombieArcade
//
//  Created by Adam Iredale on 23/03/10.
//  Copyright 2010 Stormforge Software. All rights reserved.
//

#include "SFConstraint.h"
#include "btDiscreteDynamicsWorld.h"
#include "btDefaultCollisionConfiguration.h"
#include "SFObj.h"

#define DEBUG_SFPHYSICSWORLD 0

//the physics world...
class SFPhysicsWorld : public SFObj {
    float   _lastStepTime;
    id      _scene;
    btDynamicsWorld                             *_world;
    btCollisionConfiguration                    *_collisionConfiguration;
	btCollisionDispatcher						*_dispatcher;
	btBroadphaseInterface						*_pairCache;
	btConstraintSolver							*_constraintSolver;
	//btSoftBodyWorldInfo							 _worldInfo;
    bool _simulationEnabled;
public:
    SFPhysicsWorld(id scene);
    ~SFPhysicsWorld();
    void stepSimulation();
    void stepSimulationDelta(float seconds);
    id pickObject(btVector3* rayTo, btVector3* cameraPos, btVector3* hitPos);
    void addConstraint(btTypedConstraint *constraint, bool disableCollisions);
    void addObject(btRigidBody *object);
    void removeObject(btRigidBody *object);
    void removeObjectConstraints(btRigidBody *object);
    void removeConstraint(btTypedConstraint *constraint);
    void constrainRigidBodies(SFConstraint *constraint, btRigidBody *bodyA, btRigidBody *bodyB);
    void renderDebug();
    void enableSimulation(bool enable);
};

