//
//  SFPhysicsWorld.mm
//  ZombieArcade
//
//  Created by Adam Iredale on 23/03/10.
//  Copyright 2010 Stormforge Software. All rights reserved.
//

#include "SFPhysicsWorld.h"
#include "SFUtils.h"
#include "btQuickprof.h"
#include "SFGL.h"
#include "SFSceneManager.h"

#if DEBUG_SFPHYSICSWORLD
    #include "GLDebugDrawer.h"
    GLDebugDrawer debugDrawer;
#define DRAW_FLAGS_CONSTRAINTS_ONLY btIDebugDraw::DBG_DrawConstraints
#define DRAW_FLAGS_BOUNDS btIDebugDraw::DBG_DrawAabb
#define DRAW_FLAGS_WIREFRAME_ONLY btIDebugDraw::DBG_DrawWireframe
#define DEBUG_DRAW_FLAGS DRAW_FLAGS_WIREFRAME_ONLY
#endif

#define DEFAULT_GRAVITY Vec3Make(0.0f, 0.0f, -9.8f)
#define DEFAULT_AIR_DENSITY 1.2f
#define DEFAULT_WATER_DENSITY 0.0f
#define DEFAULT_WATER_OFFSET 0.0f
#define DEFAULT_WATER_NORMAL btVector3(0.0f, 0.0f, 1.0f)
#define LOWEST_FRAMERATE 5.0f
#define DUMP_PROFILER 0

//custom physpick that doesn't pick up no-contact objects
struct	ClosestNoGhostRayResultCallback : public btCollisionWorld::RayResultCallback
{
    
    ClosestNoGhostRayResultCallback(const btVector3& rayFromWorld,const btVector3& rayToWorld)
    :m_rayFromWorld(rayFromWorld),
    m_rayToWorld(rayToWorld)
    {
    }
    
    btVector3	m_rayFromWorld;//used to calculate hitPointWorld from hitFraction
    btVector3	m_rayToWorld;
    
    btVector3	m_hitNormalWorld;
    btVector3	m_hitPointWorld;
    
    virtual	btScalar	addSingleResult(btCollisionWorld::LocalRayResult& rayResult,bool normalInWorldSpace)
    {
        //caller already does the filter on the m_closestHitFraction
        btAssert(rayResult.m_hitFraction <= m_closestHitFraction);
        
        m_closestHitFraction = rayResult.m_hitFraction;
        m_collisionObject = rayResult.m_collisionObject;
        if (normalInWorldSpace)
        {
            m_hitNormalWorld = rayResult.m_hitNormalLocal;
        } else
        {
            ///need to transform normal into worldspace
            m_hitNormalWorld = m_collisionObject->getWorldTransform().getBasis()*rayResult.m_hitNormalLocal;
        }
        m_hitPointWorld.setInterpolate3(m_rayFromWorld,m_rayToWorld,rayResult.m_hitFraction);
        return rayResult.m_hitFraction;
    }
    virtual bool needsCollision(btBroadphaseProxy* proxy0) const
    {
        bool collides = (proxy0->m_collisionFilterGroup & m_collisionFilterMask) != 0;
        btCollisionObject *collisionObject = (btCollisionObject*)proxy0->m_clientObject;
        collides = collides && !(btCollisionObject::CF_NO_CONTACT_RESPONSE & collisionObject->getCollisionFlags());
        return collides;
    }
};


bool collisionCallback( btManifoldPoint &cp,
						const btCollisionObject *colObj0,int partId0, int index0, 
						const btCollisionObject *colObj1,int partId1, int index1 )
{
    return [[[SFSceneManager alloc] currentScene] sfPhysicsCollisionCallback:cp
                                                                     colObj0:colObj0
                                                                     partId0:partId0
                                                                      index0:index0
                                                                     colObj1:colObj1
                                                                     partId1:partId1
                                                                      index1:index1];
}

SFPhysicsWorld::SFPhysicsWorld(id scene){
    _simulationEnabled = true;
    _scene = [scene retain];
    _lastStepTime = -1;
    _collisionConfiguration     = new btDefaultCollisionConfiguration();
    _dispatcher					= new btCollisionDispatcher(_collisionConfiguration);	
    _pairCache					= new btDbvtBroadphase();
    _constraintSolver           = new btSequentialImpulseConstraintSolver();
    _world                      = new btDiscreteDynamicsWorld(_dispatcher,	
                                                               _pairCache,
                                                               _constraintSolver,
                                                               _collisionConfiguration);
    gContactAddedCallback = collisionCallback;
    _world->setGravity(btVector3(DEFAULT_GRAVITY.x,
                                 DEFAULT_GRAVITY.y,
                                 DEFAULT_GRAVITY.z));
}

SFPhysicsWorld::~SFPhysicsWorld(){
    delete _world;
    delete _collisionConfiguration;
	delete _dispatcher;
	delete _pairCache;
	delete _constraintSolver;
    [_scene release];
    _scene = NULL;
}

void SFPhysicsWorld::addConstraint(btTypedConstraint *constraint, bool disableCollisions){
    _world->addConstraint(constraint, disableCollisions);
}

void SFPhysicsWorld::stepSimulationDelta(float seconds){
    //purely for debugging, this allows us to step the simulation
    //one interval at a time
    _world->stepSimulation(seconds, 60.0);
}

void SFPhysicsWorld::stepSimulation(){
    if (!_simulationEnabled) {
        _lastStepTime == -1;
        return;
    }
    if (_lastStepTime == -1) {
        //this is the first step
        _lastStepTime = getAppSecs();
    }
    _world->stepSimulation(getAppSecDiff(_lastStepTime), 60.0/LOWEST_FRAMERATE);
    _lastStepTime = getAppSecs();
#if DUMP_PROFILER
    CProfileManager::dumpAll();
#endif
}

id SFPhysicsWorld::pickObject(btVector3* rayTo, btVector3* cameraPos, btVector3* hitPos){

	ClosestNoGhostRayResultCallback rayCallback(*cameraPos, *rayTo);
	
	_world->rayTest(*cameraPos, *rayTo, rayCallback);
	
	if( rayCallback.hasHit() )
	{
		*hitPos = rayCallback.m_hitPointWorld;
		return (id)((btRigidBody*)rayCallback.m_collisionObject)->getUserPointer();
	}
	
	return NULL;
}

void SFPhysicsWorld::addObject(btRigidBody *object){
    if (!object) {
        return;
    }
    _world->addRigidBody(object);
}

void SFPhysicsWorld::removeObjectConstraints(btRigidBody *object){
    int constraintCount = object->getNumConstraintRefs();
    for (int i = constraintCount - 1; i >= 0; --i) {
        btTypedConstraint *constraint = object->getConstraintRef(i);
        _world->removeConstraint(constraint);
    }
}

void SFPhysicsWorld::removeObject(btRigidBody *object){
    if (!object) {
        return;
    }
    _world->removeRigidBody(object);
}

void SFPhysicsWorld::removeConstraint(btTypedConstraint *constraint){
    _world->removeConstraint(constraint);
}

void SFPhysicsWorld::constrainRigidBodies(SFConstraint *constraintInfo, btRigidBody *bodyA, btRigidBody *bodyB){
	
	btTransform frameInA;
	btTransform frameInB;
    
	frameInA.setIdentity();
	frameInA.setOrigin(constraintInfo->pivot());
	
	frameInB.setIdentity();
	frameInB.setOrigin((bodyA->getWorldTransform().getOrigin() + constraintInfo->pivot()) 
                       - bodyB->getWorldTransform().getOrigin());

    btConeTwistConstraint *gdof = new btConeTwistConstraint(*bodyA, *bodyB, frameInA, frameInB);
	
	//hardcoded overridden limits
	bodyA->setLinearFactor(btVector3(1,1,1));
	bodyA->setAngularFactor(btVector3(1,1,1));
	
	bodyB->setLinearFactor(btVector3(1,1,1));
	bodyB->setAngularFactor(btVector3(1,1,1));
    
    bodyA->addConstraintRef(gdof);
    bodyB->addConstraintRef(gdof);
    
    _world->addConstraint(gdof, 0);
}

void SFPhysicsWorld::renderDebug(){
#if DEBUG_SFPHYSICSWORLD
    // If the physics world doesn't have a debug drawer attached,
    // create and attach a new one...
    if(!_world->getDebugDrawer())
    {
        debugDrawer.setDebugMode(DEBUG_DRAW_FLAGS);
        _world->setDebugDrawer(&debugDrawer);
    }

    SFGL::instance()->objectReset();
    SFGL::instance()->materialReset();
    
    _world->debugDrawWorld();
#endif
}

void SFPhysicsWorld::enableSimulation(bool enable){
    _simulationEnabled = enable;
}
