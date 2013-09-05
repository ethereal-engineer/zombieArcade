//
//  SFSIO2Resource.m
//  ZombieArcade
//
//  Created by Adam Iredale on 9/11/09.
//  Copyright 2009 Stormforge Software. All rights reserved.
//

#import "SFScene.h"
#import "SFUtils.h"
#import "SFDefines.h"
#import "SFGameInfo.h"
#import "SFGameEngine.h"
#import "SFSceneManager.h"
#import "SFTransform.h"
#import "SF3DObject.h"
#import "SFLamp.h"
#import "SFGLManager.h"
#import "SFGL.h"
#import <OpenGLES/ES1/gl.h>
#import "SFDebug.h"
#import "SFSceneLogic.h"

#define OP_PRIORITY_PHYSICS NSOperationQueuePriorityNormal
#define THREAD_PRIORITY_PHYSICS THREAD_PRIORITY_NORMAL
#define ENABLE_MATERIAL_RENDER 1
#define OVERRIDE_AMBIENT_LIGHT 0
#define OVERRIDE_AMBIENT_LIGHT_COLOUR SFColourMake(0.2f,0.2f,0.2f,1.0f)
#define ENABLE_SINGLE_LIGHTS 1
#define ENABLE_LIGHTING 1

@implementation SFScene

-(id)getSl{
	return _sl;
}

-(NSString*)getTitle{
	return [self objectInfoForKey:@"title"];
}

-(NSString*)getDescription:(NSString*)descriptionKind{
	return [[self objectInfoForKey:@"descriptions"] objectForKey:descriptionKind];
}

-(void)setupLogicClassName{
    //if this "drone" needs a logic controller,
    //this is the name of that controller class
    
    //if we have no logic class of our own
    //we return the game mode logic class if that
    //exists
    
    [self setLogicClassName:[self objectInfoForKey:@"logicClass"]];
    if (![self logicClassName]) {
        [self setLogicClassName:[[self objectInfoForKey:@"gameMode"] objectForKey:@"logicClass"]];
    }
}

-(void)loadLogic{
    [self setupLogicClassName];
	_sl = [SFGameLogic logicObjectWithDrone:self dictionary:nil];
}

-(id)getMasterObjectInfoKey{
	return @"resourceInfo";
}

-(void)setupLight{
    //load the ambient light prefs
#if OVERRIDE_AMBIENT_LIGHT
    [_ambientLight setVector:OVERRIDE_AMBIENT_LIGHT_COLOUR];
    return;
#endif
    id ambientPref = [self objectInfoForKey:@"ambientLight"];
    if (ambientPref) {
        _ambientLight.setR([[ambientPref objectAtIndex:0] floatValue]);
        _ambientLight.setG([[ambientPref objectAtIndex:1] floatValue]);
        _ambientLight.setB([[ambientPref objectAtIndex:2] floatValue]);
        _ambientLight.setA([[ambientPref objectAtIndex:3] floatValue]);
    } else {
        //defaults then
        _ambientLight.setFloats((GLfloat[]){0.5f, 0.5f, 0.5f, 1.0f}, 4);
    }
}

-(void)setupBitBuffers{
    _sceneBitBuffers = (GL_DEPTH_BUFFER_BIT | GL_COLOR_BUFFER_BIT);
    if ([self objectInfoForKey:@"dontClearDepthBuffer"]) {
        _sceneBitBuffers = _sceneBitBuffers & ~GL_DEPTH_BUFFER_BIT;
    }
    if ([self objectInfoForKey:@"dontClearColourBuffer"]) {
        _sceneBitBuffers = _sceneBitBuffers & ~GL_COLOR_BUFFER_BIT;
    }
}

-(int)countObjectsInAreaXY:(SFVec *)origin radius:(float)radius filterClass:(Class)filterClass{
    //returns an array of all objects contained in this sphere
    //that exist in this world
    //this is very rough - uses a box for now
    float yMin, yMax, xMin, xMax;
    float x, y;
    int totalObjects = 0;
    
    x = origin->x();
    y = origin->y();
    
    yMin = y - radius;
    yMax = y + radius;
    xMin = x - radius;
    xMax = x + radius;
    
    NSMutableArray *objects = [[[NSMutableArray alloc] init] autorelease];
    
    for (int i = 0; i < _sceneObjectCount; ++i) {
        SF3DObject *object = _sceneObjects[i];
        if ((filterClass == nil) or ([[object class] isSubclassOfClass:filterClass])) {
            SFVec *loc = [object transform]->loc();
            x = loc->x();
            y = loc->y();
            if (((x >= xMin) and (x <= xMax)) 
                and ((y >= yMin) and (y <= yMax))) {
                [objects addObject:object];
                ++totalObjects;
            }
        }
    }
    return totalObjects;
}

-(id)initWithDictionary:(NSDictionary *)dictionary{
	self = [super initWithDictionary:dictionary];
	if (self != nil){
      //  _touchEvents = [[SFStack alloc] initStack:NO useFifo:YES];
        _firstRender = YES;
        _sceneQueue = [[SFOperationQueue alloc] initQueue:YES cancelOnClean:YES];
        [_sceneQueue setGlContext:[SFGameEngine glContext]];
#if DEBUG_SFOPERATIONQUEUE
        [_sceneQueue setName:[@"sceneQ" stringByAppendingString:[self name]]];
#endif
        _frameInterval = [[self objectInfoForKey:@"frameInterval"] intValue];
        if (!_frameInterval) {
            _frameInterval = SF_DEFAULT_FRAME_INTERVAL;
        }
        [self setupBitBuffers];
        [self setupLight];
        _physicsWorld = new SFPhysicsWorld(self);
        _physicsEnabled = YES;
    }
    return self;
}

-(SFCamera*)getLogicCamera{
	NSString *cameraName;
	if (!_sl) {
		cameraName = @"Camera.Invasion";
	} else {
		cameraName = [_sl getActiveCameraName];
	}
	return [self getItem:cameraName itemClass:[SFCamera class]];
}

-(void)setupCameras{
    _selectedCamera = [self getLogicCamera];
    [_selectedCamera setPerspective];  
    [_selectedCamera setCameraDelegate:_sl];
}

-(void)optimisePhys{
    //[_physicsWorld optimise];
}

-(void)prepAllSceneObjects{
    //set all the scene objects to "wants insertion"
    for (int i = 0; i < _sceneObjectCount; ++i) {
        SF3DObject *object = _sceneObjects[i];
        [object insertIntoWorld];
    }
}

-(void)loadLogicParts{
    //this will only be called when _sl is ready
    int loadPartCount = [_sl getLoadPartCount];
    for (int i = 0; i < loadPartCount; ++i) {
        SFOperation *opLoadTask = [[SFOperation alloc] initWithTarget:_sl
                                                             selector:@selector(loadPart:)
                                                               object:[NSNumber numberWithUnsignedChar:i]];
        [_loadTasks push:opLoadTask];
        [opLoadTask release];
    }
}

-(void)setupLoadTasks{
    [super setupLoadTasks];
    //add extra tasks for us...
    //prep all the scene objects
    [self addLoadTask:@selector(prepAllSceneObjects) object:nil];
    //optimise the physics
    [self addLoadTask:@selector(optimisePhys) object:nil];
    //load the logic controller
    [self addLoadTask:@selector(loadLogic) object:nil];
    //setup cameras
    [self addLoadTask:@selector(setupCameras) object:nil];
    //add the logic controller's load tasks then play
    [self addLoadTask:@selector(loadLogicParts) object:nil];
}

-(BOOL)sfPhysicsCollisionCallback:(btManifoldPoint)cp colObj0:(const btCollisionObject*)colObj0 partId0:(int)partId0 index0:(int)index0 colObj1:(const btCollisionObject*)colObj1 partId1:(int)partId1 index1:(int)index1{

	//convert the sio2object pointers into SF objects
	
	SF3DObject *sfo1 = (SF3DObject*)btRigidBody::upcast(colObj0)->getUserPointer();
	SF3DObject *sfo2 = (SF3DObject*)btRigidBody::upcast(colObj1)->getUserPointer();
	
	//tell the scene logic we have had a crash between these two...
	if ((sfo1 != nil) and (sfo2 != nil)) {
		[_sl handleObjectCollision:sfo1 object2:sfo2];
	}
	
	return NO;
}

//-(void)playLogic{
//	[_sl play];
//}

-(BOOL)loadSound{
    //once sound is ready this will be called - NO SOUND LOADING
    //until then
    
    //some extra stuff that needs to be seperated out here later...
    
    if (!_soundLoaded) {
        [_sl loadPlayerData];
        [self precacheAll];
        [_sl precache];
        [_sl play];
        _soundLoaded = YES;
    }
    return NO; //no indicates no more to load
}

-(void)pruneDuplicates{
    //remove any duplicates we have made of objects
    for (int i = 0; i < _sceneObjectCount; ++i) {
        SF3DObject *object = _sceneObjects[i];
        [object pruneDuplicates];
    }
}

-(void)cleanUp{
    [_sl cleanUp];
	[_sl release];
	_sl = nil;
    [_sceneQueue release];
    delete _physicsWorld;
    _physicsWorld = nil;
    [self pruneDuplicates];
    free(_sceneObjects);
    [super cleanUp];
}

-(SFPhysicsWorld*)physicsWorld{
	return _physicsWorld;
}

-(void)appendSceneObject:(SF3DObject*)object{
    //use only in loading!
    _sceneObjects = (SF3DObject**)realloc(_sceneObjects, sizeof(SF3DObject*) * (_sceneObjectCount + 1));
    _sceneObjects[_sceneObjectCount] = object;
    ++_sceneObjectCount;
}

-(void)renderObjects:(SF_TRANSFORM_MATRIX_TYPE)matrixTransform useMaterial:(BOOL)useMaterial{    
    //perform each kind of render pass on all objects
    //in scene
    
    for (int i = 0; i < _sceneObjectCount; ++i) {
        SF3DObject *object = _sceneObjects[i];
        [object processWorldState:_physicsWorld];
    }
    //now render the existing ones
    for (unsigned int pass = SF_RENDER_PASS_OPAQUE; pass < SF_RENDER_PASS_ALL; ++pass) {
        for (int i = 0; i < _sceneObjectCount; ++i) {
            SF3DObject *object = _sceneObjects[i];
            [object render:pass matrixTransform:matrixTransform useMaterial:useMaterial];
        }
    }
}

-(void)stripInvalidSceneObjects{
    //remove any objects from this scene (free them too if needed)
    //that have a non-blank mode that is not equal to the name given here
    NSString *logicStyleName = [[self objectInfoForKey:@"gameMode"] objectForKey:@"identifier"];
    if (!logicStyleName) {
        return;
    }

    for (int i = _sceneObjectCount - 1; i > -1 ; --i) {
        SF3DObject *sceneObject = _sceneObjects[i];
        NSString *modeTag = [sceneObject getBlenderInfo:@"mode"];
        if ((modeTag != nil) and (![modeTag isEqualToString:logicStyleName])) {
            sfDebug(TRUE, "Stripping %s from scene for logic", [sceneObject UTF8Description]);
            [sceneObject removeAfter:0];
        }
    }
}

-(void)addMemoryItem:(id)newItem{
    //once the item has been added, set the scene!
    [super addMemoryItem:newItem];
    [newItem setScene:self];
    if ([[newItem class] isSubclassOfClass:[SF3DObject class]]) {
        [self appendSceneObject:newItem];
    }
}

-(SFCamera*)selectedCamera{
    return _selectedCamera;
}

-(void)updateSceneLogic{
    [_sl updateScene];
}

-(void)renderLights{
    //copy so we can add/remove when we please
	NSArray *lamps = [NSArray arrayWithArray:[[_itemDictionaries objectForKey:[SFLamp class]] allValues]];
    
    //perform each kind of render pass on all objects
    for (int i = 0; i < [lamps count]; ++i) {
        SFLamp *lamp = [lamps objectAtIndex:i];
        [lamp render:i];
    }
};

-(void)spawnObject:(SF3DObject*)spwnObj withTransform:(SFTransform*)transform adjustZAxis:(BOOL)adjustZAxis{
    //moved all spawning routines HERE - it is the scene's responsibility after all

    //first of all, if we have been asked to adjust the z-axis, that means that the spawn object's
    //center is not at the base of the object and we are to compensate by spawning them half their z-height
    //higher than the transform
    if (adjustZAxis) {
        SFTransform *zAdjustedTrans = transform->copy();
        zAdjustedTrans->loc()->addZ([spwnObj dimensions]->z() / 2.0f);
        [spwnObj setFirstSpawnTransform:zAdjustedTrans];
        delete zAdjustedTrans;
    } else {
        //otherwise...
        //we set these by setting our first spawn transform
        //upon which, all other transforms are calculated
        [spwnObj setFirstSpawnTransform:transform];
    }


	//get this object ready to be seen and interacted with
    [spwnObj insertIntoWorld];
}

-(float)frameRate{
    return 60.0f / _frameInterval;
}

-(float)timeToRenderPasses:(float)seconds{
    //using the current scene's frame rate,
    //calculate the number of render passes
    //that can be used to time an event
    //rather than using system time
    return seconds * [self frameRate];
}

-(SFOperation*)addSceneOp:(SEL)sel object:(id)obj{
    SFOperation *opScene = [[[SFOperation alloc] initWithTarget:self
                                                      selector:sel
                                                        object:obj] autorelease];
    [_sceneQueue addOperation:opScene priority:NSOperationQueuePriorityNormal];
    return opScene;
}

-(BOOL)render{
    //if the scene is ready we run renderScene then
    //return yes
    if (!_fullyLoaded) {
        return NO;
    }
    [SFGameEngine swapBuffers:YES];
    if (_firstRender) {
        _firstRender = NO;
        SFGL::instance()->glClearColor(COLOUR_SOLID_WHITE);
        //start playing our music
#if MUTE_SCENE_MUSIC == 0
        [_sl playMusic];
#endif
    }
    if ([_sl active]) {
        _physicsWorld->stepSimulation();
    }
    [self renderGraphics];
    [_sl updateScene];
    //[SFGameEngine swapBuffers:YES];
    return YES;
}

-(SF3DObject*)pick:(vec2)pickPos vectorOut:(vec3*)vectorOut{
    //prepare a vector for the output data
	btVector3 pickVector;

    //must understand this better later - it's a difference of origin points
    vec2 correctedPosition;
    correctedPosition.x = pickPos.y;
    correctedPosition.y = pickPos.x;
    correctedPosition.y *= -1;
    correctedPosition.y += 480.0f;
    
	btVector3 rayTo = [_selectedCamera getRayTo:correctedPosition];
	
	btVector3 camPos = [_selectedCamera transform]->loc()->getBtVector3();
    
	SF3DObject *pickedObject = _physicsWorld->pickObject(&rayTo, &camPos, &pickVector);
	if (pickedObject) {
        //if we have picked a "proxy" object - that is, the colmesh of an object that we
        //really want to pick, we return that object instead
        id proxyTarget = [pickedObject proxyTarget];
        if (proxyTarget) {
            pickedObject = proxyTarget;
        }
        *vectorOut = Vec3Make(pickVector.x(), pickVector.y(), pickVector.z());
        return pickedObject;
	}
    return nil;
}

-(void)renderGraphics{
	SFGL::instance()->glMatrixMode(GL_MODELVIEW);
	glLoadIdentity();
    glClear(_sceneBitBuffers);
    // Enter the 3D landscape mode
    SFGL::instance()->enterLandscape3d();
    {
        [_selectedCamera render];
        SFGL::instance()->lampSetAmbient(_ambientLight.floatArray());
#if ENABLE_LIGHTING
        SFGL::instance()->enableLighting();
#endif
        
#if ENABLE_SINGLE_LIGHTS
        [self renderLights];
#endif
        [self renderObjects:SF_TRANSFORM_MATRIX_BIND useMaterial:ENABLE_MATERIAL_RENDER];
        SFGL::instance()->objectReset();
        SFGL::instance()->materialReset();
        _physicsWorld->renderDebug();
        //the render turns on all the lamps - we turn them all off here
        SFGL::instance()->disableAllLamps();
        SFGL::instance()->disableLighting();
        // Leave the landscape mode.
        SFGL::instance()->leaveLandscape3d();
    }
    
    SFGL::instance()->enter2d(0.0f, 1.0f);
    {
        //enter 2d landscape mode
        SFGL::instance()->enterLandscape2d();
        {
            [_sl renderWidgets];
            //leave 2d landscape
            SFGL::instance()->leaveLandscape2d();
        }
        SFGL::instance()->leave2d();
    }
    
    SFGL::instance()->objectReset();
    SFGL::instance()->materialReset();
}

-(SFCamera*)camera{
    return _selectedCamera;
}

@end
