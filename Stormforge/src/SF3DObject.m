//
//  SF3DObject.m
//  ZombieArcade
//
//  Created by Adam Iredale on 11/11/09.
//  Copyright 2009 Stormforge Software. All rights reserved.
//

#import "SF3DObject.h"
#import "SFUtils.h"
#import "SFSceneManager.h"
#import "SFScoreManager.h"
#import "btTransform.h"
#import "SFTransform.h"
#import "SFSound.h"
#import "SFGLManager.h"
#import "SFDebug.h"
#import "SFColour.h"
#import "SFGameEngine.h"

#define DEFAULT_OBJECT_HEALTH 1.0f
#define DEBUG_DRAW_OBJECT 0
#define FORCE_EQUAL_MASS 1

@implementation SF3DObject

-(BOOL)continueTurn{
    //continue a turn that has been already set up by "turn"
    if (_turnsDeltasRemaining > 0) {
        //set the rotation of the target to be altered by the delta
        _transform->rot()->addZ(_turnDelta);
        [self synchronisePhysicsTransform];
        --_turnsDeltasRemaining;
        return YES;
    }
    //return NO if no turn to continue
    return NO;
}

-(void)startTurn:(float)radians steps:(int)steps{
    //perform a turn of X radians in N steps
    _turnDelta = radians / (float)steps;
    _turnsDeltasRemaining = steps;
    //play the turn animation
    if (_actionState == OBJECT_WALKING){
        //just turn, don't change animation
        //in this case
        return;
    }
    if (radians > 0) {
        //left
        if (_actionState != OBJECT_TURNING_LEFT) {
            //sfDebug(TRUE, "Turning Left...");
            [self playAction:[self getActionName:@"turnLeft"] loopAction:YES randomStart:YES];
            _actionState = OBJECT_TURNING_LEFT;
        }
    } else {
        //right
        if (_actionState != OBJECT_TURNING_RIGHT) {
            //sfDebug(TRUE, "Turning Right...");
            [self playAction:[self getActionName:@"turnRight"] loopAction:YES randomStart:YES];
            _actionState = OBJECT_TURNING_RIGHT;
        }
    }
}

-(void)jump:(float)power{
    //assumes a Z up vector
//    [self unlockLinearMovement];
//	[self stopAngularMovement];
//	[self lockAngularMovement];
//	[self wakePhysics];
//    [self getRigidBody]->applyCentralImpulse(btVector3(0,0,power));
}

-(void)stopLinearMovement{
	[self getRigidBody]->setLinearVelocity(btVector3(0.0f, 0.0f, 0.0f));
}

-(void)stopAngularMovement{
	[self getRigidBody]->setAngularVelocity(btVector3(0.0f, 0.0f, 0.0f));
}

-(void)stopMoving{
	//stop walking speed and turning and grind to a halt
	[self stopLinearMovement];
	[self stopAngularMovement];
}

-(void)bufferFloats:(float*)floats floatCount:(int)floatCount jumpSize:(int)jumpSize{
    for (int i = 0; i < floatCount; ++i) {
        memcpy(&_buf[_bufferOffset], &floats[i], sizeof(float));
        _bufferOffset += jumpSize;
    }
}

-(void)bufferUnsignedChars:(float*)floats count:(int)count jumpSize:(int)jumpSize{
    for (int i = 0; i < count; ++i) {
        unsigned char thisChar = floats[i];
        memcpy(&_buf[_bufferOffset], &thisChar, sizeof(unsigned char));
        _bufferOffset += jumpSize;
    }    
}

-(void)bufferIData:(float*)floats{
    //idata is laid out as follows:
    // idata count, ....(idata items)....
    int count = floats[0];
    for (int i = 0; i < count; ++i) {
        [_currentVertexGroup addVertexShort:floats[i + 1]];
    }
}

-(void)setupOffsets:(float*)floats{
    for (int i = SF_OBJECT_SIZE; i < SF_OBJECT_NVBO_OFFSET; ++i) {
        //let's hope the exporter is in sync!
        _vbo_offset[i] = floats[i];
    }
    
    //and now that we know the object size we can set up the buffer size
    //this might be an expanding buffer in future instead....
    _buf = (unsigned char*)malloc(_vbo_offset[SF_OBJECT_SIZE]);
    _bufferOffset = 0;
}

-(BOOL)loadInfo:(SFTokens*)tokens{

    if (tokens->tokenIs("v") or tokens->tokenIs("n")) {
        [self bufferFloats:tokens->valueAsFloats(3) floatCount:3 jumpSize:4];
        return YES;
    }

    if (tokens->tokenIs("c")) {
        //[self bufferCharFromString:[value stringByAppendingString:@" 255.0"] jumpSize:1];
        [self bufferUnsignedChars:tokens->valueAsFloats(3) count:3 jumpSize:1];
        return YES;
    }
    

    if (tokens->tokenIs("u0") or tokens->tokenIs("u1")) {
        [self bufferFloats:tokens->valueAsFloats(2) floatCount:2 jumpSize:4];
        //[self bufferFloatFromString:value jumpSize:4];
        return YES;
    }

    if (tokens->tokenIs("i")) {
        //[self bufferIData:value];
        [self bufferIData:tokens->valueAsFloats(-1)];
        return YES;
    }
    
    if (tokens->tokenIs("vb")) {
        [self setupOffsets:tokens->valueAsFloats(SF_OBJECT_NVBO_OFFSET)];
        return YES;
    }

    if (tokens->tokenIs("ng")) {
        //it's irrelevant now as it refers to total number of groups
        //including the non-exported bone groups
        _vertexGroups = [[NSMutableDictionary alloc] init];
        return YES;
    }
    
    if (tokens->tokenIs("g")) {
        //normally used to advance and create the vertex group
        _currentVertexGroup = [[SFVertexGroup alloc] initWithDictionary:nil];
        [_vertexGroups setObject:_currentVertexGroup forKey:[NSString stringWithUTF8String:tokens->valueAsString()]];
        [_currentVertexGroup release]; //will be freed with the groups
        return YES;
    }

    if (tokens->tokenIs("mt")) {
        [_currentVertexGroup setMaterialName:[[NSString stringWithUTF8String:tokens->valueAsString()] lastPathComponent]];
        return YES;
    }            
    
    if (tokens->tokenIs("ni")) {
        float *floats = tokens->valueAsFloats(2);
        [_currentVertexGroup setVertexCount:floats[0]
                                       mode:floats[1]];
        _iDataOffset = 0;
        return YES;
    } 

    if (tokens->tokenIs("l")) {
        _transform->loc()->setFloats(tokens->valueAsFloats(3), 3);
        return YES;
    }
    
    if (tokens->tokenIs("r")) {
        _transform->rot()->setFloats(tokens->valueAsFloats(3), 3);
        return YES;
    }
    
    if (tokens->tokenIs("s")) {
        _transform->scl()->setFloats(tokens->valueAsFloats(3), 3);
        return YES;
    }
                
    if (tokens->tokenIs("ra")) {
        _radius = tokens->valueAsFloats(1)[0];
        return YES;
    }

    if (tokens->tokenIs("b")) {
        _physicsInfo->bounds = tokens->valueAsFloats(1)[0];
        return YES;
    }
    
    if (tokens->tokenIs("ma")) {
        _physicsInfo->mass = tokens->valueAsFloats(1)[0];
        return YES;
    }
    
    if (tokens->tokenIs("da")) {
        _physicsInfo->damp = tokens->valueAsFloats(1)[0];
        return YES;
    }
    
    if (tokens->tokenIs("rd")) {
        _physicsInfo->rotdamp = tokens->valueAsFloats(1)[0];
        return YES;
    }
       
    if (tokens->tokenIs("mr")) {
        _physicsInfo->margin = tokens->valueAsFloats(1)[0];
        return YES;
    }

    if (tokens->tokenIs("di")) {
        _dim->setFloats(tokens->valueAsFloats(3), 3);
        return YES;
    }

    if (tokens->tokenIs("ip")) {
        _ipoName = [[[NSString stringWithUTF8String:tokens->valueAsString()] lastPathComponent] retain];
        return YES;
    }

    if (tokens->tokenIs("ls")) {
        _physicsInfo->linstiff = tokens->valueAsFloats(1)[0];
        return YES;
    }
                
    if (tokens->tokenIs("sm")) {
        _physicsInfo->shapematch = tokens->valueAsFloats(1)[0];
        return YES;
    }

    if (tokens->tokenIs("ci")) {
        _physicsInfo->citeration = tokens->valueAsFloats(1)[0];
        return YES;
    }
    
    if (tokens->tokenIs("pi")) {
        _physicsInfo->piteration = tokens->valueAsFloats(1)[0];
        return YES;
    }
    
    if (tokens->tokenIs("con_n")) {
        //a constraint - name first
        _currentConstraint = new SFConstraint(tokens->valueAsString());
        [[self constraintDefs] addObject:[NSValue valueWithPointer:_currentConstraint]];
        return YES;
    }
    
    if (tokens->tokenIs("con_i")) {
        _currentConstraint->setInfluence(tokens->valueAsFloats(1)[0]);
        return YES;
    }
    
    if (tokens->tokenIs("con_t")) {
        _currentConstraint->setTargetName(tokens->valueAsString());
        return YES;
    }
    
    if (tokens->tokenIs("con_ax")) {
        _currentConstraint->setAxis(tokens->valueAsFloats(3));
        return YES;
    }
    
    if (tokens->tokenIs("con_lmx")) {
        _currentConstraint->setMaxLocation(tokens->valueAsFloats(3));
        return YES;
    }
    
    if (tokens->tokenIs("con_rmx")) {
        _currentConstraint->setMaxRotation(tokens->valueAsFloats(3));
        return YES;
    }
    
    if (tokens->tokenIs("con_lmn")) {
        _currentConstraint->setMinLocation(tokens->valueAsFloats(3));
        return YES;
    }
    
    if (tokens->tokenIs("con_rmn")) {
        _currentConstraint->setMinRotation(tokens->valueAsFloats(3));
        return YES;
    }
    
    if (tokens->tokenIs("con_p")) {
        _currentConstraint->setPivot(tokens->valueAsFloats(3));
        return YES;
    }
    
    if (tokens->tokenIs("triggerKind")) {
        //for now this is just physImpulse
        _actAsTrigger = YES;
        return YES;
    }
    
    if (tokens->tokenIs("triggerData")) {
        //for now this is just a vector in string form
        _triggerImpulse = new SFVec();
        _triggerImpulse->setFloats(tokens->valueAsFloats(3), 3);
    }
    
    //any missed tokens are set as blender info
    [self setBlenderInfo:[NSString stringWithUTF8String:tokens->valueAsString()] infoKey:[NSString stringWithUTF8String:tokens->tokenName()]];
    return YES; //we can't really discern between skipped items and extra info
}

-(BOOL)doesActAsTrigger{
    return _actAsTrigger;
}

-(void)objectWasHurt:(float)damageAmount fromInflictor:(id)inflictor{
   
}

-(void)objectDidDie:(float)finalDamageAmount fromInflictor:(id)inflictor{
    [self removeAfter:0];
}

-(void)resetFlagState:(u_int64_t)flagMask{
    [super resetFlagState:flagMask];
    //this is called during the loader so we hook it to
    //know if we are physical or not
    if ([self objectIsPhysical]) {
        if (_physicsSetup){
            return;
        }
        _physicsInfo = (SFObjectPhysicStruct *) calloc(1, sizeof(SFObjectPhysicStruct));
        _physicsInfo->damp = 0.04f;
        _physicsInfo->rotdamp = 0.1f;
        sfDebug(DEBUG_SF3DOBJECT, "Alloc'd physics structure for %s", [self UTF8Description]);
    }
}

+(NSDictionary*)actionDictionary{
    return nil;
}

-(void)bindActions:(id)useResource{
    NSEnumerator *actions = [[[self class] actionDictionary] objectEnumerator];
    for (id actionName in actions) {
        [useResource getItem:actionName itemClass:[SFAction class] tryLoad:YES];
    }
}

-(BOOL)isFake{
    return _isFake;
}

-(void)resolveDependantItems:(id)useResource{
    [super resolveDependantItems:useResource];
    //if we have been loaded in retrospect (on demand), resolve all our
    //things like materials, sounds etc
    [self bindMaterials:useResource];
    [self bindActions:useResource];
    [self precache];
}

-(BOOL)takeDamageFrom:(id)inflictor{
    //reduces the object's health until it is no longer _live
    if (!_isLive) {
        return NO; //can't take damage - it's dead
    }
    
    float damageAmount = [inflictor damageAmount];
    
    if (_currentHealth - damageAmount <= 0) {
        _isLive = NO;
        [self objectDidDie:damageAmount fromInflictor:inflictor];
        return YES;
    } else {
        _currentHealth -= damageAmount;
        [self objectWasHurt:damageAmount fromInflictor:inflictor];
        return YES;
    }
}

-(void)tearDownPhysicsObject{
    //destroy the physics part of this object
	if (!_physicsSetup){
        return;
    }
    
    //the original version cycles through looking for duplicates of the btrigidbody - I don't use that so it's much
    //simplified
    delete _physicsInfo->_physicsCollisionShape;
    delete _physicsInfo->_motionState;
    
    _physicsInfo->_physicsCollisionShape = nil;
    _physicsInfo->_motionState = nil;
}

-(SFObjectAlliance)objectAlliance{
    return _objectAlliance;
}

-(void)setTransformFromBtTransform:(btTransform*)transform{
    //if (_ipo and ([_ipo isPlaying])) {
//        [self synchronisePhysicsTransform];
//        return;
//    }
    transform->getOpenGLMatrix(_transform->matrix());
    _transform->updateLocFromMatrix();
    //_transform->updateRotFromMatrix();
    btScalar yaw, pitch, roll;
    btMatrix3x3 rotationMatrix = btMatrix3x3(transform->getRotation());
	rotationMatrix.getEulerYPR(yaw, pitch, roll);
    _transform->rotateZRadians(yaw); //update the direction (Z axis only atm)
}

-(void)setupPhysicsCollisionShape{
    
	switch(_physicsInfo->bounds )
	{
        case SF_PHYSIC_CAPSULE:
        {
            //here we do a bit of deduction - if the shape is wider than tall we use a capsule, otherwise we
            //use a capsule Z
            float width  = _dim->x() * _transform->scl()->x(),
                  height = _dim->z() * _transform->scl()->z();
            if (width > height) {
                _physicsInfo->_physicsCollisionShape = new btCapsuleShapeX(height / 2.0f, width);
            } else {
                _physicsInfo->_physicsCollisionShape = new btCapsuleShapeZ(width / 2.0f, height);
            }
            break;
        }
        
		case SF_PHYSIC_BOX:
		{
			_physicsInfo->_physicsCollisionShape = new btBoxShape(btVector3(_dim->x() * _transform->scl()->x(),
                                                              _dim->y() * _transform->scl()->y(),
                                                              _dim->z() * _transform->scl()->z()));
			break;
		}
            
		case SF_PHYSIC_SPHERE:
		{
			_physicsInfo->_physicsCollisionShape = new btSphereShape( _radius * 0.575f ); //radians to degrees???
			break;
		}
            
		case SF_PHYSIC_CYLINDER:
		{
			_physicsInfo->_physicsCollisionShape = new btCylinderShapeZ(btVector3(_dim->x() * _transform->scl()->x(),
                                                                    _dim->y() * _transform->scl()->y(),
                                                                    _dim->z() * _transform->scl()->z()));
			break;
		}
            
		case SF_PHYSIC_CONE:
		{
			_physicsInfo->_physicsCollisionShape = new btConeShapeZ(_dim->x() * _transform->scl()->x(),
                                                      _dim->z() * _transform->scl()->z() * 2.0f);
			break;
		}
            
		case SF_PHYSIC_TRIANGLEMESH:
		{
            
			btVector3 tri[ 3 ];
			
			_physicsInfo->_btTriangleMesh = new btTriangleMesh();
            
            NSEnumerator *vertexGroups = [_vertexGroups objectEnumerator];
			for (SFVertexGroup *vertexGroup in vertexGroups) {
                if ([vertexGroup mode] == GL_TRIANGLES)
				{
					for (unsigned int j = 0; j < [vertexGroup vertexCount]; j += 3) {
						memcpy( &tri[ 0 ][ 0 ], &_buf[[vertexGroup vertices][ j     ] * 12 ], 12 );
						memcpy( &tri[ 1 ][ 0 ], &_buf[[vertexGroup vertices][ j + 1 ] * 12 ], 12 );
						memcpy( &tri[ 2 ][ 0 ], &_buf[[vertexGroup vertices][ j + 2 ] * 12 ], 12 );
						
						_physicsInfo->_btTriangleMesh->addTriangle( tri[ 0 ], tri[ 1 ], tri[ 2 ], 1 );
					}
				} else if ([vertexGroup mode] == GL_TRIANGLE_STRIP ) {
                    for (unsigned int j = 2; j < [vertexGroup vertexCount]; ++j) {
						memcpy( &tri[ 0 ][ 0 ], &_buf[[vertexGroup vertices][ j - 2 ] * 12 ], 12 );
						memcpy( &tri[ 1 ][ 0 ], &_buf[[vertexGroup vertices][ j - 1 ] * 12 ], 12 );
						memcpy( &tri[ 2 ][ 0 ], &_buf[[vertexGroup vertices][ j     ] * 12 ], 12 );
						
						_physicsInfo->_btTriangleMesh->addTriangle( tri[ 0 ], tri[ 1 ], tri[ 2 ], 1 );
					}				
				}
            }
            
			_physicsInfo->_physicsCollisionShape = new btBvhTriangleMeshShape( _physicsInfo->_btTriangleMesh, 1, 1 );
			
			break;
		}
            
		case SF_PHYSIC_CONVEXHULL:		
		{
			unsigned int n_vert = [self getNumVerts];
            
			btVector3 vert;
            
			_physicsInfo->_btConvexHullShape = new btConvexHullShape();
			
			_physicsInfo->_btConvexHullShape->setMargin( 0.01f );
			   
			for (unsigned int i = 0; i < n_vert; ++i) {
                memcpy( &vert[ 0 ], &_buf[ i * 12 ], 12 );
				_physicsInfo->_btConvexHullShape->addPoint( vert );
            }
             
			_physicsInfo->_physicsCollisionShape = _physicsInfo->_btConvexHullShape;
			
			break;
		}
	}
    
    //setup collision shape options
    
	if(_physicsInfo->margin )
	{
		_physicsInfo->_physicsCollisionShape->setMargin(_physicsInfo->margin );
	}
    
}

-(BOOL)objectIsPhysical{
    //true if this object exists in the physics realm as well
    //as the graphical realm
    return [self flagState:SF_OBJECT_ACTOR or SF_OBJECT_GHOST];
}

-(btTransform)getTransformForPhysics{
    btTransform physTransform;
    physTransform.setIdentity();
    //compile the transform so we can use the opengl matrix to setup the phys object
    _transform->compileMatrix();
    physTransform.setFromOpenGLMatrix(_transform->matrix());
    return physTransform;
}

-(void)setupMaterialPhysics{
    if (![self objectIsPhysical]) {
        return;
    }
    if ([_vertexGroups count]) {
        
        float maxFriction = 0.0f;
        float maxRestitution = 0.0f;
        
        NSEnumerator *vertexGroups = [_vertexGroups objectEnumerator];
		for (SFVertexGroup *vertexGroup in vertexGroups){
            id vertexGroupMat = [vertexGroup material];
			if( vertexGroupMat )
			{
				maxFriction = MAX(maxFriction, [vertexGroupMat friction]);
                maxRestitution = MAX(maxRestitution, [vertexGroupMat restitution]);
			}
		}
        
        if (maxFriction) {
            _physicsInfo->_btRigidBody->setFriction(maxFriction);
        }
        
        if (maxRestitution) {
            _physicsInfo->_btRigidBody->setRestitution(maxRestitution);
        }
        
	}
}

-(void)moveForward:(float)speed{
    //to override
}

-(void)setupPhysicsObject{
    //sets up the physics world object
    //for this 3d object (if required)

	//btTransform transform;
	//btVector3 _btVector3( 0.0f, 0.0f, 0.0f );
	
    if (![self objectIsPhysical]) {
        return; //only set up physics on physics objects
    }
    
    //based on our SIO2 object options,
    //set up our collision mesh
    [self setupPhysicsCollisionShape];
    
    //setup our starting place in the physics world
	_physicsInfo->_motionState = new SFMotionState([self getTransformForPhysics], 
                                                   self, 
                                                   @selector(setTransformFromBtTransform:));
    
    //calculate our local inertia from our mass
    btVector3 localInertia = btVector3(0,0,0);
    if(_physicsInfo->mass )
	{		
#if FORCE_EQUAL_MASS
        _physicsInfo->mass = 1.0f;
#endif
		_physicsInfo->_physicsCollisionShape->calculateLocalInertia(_physicsInfo->mass, localInertia);
	}
    
    //setup our actual physical entity
	_physicsInfo->_btRigidBody = new btRigidBody(_physicsInfo->mass,
                                                      _physicsInfo->_motionState,
                                                      _physicsInfo->_physicsCollisionShape,
                                                      localInertia);
    
    //if the object is just dynamic (and not a rigidbody in blender), then we don't let it roll
    //but we let it move - and also set up its damping
	if ([self flagState:SF_OBJECT_DYNAMIC]){
		if (![self flagState:SF_OBJECT_RIGIDBODY]){ 
            [self getRigidBody]->setAngularFactor(btVector3(0.0f, 0.0f, 1.0f));
        }
		[self getRigidBody]->setDamping(_physicsInfo->damp,
                                        _physicsInfo->rotdamp);
	}
	
	//if this is a no-sleeping object (TRY NOT TO USE!!!), set it so
	if ([self flagState:SF_OBJECT_NOSLEEPING]){ 
        _physicsInfo->_btRigidBody->setActivationState(DISABLE_DEACTIVATION);
    }
    
    //if this is a ghost, disable collisions
	if ([self flagState:SF_OBJECT_GHOST]){
		_physicsInfo->_btRigidBody->setCollisionFlags(_physicsInfo->_btRigidBody->getCollisionFlags() |
                                                                        btCollisionObject::CF_NO_CONTACT_RESPONSE);
	}
	
	//set the object's friction based on the max values found on all materials
	[self setupMaterialPhysics];
    
    //set the user pointer to point back to the SIO2object (for now)
	_physicsInfo->_btRigidBody->setUserPointer(self);
    _physicsSetup = YES;
}

-(void)pushTransform:(SFTransform*)transform{
    //save a transform to the transform stack so we can later "pop" and return to it
    SFTransform *aTransform = transform->copy();
    [_transformStack addObject:[NSValue valueWithPointer:aTransform]];
}

-(void)pushTransform{
    //save our CURRENT transform to the stack so we can later revert
    [self pushTransform:_transform];
}

-(SFTransform*)topStackTransform{
    //return the last transform we pushed on to the transform stack
    return (SFTransform*)[[_transformStack lastObject] pointerValue];
}

-(id)popTransform:(BOOL)apply{
//    //restore our last transform from the transform stack
//    id popped = [[self topStackTransform] retain];
//    [_transformStack removeLastObject];
//    if (apply) {
//        _transform->setFromTransform([popped pointerValue])
//        _poppedTransform = YES;
//    }
//    return popped;
    return nil;//tmp
}

-(BOOL)undoLastMoveToTransform:(float)seconds callbackObject:(id)callbackObject callbackSelector:(SEL)callbackSelector{
    //find out where we moved from and move back there...
//    if ([self dynamicIpoPlaying]) {
//        return NO;
//    }
//    
//    id destination = [self popTransform:NO];
//    
//    if (!destination) {
//        return NO;
//    }
//    
//    [self cleanUpDynamicIpo];
//    _dynamicIpo = [[SFDynamicIPO alloc] initIpo:@"mover"
//                                           from:[self getTransformWithDictionary:nil]
//                                             to:destination
//                                           time:seconds
//                                 callbackObject:callbackObject
//                               callbackSelector:callbackSelector];
//    
//    sfDebug(TRUE, "Moving %s from %s back to %s", [self UTF8Description], [[[self getTransformWithDictionary:nil] description] UTF8String], [[destination description] UTF8String]);
//    
//    //play this dynamic ipo
//    [_dynamicIpo play];
//    [destination release];
//    return YES;
    return NO;//tmp
}

-(void)moveToTransform:(SFTransform *)destination seconds:(float)seconds callbackObject:(id)callbackObject callbackSelector:(SEL)callbackSelector{
    //creates and plays a dynamic IPO to move to the location requested in the time given
    //and calls the callback object and selector when done
//    
//    //playing while another is playing does nothing
//    if ([self dynamicIpoPlaying]) {
//        return;
//    }
//    
//    //if ([self cleanUpDynamicIpo]) {
////        [self popTransform:YES];
////    }
//    
//     //save our original transform so we can revert
//    [self pushTransform]; 
//    
//    [self cleanUpDynamicIpo];
//    _dynamicIpo = [[SFDynamicIPO alloc] initIpo:@"mover"
//                                             from:[self getTransformWithDictionary:nil]
//                                               to:destination
//                                             time:seconds
//                                   callbackObject:callbackObject
//                                 callbackSelector:callbackSelector];
//    
//    sfDebug(TRUE, "Moving %s from %s to %s", [self UTF8Description], [[[self getTransformWithDictionary:nil] description] UTF8String], [[destination description] UTF8String]);
//    
//    //play this dynamic ipo
//    [_dynamicIpo play];
    
}

-(id)proxyTarget{
    //if we have a proxy object - that is, we are a colmesh for an object, return it here
    id targetName = [self getBlenderInfo:@"colMeshFor"];
    if (targetName) {
        //return [[self sm] getI:targetName];
        sfDebug(TRUE,"finish me!!!");
        return nil;
    }
    return nil;
}

-(SFVertexGroup*)vertexGroupByName:(NSString*)name{
    return [_vertexGroups objectForKey:name];
}

-(void)setPhysicsInfo:(SFObjectPhysicStruct*)physicsInfo{
    _physicsInfo->bounds     = physicsInfo->bounds;
	_physicsInfo->mass       = physicsInfo->mass;
	_physicsInfo->damp       = physicsInfo->damp;
	_physicsInfo->rotdamp    = physicsInfo->rotdamp;
	_physicsInfo->margin     = physicsInfo->margin;
	_physicsInfo->linstiff   = physicsInfo->linstiff;
	_physicsInfo->shapematch = physicsInfo->shapematch;
	_physicsInfo->citeration = physicsInfo->citeration;
	_physicsInfo->piteration = physicsInfo->piteration;
}

-(void)copySoft:(SF3DObject*)aCopy{
    //doesn't make a physical copy of
    //opengl-buffered vertices
    //this is ideal for duplicate objects
    //that do not require vertex animation (action)
    
    [aCopy setRadius:_radius];
    [aCopy resetFlagState:[self flagMask]];
    if ([self objectIsPhysical]) {
        [aCopy setPhysicsInfo:_physicsInfo];
    }
    [aCopy setDimensions:_dim];
    [aCopy setIpo:_ipo];
    
    if ([self hasConstraints]) {
        [[aCopy constraintDefs] addObjectsFromArray:[self constraintDefs]];
    }
    
    [aCopy setTransform:_transform];
    //bind matrix probably unnec
    [aCopy transform]->compileMatrix();
}

-(void)copyVertexGroupsFrom:(id)vertexGroups hardCopy:(BOOL)hardCopy{
    
    //given a dictionary of vertex groups, 
    //copy it - no sweat - the real work is done
    //in the vertex group object copy routine
    if (hardCopy) {
        //hard copy copies verts, buffer objects, everything...
        _vertexGroups = [[NSMutableDictionary alloc] initWithDictionary:vertexGroups copyItems:YES];
    } else {
        //soft copy just needed for the materials
        _vertexGroups = [[NSMutableDictionary alloc] initWithCapacity:[vertexGroups count]];
        for (NSString* vertexGroupName in vertexGroups) {
            id newVertexGroup = [[SFVertexGroup alloc] initWithDictionary:nil];
            [newVertexGroup setMaterial:[[vertexGroups objectForKey:vertexGroupName] material]];
            [_vertexGroups setObject:newVertexGroup forKey:vertexGroupName];
            [newVertexGroup release];
        }
    }
}

-(void)setBuffer:(unsigned char*)buffer{
    memcpy(_buf, buffer, _vbo_offset[SF_OBJECT_SIZE]);
}

-(void)duplicateVertexBuffer:(SF3DObject*)aCopy{
    [SFUtils assertGlContext];
#if SF_USE_GL_VBOS
    _buf = (unsigned char *)SFGL::instance()->mapBuffer(_vbo, GL_ARRAY_BUFFER);
    {
#endif
        [aCopy setBuffer:_buf];
#if SF_USE_GL_VBOS
    }
    SFGL::instance()->unMapBuffer(_vbo, GL_ARRAY_BUFFER);
    _buf = nil;
#endif
}

-(void)setVBOOffset:(unsigned int **)vboOffset{
    memcpy(&_vbo_offset, vboOffset, sizeof(_vbo_offset));
    //also alloc the buffer because we know the size here
    _buf = (unsigned char *)malloc(_vbo_offset[SF_OBJECT_SIZE]);
}

-(void)copyHard:(SF3DObject*)aCopy{
    //makes an entirely new object including 
    //opengl-buffered vertex data
    //required for objects that use actions
    
    //soft copy first
    [self copySoft:aCopy];
    [aCopy setVBOOffset:(unsigned int**)&_vbo_offset]; 
    [self duplicateVertexBuffer:aCopy];
}

-(void)setRadius:(float)radius{
    _radius = radius;
}

-(void)setIpo:(SFIpo*)ipo{
    //set a "next" ipo so that the next render will pick it up
    if (_nextIpo) {
        return;
    }
    _nextIpo = [ipo retain];
}

-(SFIpo*)ipo{
    return _ipo;
}

+(NSString*)fileDirectory{
    return @"object";
}

-(void)setTransform:(SFTransform*)transform{
    _transform->setFromTransform(transform);
}
-(void)setDimensions:(SFVec*)dim{
    _dim->setVector(dim);
}

-(void)enableCollisions:(BOOL)enable{
    
    if ([self getRigidBody]) {
        if (enable) {
            [self setCollisionFlags:[self getRigidBody]->getCollisionFlags() | btCollisionObject::CF_CUSTOM_MATERIAL_CALLBACK];
        } else {
            [self setCollisionFlags:[self getRigidBody]->getCollisionFlags() & ~btCollisionObject::CF_CUSTOM_MATERIAL_CALLBACK];
        }
    }
    
}

-(void)forceCollisionCallback:(BOOL)activated{
	[self enableCollisions:activated];
}

-(SFTransform*)transform{
    return _transform;
}

-(void)synchronisePhysicsTransform{
    if (![self objectIsPhysical]) {
        return;
    }
    //syncronize our physics position
    btTransform updateLocation = [self getTransformForPhysics];
    //part 1 - the rigid body centre of mass
    [self getRigidBody]->setCenterOfMassTransform(updateLocation);
    //part 2 - the default motion state world transform
    //_physicsInfo->_motionState->setWorldTransform(updateLocation);
}

-(void)setFirstSpawnTransform:(SFTransform*)transform{
    //there are two entities to keep in sync - our graphical
    //and our physical body (and two in that)
 
    //update our graphical position
    _transform->setFromTransform(transform);

    //now synch the phys
    [self synchronisePhysicsTransform];
}

-(BOOL)isWorld{
    return _isWorld;
}

-(SFObjectWorldState)worldState{
    return _worldState;
}

-(void)forceImmediateExistance{
    //skips adding/removing from physical
    //world and forces this object to be 
    //drawn
    _worldState = wsExists;
}

-(BOOL)continueToRender{
    if (_worldState != wsExists) {
        return NO;
    }
	if (_removeAfterRenderCount < 0) {
		return YES;
	}
	if (_removeAfterRenderCount == 0) {
        //flag the transition but don't
        //remove it from render YET
        
        if (_worldState == wsExists) {
            _worldState = wsWantsRemoval;
        }

	}
    --_removeAfterRenderCount;
    return YES;
}

-(void)updateDistanceFromCamera:(SFCamera*)camera{
    _dst = [camera sphereDistInFrustum:_transform->loc() radius:_radius];
}

-(void)setupCollisionCallback{
	if ([[self class] enableCollisionCallback]) {
		[self enableCollisions:YES];
	}
}

-(void)saveOriginalTransform{
    //keep a copy of the original transform of this object so we can reset when we want
    if (_originalTransform) {
        delete _originalTransform;
    }
    _originalTransform = _transform->copy();
}

-(void)genId{
#if SF_USE_GL_VBOS
    if (_vbo_offset[ SF_OBJECT_SIZE ]) {
        
        int btype = [self flagState:SF_OBJECT_DYNAMIC_DRAW] ? GL_DYNAMIC_DRAW : GL_STATIC_DRAW;

        glGenBuffers(1, &_vbo);
        SFGL::instance()->glBindBuffer(GL_ARRAY_BUFFER, _vbo);
        SFGL::instance()->glBufferData(GL_ARRAY_BUFFER, _vbo_offset[SF_OBJECT_SIZE], &_buf[0], btype);

        NSEnumerator *vertexGroups = [_vertexGroups objectEnumerator];
        for (SFVertexGroup *vertexGroup in vertexGroups) {
            [vertexGroup genId];
        }

        free(_buf );
        _buf = NULL;

    }
#endif
}

-(BOOL)hasConstraints{
    return (_constraintDefs != nil);
}

-(id)constraintDefs{
    //the object's constraint definitions (from blender)
    if (!_constraintDefs) {
        _constraintDefs = [[NSMutableArray alloc] init];
    }
    return _constraintDefs;
}

-(id)getConstraintTargets{
    return [self objectInfoForKey:@"constraintTargets" useMasterInfo:NO createOk:YES];
}

-(btRigidBody*)getConstraintTargetBody:(id)constraintKey{
    return [[[self getConstraintTargets] objectForKey:constraintKey] getRigidBody];
}

-(void)setupConstraintsToObject:(id)object{
	//for each constraint that we have,
	//check if we want (by target name)
	//to set up the constraint to this object
	//if so, do it
    if (![self hasConstraints]) {
        return;
    }
	id constraintDictionary = [self constraintDefs];
	id constraints = [constraintDictionary objectEnumerator];
	for (id constraintPointer in constraints) {
        SFConstraint *constraint = (SFConstraint*)[constraintPointer pointerValue];
		char *targetString = (char*)[[object getBaseName] UTF8String];
		if (constraint->targetNameIs(targetString)) {
			//we want to set up a constraint for it later on
			[[self getConstraintTargets] setObject:object forKey:constraintPointer];
		}
	}
}

-(id)unlockableObjectId{
    return [self getBlenderInfo:@"uniqueId"];
}

-(int)getNumVerts{
    if(_vbo_offset[ SF_OBJECT_NORMALS ] )
	{ return _vbo_offset[ SF_OBJECT_NORMALS ] / 12; }
    
	else if( _vbo_offset[ SF_OBJECT_VCOLOR ] )
	{ return _vbo_offset[ SF_OBJECT_VCOLOR ] / 12; } 	
    
	else if( _vbo_offset[ SF_OBJECT_TEXUV0 ] )
	{ return _vbo_offset[ SF_OBJECT_TEXUV0 ] / 12; }
    
	else if( _vbo_offset[ SF_OBJECT_TEXUV1 ] )
	{ return _vbo_offset[ SF_OBJECT_TEXUV1 ] / 12; }
    
	return _vbo_offset[ SF_OBJECT_SIZE ] / 12;
}

-(void)updateTimeRatio{
    _SIO2objectanimation->d_time = 0.0f;
    _SIO2objectanimation->t_ratio = (float)((_SIO2objectanimation->_SIO2frame2->frame * 
                                            (1.0f / _SIO2objectanimation->fps )) - 
                                            (_SIO2objectanimation->_SIO2frame1->frame * 
                                            (1.0f / _SIO2objectanimation->fps )));
}

-(BOOL)setAction:(SFAction*)action _interp:(float)_interp _fps:(float)_fps startFrame:(int)startFrame{
	unsigned int s_frame = [self getNumVerts] * 12;
    
	if( s_frame == [action frameSize] || ( s_frame << 1 ) == [action frameSize] )
	{
		_SIO2objectanimation->_action = action;
        
		_SIO2objectanimation->curr_frame = startFrame;
		_SIO2objectanimation->next_frame = startFrame + 1;
		
		_SIO2objectanimation->_SIO2frame1 = [_SIO2objectanimation->_action frames][_SIO2objectanimation->curr_frame ];
		_SIO2objectanimation->_SIO2frame2 = [_SIO2objectanimation->_action frames][_SIO2objectanimation->next_frame ];	
		
		_SIO2objectanimation->interp = _interp;
		_SIO2objectanimation->fps    = _fps;
		
		[self updateTimeRatio];
		
		return YES;
	}
	
	return NO;
}

-(void)play:(BOOL)loopAction{
    _actionPlaying = YES;
    _SIO2objectanimation->loop  = loopAction;
}

-(void)playAction:(NSString*)actionName loopAction:(BOOL)loopAction randomStart:(BOOL)randomStart{
	//plays an action on this object
	
	if (!actionName) {
		//null action name - do nothing
		return;
	}
	
	SFAction *action = [[self rm] getItem:actionName itemClass:[SFAction class]];
	if (!action) {
		sfDebug(DEBUG_SF3DOBJECT, "Action %s not loaded, aborting play", [actionName UTF8String]);
		return;
	}
	
	//we have the action - play it

	if (_SIO2objectanimation->_action == action) {
		//we already have it assigned to us as an action
		//so if we are already in play mode, there's nothing
		//to do here
		if (_actionPlaying) {
			return;
		}

	} else {
		//set the action for our object
        int startFrame = 0;
        if (randomStart) {
            startFrame = [SFUtils getRandomPositiveInt:[action numFrames] - 1];
        }
        [self setAction:action _interp:0.5f _fps:[_scene frameRate] startFrame:startFrame];
	}
    
	//now just start it playing
	[self play:loopAction];
}

-(void)stopAnimation{
	
    if (!_SIO2objectanimation or !_actionPlaying) {
        return;
    }
    
    //stops the object animation
	_actionPlaying = NO;
    
	_SIO2objectanimation->curr_frame = 0;
	_SIO2objectanimation->next_frame = 1;
    
	_SIO2objectanimation->_SIO2frame1 = [_SIO2objectanimation->_action frames][_SIO2objectanimation->curr_frame];
	_SIO2objectanimation->_SIO2frame2 = [_SIO2objectanimation->_action frames][_SIO2objectanimation->next_frame];	
    
	_SIO2objectanimation->d_time = 0.0f;
    _actionState = OBJECT_IDLE;
}

-(void)pauseAnimation:(BOOL)paused{
	if (paused){
		_actionPlaying = NO;
	} else {
		_actionPlaying = YES;
	}
}

-(NSString*)getBlenderInfo:(id)infoKey{
	NSDictionary *blenderInfo = [self objectInfoForKey:@"blenderInfo"];
	if (blenderInfo) {
		return [blenderInfo objectForKey:infoKey];
	} else {
		return nil;
	}
}

-(void)setBlenderInfo:(id)value infoKey:(id)infoKey{
	id blenderInfo = [self objectInfoForKey:@"blenderInfo" useMasterInfo:NO];
	if (!blenderInfo) {
		blenderInfo = [[NSMutableDictionary alloc] init];
		[self setObjectInfo:blenderInfo forKey:@"blenderInfo"];
        [blenderInfo release];
	}
	[blenderInfo setObject:value forKey:infoKey];
}

-(int)getBlenderInt:(id)infoKey{
	//convenience
	id blenderValue = [self getBlenderInfo:infoKey];
	if (blenderValue){
		return [blenderValue integerValue];
	} else {
		return -1;
	}

}

-(float)getBlenderFloat:(id)infoKey{
	//convenience
	id blenderValue = [self getBlenderInfo:infoKey];
	if (blenderValue){
		return [blenderValue floatValue];
	} else {
		return 0.0f;
	}
	
}

-(BOOL)getBlenderBool:(id)infoKey{
	//convenience
	id blenderValue = [self getBlenderInfo:infoKey];
	if (blenderValue){
		return [blenderValue boolValue];
	} else {
		return NO;
	}
	
}

-(void)simulatePhysicsHit:(SF3DObject*)inflictor{
    //for use when we don't actually have a collision to create the hit for us
}

-(BOOL)isLive{
	return _isLive;
}

-(id)initCopyWithDictionary:(NSDictionary *)dictionary{
    self = [super initCopyWithDictionary:dictionary];
    if (self != nil) {
        _worldState = wsDoesNotExist;
        _colour = new SFColour(COLOUR_SOLID_WHITE);
        _dim = new SFVec(3);
        _visible = YES;
        _removeAfterRenderCount = -1;
        _currentHealth = DEFAULT_OBJECT_HEALTH;
        _transformStack = [[NSMutableArray alloc] init];
        _transform = new SFTransform();
        _dst = 1.0f;
    }
    return self;
}

-(id)initWithTokens:(SFTokens *)tokens dictionary:(NSDictionary *)dictionary{
	self = [super initWithTokens:tokens dictionary:dictionary];
	if (self != nil) {
        [self setup3dObject];
    }
	return self;    
}

-(void)setup3dObject{
    _isWorld = [self getBlenderBool:@"isWorld"];
    [self saveOriginalTransform];
    [self setupPhysicsObject];
    [self genId];
    [self checkVisibility];
    [self setupCollisionCallback];
    //and if we are unlockable we start life hidden
    //if (_objectIsUnlockable) {
    //    [self hide];
    //}
    _isLive = YES;
#if DEBUG_DRAW_OBJECT
    [self notifyMe:SF_NOTIFY_DRAW_DEBUG_NOW selector:@selector(debugDrawObject:)];
#endif
}

-(void)checkVisibility{
#if ALL_OBJECTS_VISIBLE == 0
    id blenderVisible = [self getBlenderInfo:@"visible"];
    if (blenderVisible and ![blenderVisible boolValue]) {
		sfDebug(DEBUG_SF3DOBJECT, "Object wants to be invisible...");
        [self hide];
	}
#endif
}

+(NSArray*)getCollisionInterestClasses{
	return nil;
}

+(NSArray*)getContactInterestClasses{
	return nil;
}

-(BOOL)getOnGround{
	return _onGround;
}

-(void)setOnGround{
	_onGround = true;
}

-(int)getBlenderTag{
	return [self getBlenderInt:@"tag"];
}

-(BOOL)getZoomedIn{
	return _zoomedIn;
}

-(id)getActions{
	//autocreate our actions group
	id actions = [self objectInfoForKey:@"actions"];
	if (!actions) {
		actions = [[NSMutableDictionary alloc] init];
		[self setObjectInfo:actions forKey:@"actions"];
	}
	return actions;
}

-(void)setAttackSoundObject:(SFSound*)sound{
    [_sndAttack release];
    _sndAttack = [sound retain];
}

-(void)postCopySetup:(id)aCopy{
    [super postCopySetup:aCopy];
    if (!_requiresActionAnimation) {
        [self copySoft:aCopy];
        [aCopy setSoftOriginal:self];
    } else {
        [self copyHard:aCopy];
    }
    [aCopy setAttackSoundObject:_sndAttack];
    [aCopy copyVertexGroupsFrom:_vertexGroups hardCopy:_requiresActionAnimation];
    [aCopy setup3dObject];
}

-(BOOL)objectIsGraphical{
    return YES;
}

-(void)objectBecameLeased{
    sfDebug(DEBUG_SF3DOBJECT, "LEASED: %s", [[self description] UTF8String]);
    [self wakePhysics];
    _isLive = YES;
}

-(void)resetToOriginalTransform{
    if (_originalTransform != nil) {
        if (!_physicsSetup) {
            _transform->setFromTransform(_originalTransform);
        } else {
            [self setFirstSpawnTransform:_originalTransform];
        }
    }
}

-(void)objectBecameUnleased{
    //at this stage it is DEFINITELY NOT BEING RENDERED
    //so we can use a custom GL context to quickly get any gl stuff
    //we need done
    if (![EAGLContext currentContext]) {
        [EAGLContext setCurrentContext:[SFGLManager quickSharedContext]];
    }
    sfDebug(DEBUG_SF3DOBJECT, "UNLEASED: %s", [[self description] UTF8String]);
    [self sleepPhysics];
    _isLive = NO;
    [self resetToOriginalTransform];
}

-(id)playFXSound:(NSString*)soundName{
	//plays sound local to this object
	return [SFSound quickPlaySFX:soundName position:_transform->loc()];
}

-(id)playBlenderSound:(NSString*)soundTag{
    NSString *soundName = [[self getBlenderInfo:soundTag] retain];
    if (!soundName) {
        sfDebug(TRUE, "No sound to play!");
        return nil;
    }
	id playingSound = [self playFXSound:soundName];
    [soundName release];
    return playingSound;
}

-(id)playGetSound{
    return [self playBlenderSound:@"getSound"];
}

-(id)playPutSound{
	return [self playBlenderSound:@"putSound"];
}

-(void)wasHitBy:(SF3DObject*)attacker{
    //we have been hit by something - that is, we are the victim
    //we should only change things on ourself
    if ([[self class] takesDamageFrom:[attacker class]]) {
        [self takeDamageFrom:attacker];
    }
}

-(void)didHit:(SF3DObject*)victim{
	//we have hit somethign - that is, we are the attacker
    //we should only change things on ourself
}

-(void)hide{
    //[self setFlagState:SF_OBJECT_INVISIBLE value:YES];
    _visible = NO;
}

-(void)show{
    //[self setFlagState:SF_OBJECT_INVISIBLE value:NO];
    _visible = YES;
}

-(NSString*)getActionName:(NSString*)actionType{
    return [[[self class] actionDictionary] objectForKey:actionType];
}

+(BOOL)takesDamageFrom:(Class)attackerClass{
    return NO;
}

-(float)getCalculatedDamageAmount{
    return _baseDamageAmount;
}

-(float)damageAmount{
    if (_isLive) {
        return [self getCalculatedDamageAmount];
    }
    return 0.0f;
}

-(SF3DObject*)nextDuplicate{
    return _nextDuplicate;
}

-(SFVec*)dimensions{
    return _dim;
}

-(void)cleanUpSIO2Object{
    [_nextDuplicate release];
    delete _transform;
    delete _dim;
    delete _colour;
    [_vertexGroups removeAllObjects];
	[_vertexGroups release];
    [_transformStack removeAllObjects];
    [_transformStack release];
    if (![EAGLContext currentContext]) {
        [EAGLContext setCurrentContext:[SFGameEngine glContext]];
    }
    
#if SF_USE_GL_VBOS
    SFGL::instance()->glDeleteBuffers(1, &_vbo);
#endif
    
	if(_physicsInfo )
	{
		if(_physicsInfo->_btTriangleMesh )
		{
			delete _physicsInfo->_btTriangleMesh;
			_physicsInfo->_btTriangleMesh = NULL;
		}
		
		free(_physicsInfo );
		_physicsInfo = NULL;
	}
	
	
	if (_SIO2objectanimation )
	{
		free(_SIO2objectanimation );
		_SIO2objectanimation = NULL;
	}
	
	
	if( _buf )
	{
		free( _buf );
		_buf = NULL;
	}
}

-(void)prepareObject{
    [super prepareObject];
    //reset direction and scale
    _transform->setDefaults();
}

-(void)resetObject{
    [super resetObject];
    //reset any turns being made
    _turnDelta = 0;
    _turnsDeltasRemaining = 0;
    //reset the physics state...
    if (!_physicsSetup) {
        return;
    }
    _physicsInfo->_btRigidBody->setLinearVelocity(btVector3(0.0f, 0.0f, 0.0f));
    _physicsInfo->_btRigidBody->setAngularVelocity(btVector3(0.0f, 0.0f, 0.0f));
    [self stopAnimation];
}

-(void)precacheSounds:(NSMutableArray *)sounds{
    [super precacheSounds:sounds];
    //if we have get or put sounds we need to precache them
    NSString *sound = [self getBlenderInfo:@"getSound"];
    if (sound) {
        [sounds addObject:sound];
    }
    sound = [self getBlenderInfo:@"putSound"];
    if (sound) {
        [sounds addObject:sound];
    }
    if (_attackSoundName) {
        [sounds addObject:_attackSoundName];
    }
}

-(void)soundPrecachingComplete{
    [super soundPrecachingComplete];
    if (_attackSoundName) {
        _sndAttack = [[SFSound quickPlayFetch:_attackSoundName] retain];
    }
}

-(void)processWorldState:(SFPhysicsWorld*)physicsWorld{
    //the scene has given us the physics world and 
    //said we can add or remove ourselves etc if we want
    switch (_worldState) {
        case wsWantsInsertion:
            //if the object wants to be added to the world then we add it
            sfDebug(DEBUG_SF3DOBJECT, "Inserting %s into world...\n", [self UTF8Description]);
            [self prepareObject];
            [self addObjectToWorld:physicsWorld];
            break;
        case wsWantsRemoval:
            //if the object wants to be removed from the world then we remove it
            [self removeObjectFromWorld:physicsWorld];
            [self resetObject];
            break;
        default:
            //otherwise it is fine as it is, either existing or not existing
            //in the world
            break;
    }
    if (_nextDuplicate) {
        [_nextDuplicate processWorldState:physicsWorld];
    }
}

-(void)reserve{
    //allows reservation of objects in the object pool
    if (_worldState == wsDoesNotExist) {
        _worldState = wsReserved;
    }
}

-(void)unReserve{
    //allows reservation of objects in the object pool
    if (_worldState == wsReserved) {
        _worldState = wsDoesNotExist;
    }
}

-(void)insertIntoWorld{
    //sets our flags ready for the next process statement
    if (_worldState != wsExists) {
        _worldState = wsWantsInsertion;
    }
}

-(void)setBodyLinearVelocity:(btVector3)velocity{
    [self getRigidBody]->setLinearVelocity(velocity);
}

-(void)activateTrigger:(id)activatedBy{
    //if this object is a trigger then we do whatever this
    //kind of trigger does when it is activated
    //by the object given
    //sfDebug(TRUE, "Trigger %s activated by %s", [self UTF8Name], [activatedBy UTF8Name]);
    //at the moment we just apply the physics impulse given
    [activatedBy setBodyLinearVelocity:_triggerImpulse->getBtVector3()];
}

-(void)removeFromWorld{
    if (_worldState == wsExists) {
        _worldState = wsWantsRemoval;
    }
}

-(void)addObjectToWorld:(SFPhysicsWorld*)physicsWorld{
    _worldState = wsExists;
    if (!_physicsSetup){
        return;
    }
    physicsWorld->addObject(_physicsInfo->_btRigidBody);
    [self setupCollisionCallback];
}

-(void)removeObjectFromWorld:(SFPhysicsWorld*)physicsWorld{
    _worldState = wsDoesNotExist;
    if (!_physicsSetup){
        return;
    }
    if (physicsWorld) {
        physicsWorld->removeObject(_physicsInfo->_btRigidBody);
    }
}

-(void)cleanUp{
    if (_originalTransform) {
        delete _originalTransform;
        _originalTransform = NULL;
    }
    [self tearDownPhysicsObject];
    [self cleanUpSIO2Object];
    [_softOriginal release];
    _softOriginal = nil;
    [_ipo release];
    [_sndAttack release];
    [super cleanUp];
}

-(void)setCollisionFlags:(unsigned int)collisionFlags{
    if ([self getRigidBody]){
        [self getRigidBody]->setCollisionFlags(collisionFlags);
    }
}

-(void)stopAllCollisions{
	//stop colliding
    [self enableCollisions:NO];
}

-(void)removeAfter:(float)removeDelay{
	_removeAfterRenderCount = [[[self sm] currentScene] timeToRenderPasses:removeDelay];
}

-(void)hitWorld:(id)worldObject{
	[self setOnGround];
}

+(BOOL)enableCollisionCallback{
	return false;
}

+(id)getCollisionClass{
	//the class that is broadcast as having been spawned
	//you may want to override this in the subclass so
	//that you can appeal to a general object audience
	return [self class];
}

-(int)getDuplicationId{
	return 0; //not working...
}

-(float)getCameraDistance{
    return _dst;
}

-(NSComparisonResult)compareByDistance:(id)sortItem2{
	
	if ([self getCameraDistance] > [sortItem2 getCameraDistance]) {
		return NSOrderedDescending;
	} else {
		return NSOrderedAscending;
	}
}

-(btRigidBody*)getRigidBody{
    if (!_physicsInfo) {
        return nil;
    }
	return (btRigidBody*)_physicsInfo->_btRigidBody;
}

-(void)wakePhysics{
    if ([self getRigidBody]) {
        [self getRigidBody]->activate(NO);
    }
}

-(void)sleepPhysics{
    if ([self getRigidBody]){
        [self getRigidBody]->setActivationState(WANTS_DEACTIVATION);
    }
}

-(id)getResourceName{
    return [[self objectInfoForKey:@"resourceInfo"] objectForKey:@"filename"];
}

-(void)bindVBO:(BOOL)useMaterial{
    
#if SF_USE_GL_VBOS
	if( !_vbo )
	{ return; }

    SFGL::instance()->glBindBuffer(GL_ARRAY_BUFFER, _vbo);
#endif
    //SFGL::instance()->glVertexPointer(3, GL_FLOAT, 0, (void *)NULL);
    SFGL::instance()->glVertexPointer(3, GL_FLOAT, 0, SF_BUFFER_OFFSET(0, _buf));
    
	if (useMaterial){
        
        if (SFGL::instance()->cachedState(GL_LIGHTING) and (_vbo_offset[SF_OBJECT_NORMALS])) {
            SFGL::instance()->glEnableClientState(GL_NORMAL_ARRAY);
            glNormalPointer( GL_FLOAT,
                            0,
                            SF_BUFFER_OFFSET(_vbo_offset[SF_OBJECT_NORMALS], _buf));
        } else {
            SFGL::instance()->glDisableClientState(GL_NORMAL_ARRAY);
        }
		
        if (_vbo_offset[ SF_OBJECT_VCOLOR ]){
			SFGL::instance()->glEnableClientState(GL_COLOR_ARRAY);
			glColorPointer( 4,
                           GL_UNSIGNED_BYTE,
                           0,
                           (void *)SF_BUFFER_OFFSET(_vbo_offset[SF_OBJECT_VCOLOR], _buf));
		} else { 
            SFGL::instance()->glDisableClientState(GL_COLOR_ARRAY); 
        }
        
		if (_vbo_offset[ SF_OBJECT_TEXUV0 ]){
            SFGL::instance()->glClientActiveTexture(GL_TEXTURE0);
			SFGL::instance()->glEnableClientState(GL_TEXTURE_COORD_ARRAY);
			SFGL::instance()->glTexCoordPointer(2, GL_FLOAT, 0, 
                                                SF_BUFFER_OFFSET(_vbo_offset[SF_OBJECT_TEXUV0], _buf));	
		} else {
            SFGL::instance()->glClientActiveTexture(GL_TEXTURE0);
            SFGL::instance()->glDisableClientState(GL_TEXTURE_COORD_ARRAY);
        }
		
        if (_vbo_offset[ SF_OBJECT_TEXUV1 ]){
            SFGL::instance()->glClientActiveTexture(GL_TEXTURE1);
			SFGL::instance()->glEnableClientState(GL_TEXTURE_COORD_ARRAY);
			SFGL::instance()->glTexCoordPointer(2, GL_FLOAT, 0, 
                                                SF_BUFFER_OFFSET(_vbo_offset[SF_OBJECT_TEXUV1], _buf));	
		} else {
            SFGL::instance()->glClientActiveTexture(GL_TEXTURE1);
            SFGL::instance()->glDisableClientState(GL_TEXTURE_COORD_ARRAY);
        }
	} else {
        SFGL::instance()->materialReset();
    }

}

-(void)renderAction{
    
    if( !_SIO2objectanimation || !_SIO2objectanimation->_action ){
        return;
    }
    
    if(_actionPlaying)
    {
        _SIO2objectanimation->d_time += [[SFGameEngine mainViewController] deltaTime];
        
        if(_dst){
#if SF_USE_GL_VBOS
            _buf = (unsigned char*)SFGL::instance()->mapBuffer(_vbo, GL_ARRAY_BUFFER);
            {
#endif
                unsigned int r_vert = [self getNumVerts];
                unsigned int n_vert = r_vert * 3;
                
                float *curr_buf = (float *)_SIO2objectanimation->_SIO2frame1->buf;
                float *next_buf = (float *)_SIO2objectanimation->_SIO2frame2->buf;
                float *main_buf = (float *)_buf;
                float ratio = SF_CLAMP(_SIO2objectanimation->d_time / _SIO2objectanimation->t_ratio, 0.0f, 1.0f );
                float inv_ratio = 1.0f - ratio;
                
                for (int i = 0; i < n_vert; ++i) {
                    main_buf[ i ] = curr_buf[ i ] * inv_ratio + next_buf[ i ] * ratio;
                }
                
                
                if( ( n_vert << 3 ) == [_SIO2objectanimation->_action frameSize] )
                {
                    curr_buf = ( float * )&_SIO2objectanimation->_SIO2frame1->buf[ r_vert * 12 ];				
                    next_buf = ( float * )&_SIO2objectanimation->_SIO2frame2->buf[ r_vert * 12 ];
                    main_buf = ( float * )&_buf[_vbo_offset[ SF_OBJECT_NORMALS ]];
                    
                    for (int i = 0; i < n_vert; ++i) {
                        main_buf[ i ] = curr_buf[ i ] * inv_ratio + next_buf[ i ] * ratio;
                    }
                }
#if SF_USE_GL_VBOS
                SFGL::instance()->unMapBuffer(_vbo, GL_ARRAY_BUFFER);
            }
            _buf = NULL;
#endif
        }
        
        
        if(_SIO2objectanimation->d_time > _SIO2objectanimation->t_ratio )
        {
            ++_SIO2objectanimation->curr_frame;
            ++_SIO2objectanimation->next_frame;
            
            
            if (_SIO2objectanimation->next_action)
            {
                _SIO2objectanimation->curr_frame = [_SIO2objectanimation->_action numFrames];
                _SIO2objectanimation->next_action = 0;
            }
            
            
            if( _SIO2objectanimation->next_frame == [_SIO2objectanimation->_action numFrames] )
            {
                if( _SIO2objectanimation->loop )
                {
                    _SIO2objectanimation->next_frame  = 0;
                    _SIO2objectanimation->_SIO2frame1 = [_SIO2objectanimation->_action frames][ _SIO2objectanimation->curr_frame ];	
                    _SIO2objectanimation->_SIO2frame2 = [_SIO2objectanimation->_action frames][ _SIO2objectanimation->next_frame ];	
                    
                    _SIO2objectanimation->d_time  = 0.0f;
                    _SIO2objectanimation->t_ratio = _SIO2objectanimation->interp;
                }
                else
                {
                    [self stopAnimation];
                    return;
                }
            }
            else if( _SIO2objectanimation->curr_frame == [_SIO2objectanimation->_action numFrames] )
            {
                _SIO2objectanimation->curr_frame  = ( _SIO2objectanimation->next_frame - 1 );
                
                _SIO2objectanimation->_SIO2frame1 = [_SIO2objectanimation->_action frames][ _SIO2objectanimation->curr_frame ];
                _SIO2objectanimation->_SIO2frame2 = [_SIO2objectanimation->_action frames][ _SIO2objectanimation->next_frame ];
            }
            else
            {
                _SIO2objectanimation->_SIO2frame1 = [_SIO2objectanimation->_action frames][ _SIO2objectanimation->curr_frame ];
                _SIO2objectanimation->_SIO2frame2 = [_SIO2objectanimation->_action frames][ _SIO2objectanimation->next_frame ];			
            }
            
            [self updateTimeRatio];			
        }
    }
}

-(void)setSoftOriginal:(id)softOriginal{
    _softOriginal = [softOriginal retain];
}

-(void)replicate:(int)count masterObject:(SF3DObject*)masterObject{
    //a linked list of duplicates
    
    if (!count) {
        return;
    }
    
    if (!_nextDuplicate) {
        _nextDuplicate = [masterObject copy];
        --count;
    }
    [_nextDuplicate replicate:count masterObject:masterObject];    
}

-(void)replicate:(int)count{
    [self replicate:count masterObject:self];
}

-(void)pruneDuplicates{
    if (_nextDuplicate) {
        [_nextDuplicate pruneDuplicates];
        [_nextDuplicate cleanUp];
        [_nextDuplicate release];
        _nextDuplicate = nil;
    }
}

-(BOOL)render:(unsigned int)renderPass matrixTransform:(unsigned char)matrixTransform useMaterial:(BOOL)useMaterial{
    
    //render any duplicates first
    if (_nextDuplicate) {
        [_nextDuplicate render:renderPass matrixTransform:matrixTransform useMaterial:useMaterial];
    }
    
    if (![self continueToRender]) {
        return NO;
    }
    
    if (!(_visible && _dst != 0)){ 
        return NO;
    }
    if (renderPass == SF_RENDER_PASS_OPAQUE) {
        //this is the first render pass of three - only on this one do we run a pre-render
        //before we actually draw anything we might need to move the object around a bit - this only gets called ONCE
        //per render pass even though an object may be rendered several times for different materials
        
        //if there's a "next" ipo waiting for us, use it
        if (_nextIpo) {
            [_ipo release];
            _ipo = _nextIpo;
            _nextIpo = nil;  
            //set the initial transform
            [_ipo setInitialTransform:_transform];
        }
        
        if( (_ipo != nil) && [_ipo isPlaying] )
        {
            [_ipo render];
            _transform->setFromTransform([_ipo transform]);
            [self synchronisePhysicsTransform];
        }
        
        if (_requiresActionAnimation) {
            //soft copies can't have animated vertices as they refer to a 
            //vertex buffer of another entity
            [self renderAction];
        }
        
        //billboarding
        if ((_flagMask & SF_OBJECT_BILLBOARD) != 0) {
            //set the z-axis rotation of the object equal to that of the camera
            _transform->rot()->setZ([(SFCamera*)[_scene camera] transform]->rot()->z());
        }
    }

    SFGL::instance()->glPushMatrix();
    {        
        switch (matrixTransform) {
            case SF_TRANSFORM_MATRIX_APPLY:
                _transform->applyTransform();
                break;
            case SF_TRANSFORM_MATRIX_BIND:
                _transform->multMatrix();
                break;
            //otherwise we do nothing
        }
        //if this is a soft copy then
        //we use the original as the
        //vertex group source
        id pointSource;
        id matSource = nil;
        if (_softOriginal) {
            pointSource = _softOriginal;
            matSource = self;
        } else {
            pointSource = self;
        }

        [pointSource renderVertexGroups:renderPass 
                     useMaterial:useMaterial 
                     materialObject:matSource];
    }
    SFGL::instance()->glPopMatrix();
    
    return YES;
}

-(SF3DObject*)findSpawnableObject{
    //goes through the dupes list (but us first) and returns the first available (not in world at present)
    //object
    if (_worldState == wsDoesNotExist){
        return self;
    }
    if (_nextDuplicate) {
        return [_nextDuplicate findSpawnableObject];
    }
    return nil;
}

-(void)debugDrawObject:(id)notify{
    
    if ((!_scene) or !([_scene selectedCamera])){
        return;
    }
    
    //draw a blue box around the location
    float x, y, z;
    
    //if it's an empty mesh, draw it in green
    vec4 drawColour;
    
    if (![self getNumVerts]) {
        drawColour = COLOUR_SOLID_GREEN;
    } else {
        drawColour = COLOUR_SOLID_BLUE;
    }

    
    sio2Project(_transform->loc()->x(),
                _transform->loc()->y(),
                _transform->loc()->z(),
                [[_scene selectedCamera] matModelView],
                [[_scene selectedCamera] matProjection],
                [[SFGameEngine mainViewController] matViewPort], &x, &y, &z);
    SFGL::instance()->glPushMatrix();
    SFGL::instance()->enter2d(0.0f, 1000.0f);
    [SFUtils drawGlBox:CGRectMake(x - 15, y + 15, 30, 30) colour:drawColour];
    SFGL::instance()->leave2d();
    SFGL::instance()->glPopMatrix();

}

-(void)bindMaterials:(SFResource*)useResource{
    //for each vertex group with a name, seek out the material for it
    NSEnumerator *vertexGroups = [_vertexGroups objectEnumerator];
    for (SFVertexGroup *vertexGroup in vertexGroups) {
        [vertexGroup bindMaterial:useResource];
    }
    [self setupMaterialPhysics];
}

-(NSDictionary*)vertexGroups{
    return _vertexGroups;
}

-(void)renderVertexGroups:(unsigned int)renderPass useMaterial:(BOOL)useMaterial materialObject:(id)materialObject{
    
    BOOL vboBound = NO;
    
    for (NSString *vertexGroupName in _vertexGroups) {
        
        SFVertexGroup *vertexGroup = [_vertexGroups objectForKey:vertexGroupName];
        
        id vertexGroupMaterial = nil;
        
        if (materialObject) {
            //use an alternate vertex group for material settings
            vertexGroupMaterial = [[[materialObject vertexGroupByName:vertexGroupName] material] retain];
        }
        
        if (![vertexGroup willRenderInPass:renderPass]) {
            continue;
        }
        
        //sfDebug(DEBUG_SF3DOBJECT, "Rendering %s", [self UTF8Name]);
        
        if (!vboBound) {
            [self bindVBO:useMaterial];
            vboBound = YES;
        }
        
        if (![self flagState: SF_OBJECT_TWOSIDE]){
            [vertexGroup render:useMaterial renderPass:renderPass altMaterial:vertexGroupMaterial];
        } else {
            glCullFace( GL_FRONT );
            [vertexGroup render:useMaterial renderPass:renderPass altMaterial:vertexGroupMaterial];
            
            glCullFace( GL_BACK );
            [vertexGroup render:useMaterial renderPass:renderPass altMaterial:vertexGroupMaterial];
        }
        
        [vertexGroupMaterial release];
    }
    
    
}

-(vec3)getTargetDirectionDiff:(SF3DObject*)target{
    SFVec *directionOfObject = _transform->loc()->directionTo([target transform]->loc());
    directionOfObject->subtract(_transform->dir());
    vec3 diff = directionOfObject->getVec3();
    delete directionOfObject;
    return diff;
}

-(void)goIdle{
	//perform idle animation
	if (_actionState != OBJECT_IDLE) {
		//sfDebug(TRUE, "Turning Into A Vegetable...");
		[self playAction:[self getActionName:@"idle"] loopAction:YES randomStart:YES];
		_actionState = OBJECT_IDLE;
	}
}

-(void)attack{
	//play attack ipo
	//play turn right animation
    if (_sndAttack and ![_sndAttack isPlayingForceCheck]) {
        [_sndAttack playAsSFX:_transform->loc() repeat:NO];
    }
	if (_actionState != OBJECT_ATTACKING) {
		[self playAction:[self getActionName:@"attack"] loopAction:YES randomStart:YES];
		_actionState = OBJECT_ATTACKING;
	}	
}


@end
