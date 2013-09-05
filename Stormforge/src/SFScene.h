//
//  SFSIO2Resource.h
//  ZombieArcade
//
//  Created by Adam Iredale on 9/11/09.
//  Copyright 2009 Stormforge Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SFProtocol.h"
#import "SFSceneLogic.h"
#import "SFResource.h"
#import "SFStack.h"
#import "SFCamera.h"
#import "SFPhysicsWorld.h"

#define DEBUG_SFSCENE 0

#define DEBUG_SHOW_HUD 0

@interface SFScene : SFResource <PScene> {
	//a wrapper class to an SIO2 resource
	//that allows lazy loading of resources
	//by when they are requested first
	SFSceneLogic *_sl; //the scene logic object
    SFCamera *_selectedCamera;
    SFColour _ambientLight;
    SFPhysicsWorld *_physicsWorld;
    BOOL _physicsEnabled, _cleaningNow, _musicStarted;
    unsigned int _sceneBitBuffers;
    SFOperationQueue *_sceneQueue;
    SF3DObject **_sceneObjects;
    int         _sceneObjectCount;
    BOOL _firstRender, _energySaver; //later...
    NSInteger _frameInterval;
    BOOL _soundLoaded;
}

-(void)appendSceneObject:(SF3DObject*)object;
-(void)stripInvalidSceneObjects;
-(BOOL)render;
-(void)renderGraphics;

-(void)spawnObject:(SF3DObject*)spwnObj withTransform:(SFTransform*)transform adjustZAxis:(BOOL)adjustZAxis;

-(BOOL)loadSound;

-(SFOperation*)addSceneOp:(SEL)sel object:(id)obj;

-(BOOL)sfPhysicsCollisionCallback:(btManifoldPoint)cp colObj0:(const btCollisionObject*)colObj0 partId0:(int)partId0 index0:(int)index0 colObj1:(const btCollisionObject*)colObj1 partId1:(int)partId1 index1:(int)index1;

-(float)frameRate;
-(NSString*)getTitle;
-(NSString*)getDescription:(NSString*)descriptionKind;

-(SFCamera*)selectedCamera;

-(SFPhysicsWorld*)physicsWorld;
-(SF3DObject*)pick:(vec2)pickPos vectorOut:(vec3*)vectorOut;
-(SFCamera*)camera;
-(float)frameRate;

-(int)countObjectsInAreaXY:(SFVec *)origin radius:(float)radius filterClass:(Class)filterClass;

-(float)timeToRenderPasses:(float)seconds;

//sl
@property (nonatomic, readonly,getter=getSl) id _sl;

@end
