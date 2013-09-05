//
//  SF3DObject.h
//  ZombieArcade
//
//  Created by Adam Iredale on 11/11/09.
//  Copyright 2009 Stormforge Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SFProtocol.h"
#import "SFLoadableGameObject.h"
#import "SFMaterial.h"
#import "SFIpo.h"
#import "SFCamera.h"
#import "SFDefines.h"
#import "SFVertexGroup.h"
#import "SFConstraint.h"
#import "SFMotionState.h"
#import "SFPhysicsWorld.h"
#import "SFAction.h"
#import "SFSound.h"

#define SF_OBJECT_TAG_INVALID -1
#define DEBUG_SF3DOBJECT 0

typedef struct
{
	unsigned char		bounds;
	
	float				mass;
	float				damp;
	float				rotdamp;
	float				margin;
	
	float				linstiff;
	float				shapematch;
	
	unsigned char		citeration;
	unsigned char		piteration;
	
	btTriangleMesh		*_btTriangleMesh;
	
	btConvexHullShape	*_btConvexHullShape;
	
	btRigidBody			*_btRigidBody;
    
	btSoftBody			*_btSoftBody;
    
    SFMotionState       *_motionState;
    
    btCollisionObject *_physicsCollisionObject; //our physics body
    btCollisionShape *_physicsCollisionShape; //our collision shape
    
} SFObjectPhysicStruct;

typedef enum {
    wsExists,
    wsDoesNotExist,
    wsWantsInsertion,
    wsWantsRemoval,
    wsReserved,
    wsAll
} SFObjectWorldState;

typedef enum {
	OBJECT_WALKING,
	OBJECT_IDLE,
	OBJECT_TURNING_LEFT,
	OBJECT_TURNING_RIGHT,
	OBJECT_ATTACKING
} OBJECT_ACTION_STATE;

typedef enum {
    oaNone,
    oaFriendly,
    oaEnemy
} SFObjectAlliance;

@interface SF3DObject : SFLoadableGameObject {

    BOOL _isFake;
    
    SFObjectWorldState _worldState;
    
    BOOL _actionPlaying, _visible;
    
	SFColour            *_colour;
    
	float				_radius;
	float				_dst;
    
	unsigned int		_vbo;
    unsigned int        _bufferOffset;
    unsigned int        _iDataOffset;
	unsigned char		*_buf;
    id  _currentVertexGroup;
	unsigned int		_vbo_offset[ SF_OBJECT_NVBO_OFFSET ];
    
	SFVec *_dim;
    
	NSString *_ipoName;
	SFIpo *_ipo, *_nextIpo;
	
	NSMutableDictionary *_vertexGroups;
    
    SFObjectAlliance _objectAlliance;
    
    SFTransform *_transform;
    
	SFObjectPhysicStruct *_physicsInfo;
	
	SFObjectAnimationStruct *_SIO2objectanimation;
    
    NSString *_attackSoundName;
    SFSound *_sndAttack;
    
	int _ipoCurvesRemaining; //when playing an IPO this gives the number of curves still playing out
	float _currentForwardSpeed;
	BOOL _zoomedIn;
	BOOL _offsetOnly;
	BOOL _finalized;
	BOOL _onGround;
	BOOL _isLive;
	int _removeAfterRenderCount;
	BOOL _isWrapper;
    BOOL _isLeased;
    BOOL _physicsSetup;
    BOOL _isWorld;
    BOOL _actAsTrigger;
    SFVec *_triggerImpulse;
    NSMutableDictionary *_vertexGroupMaterials;
    NSMutableArray *_opaqueVertexGroups;
    NSMutableArray *_alphaTestVertexGroups;
    NSMutableArray *_alphaBlendVertexGroups;
    NSMutableArray *_transformStack;
    NSMutableArray *_constraintDefs;
    BOOL _poppedTransform;
    float _currentHealth;
    id _softOriginal;
    BOOL _requiresActionAnimation;
    SFConstraint *_currentConstraint;
    SFTransform *_originalTransform;
    unsigned char _actionState;
    float _baseDamageAmount;
    
    //duplicates
    id _nextDuplicate;
    
    float _turnDelta;
    int _turnsDeltasRemaining;
    
}
-(void)startTurn:(float)radians steps:(int)steps;
-(BOOL)continueTurn;
-(BOOL)isFake;
-(SFIpo*)ipo;
-(void)jump:(float)power;
-(void)forceImmediateExistance;
-(id)playFXSound:(NSString*)soundName;
-(SFObjectWorldState)worldState;
-(void)insertIntoWorld;
-(void)removeFromWorld;
-(void)reserve;
-(void)unReserve;
-(void)simulatePhysicsHit:(SF3DObject*)inflictor;
-(void)addObjectToWorld:(SFPhysicsWorld*)physicsWorld;
-(void)removeObjectFromWorld:(SFPhysicsWorld*)physicsWorld;
-(SF3DObject*)findSpawnableObject;
-(SF3DObject*)nextDuplicate;
-(void)pruneDuplicates;
-(void)replicate:(int)count;
-(NSDictionary*)vertexGroups;
-(id)playGetSound;
-(id)playPutSound;
-(void)stopAngularMovement;
-(void)stopLinearMovement;
-(int)getBlenderInt:(id)infoKey;
-(float)getBlenderFloat:(id)infoKey;
-(BOOL)getBlenderBool:(id)infoKey;
-(void)setTransformFromBtTransform:(btTransform*)transform;
-(void)setupConstraintsToObject:(id)object;
-(void)updateDistanceFromCamera:(SFCamera *)camera;
-(BOOL)setAction:(SFAction*)action _interp:(float)_interp _fps:(float)_fps startFrame:(int)startFrame;
-(void)synchronisePhysicsTransform;
-(btRigidBody*)getConstraintTargetBody:(id)constraintKey;
-(id)proxyTarget;
-(float)damageAmount;
+(BOOL)enableCollisionCallback;
-(void)attack;
-(int)getNumVerts;
-(void)setFirstSpawnTransform:(SFTransform*)transform;
-(NSString*)getActionName:(NSString*)actionType;
-(void)enableCollisions:(BOOL)enable;
-(BOOL)render:(unsigned int)renderPass matrixTransform:(unsigned char)matrixTransform useMaterial:(BOOL)useMaterial;
-(void)hitWorld:(id)worldObject;
-(void)renderVertexGroups:(unsigned int)renderPass useMaterial:(BOOL)useMaterial materialObject:(id)materialObject;
-(void)setSoftOriginal:(id)softOriginal;
-(void)resetToOriginalTransform;
-(float)getCalculatedDamageAmount;
-(int)getBlenderTag;
-(BOOL)isLive;
-(id)getActions;
-(btRigidBody*)getRigidBody;
-(float)getCameraDistance;
-(SFVertexGroup*)vertexGroupByName:(NSString*)name;
-(BOOL)isWorld;
-(SFTransform*)transform;
-(void)pauseAnimation:(BOOL)paused;

//blender convenience fns
-(NSString*)getBlenderInfo:(id)infoKey;
-(int)getBlenderInt:(id)infoKey;
-(float)getBlenderFloat:(id)infoKey;
-(BOOL)getBlenderBool:(id)infoKey;
-(void)setBlenderInfo:(id)value infoKey:(id)infoKey;

-(void)objectDidDie:(float)finalDamageAmount fromInflictor:(id)inflictor;
-(void)objectWasHurt:(float)damageAmount fromInflictor:(id)inflictor;

-(void)bindMaterials:(SFResource*)useResource;
-(SFTransform*)transform;
-(void)setTransformFromBtTransform:(btTransform*)transform;
-(void)setRadius:(float)radius;
-(void)setTransform:(SFTransform*)transform;
-(void)setDimensions:(SFVec*)dim;
-(void)setIpo:(SFIpo*)ipo;
-(SFIpo*)ipo;
-(void)wasHitBy:(SF3DObject*)attacker;
-(void)didHit:(SF3DObject*)victim;
+(BOOL)takesDamageFrom:(Class)attackerClass;
-(void)removeAfter:(float)removeDelay;
-(float)damageAmount;
-(void)goIdle;
-(void)moveForward:(float)speed;
-(vec3)getTargetDirectionDiff:(SF3DObject*)target;
-(void)stopMoving;
-(SFVec*)dimensions;
-(BOOL)getOnGround;
-(id)constraintDefs;
-(void)show;
-(void)hide;
-(BOOL)objectIsPhysical;
-(BOOL)hasConstraints;
-(void)setCollisionFlags:(unsigned int)collisionFlags;
-(void)wakePhysics;
-(void)sleepPhysics;
-(void)setup3dObject;
-(void)checkVisibility;
-(void)playAction:(NSString*)actionName loopAction:(BOOL)loopAction randomStart:(BOOL)randomStart;
-(void)play:(BOOL)loopAction;
-(void)processWorldState:(SFPhysicsWorld*)physicsWorld;
-(SFObjectAlliance)objectAlliance;
-(void)setAttackSoundObject:(SFSound*)sound;
-(void)activateTrigger:(id)activatedBy;
-(BOOL)doesActAsTrigger;
-(void)setBodyLinearVelocity:(btVector3)velocity;

@end
