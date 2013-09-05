//
//  SFSIO2ResourceManager.m
//  ZombieArcade
//
//  Created by Adam Iredale on 9/11/09.
//  Copyright 2009 Stormforge Software. All rights reserved.
//

#import "SFSceneManager.h"
#import "SFSceneLogic.h"
#import "SFUtils.h"
#import "SFDefines.h"
#import "SFScoreManager.h"
#import "SFGameEngine.h"

static SFSceneManager *gSFSceneManager = nil;

@implementation SFSceneManager

-(id<PScene>)currentScene{
	return _currentScene;
}

-(void)notifyLevelOver{
    //tell the score manager to compute final scores etc
    [[self scom] levelIsOver];
}

-(SFRenderResult)render:(BOOL)soundAvailable 
         allowLoadDelta:(BOOL)allowLoadDelta 
            touchEvents:(NSArray*)touchEvents
            otherEvents:(NSArray*)otherEvents{
    //if we are changing scenes then the change will wait until we get to this point
    if (_startChangingScenes){
        _startChangingScenes = NO;
        _changingScenes = YES;
        [[SFGameEngine defaultQueue] addOperation:self
                                         selector:@selector(setSceneWithDictionary:)
                                           object:_nextSceneInfo];
        [_nextSceneInfo release];
    }
    //this gets called A LOT
    //firstly - if we don't have a current scene, or are changing scenes,
    //render a loading screen
    if (_changingScenes) {
        [_loadingScreen render];
        return rrChangingScenes;
    }
    
    //ok, so we have a current scene - are we allowed to load/render it?
    if (!allowLoadDelta) {
        [_loadingScreen render];
        return rrWaitingToLoad;
    }
    
    //we are allowed to load now (or render, if there's sound ready)

    SFScene *currentScene = [_currentScene retain];
    
    //the loading loop
    while ([currentScene loadDelta]) {
        [_loadingScreen render];
    }
    
    //ok so after all that we might still be waiting for sound (that's all)
    if (!soundAvailable) {
        [_loadingScreen render];
        [currentScene release];
        return rrWaitingForSound;
    }
    
    //when sound is ready we can set up our
    //sound tasks
    while ([currentScene loadSound]) {
        [_loadingScreen render];
    }
    
    //ok, so we are fully loaded and all resources are ready for rendering
    // - let's render!
    BOOL renderedOk = [currentScene render];
    
    //now process any touch events
    for (SFTouchEvent *touchEvent in touchEvents) {
        [currentScene._sl dispatchTouchEvents:touchEvent];
    }

    [currentScene release];
    if (renderedOk) {
        return rrRenderedOk;
    };
    return rrDroppedFrame;
}

-(void)processOtherEvents:(NSArray *)otherEvents{
    //for processing game center events - only when we are rendering in a 
    //scene
    SFScene *currentScene = [_currentScene retain];
    [_currentScene._sl dispatchOtherEvents:otherEvents];
    [currentScene release];
}

-(id)currentLogic{
	return _currentScene._sl;
}

-(void)cleanUpCurrentScene{
    if (_currentScene != nil){
        [self notifyLevelOver];
        [_currentScene cleanUp];
        [_currentScene release];
        _currentScene = nil;
	}
}

-(void)setSceneWithDictionary:(NSDictionary*)newSceneInfo{
	[self cleanUpCurrentScene];
    //[[self rm] flushResources];
	NSMutableDictionary *addDictionary = [[NSMutableDictionary alloc] init];
	[addDictionary addEntriesFromDictionary:newSceneInfo];
    [addDictionary setObject:@"SFScene" forKey:@"objectClass"];
	_currentScene = [[[self rm] getResourceWithDictionary:addDictionary] retain];
	[addDictionary release];
    _changingScenes = NO;
}

-(void)changeScene:(NSDictionary*)newSceneInfo{
    _nextSceneInfo = [newSceneInfo retain];
    _startChangingScenes = YES;
}

-(id)initWithDictionary:(NSDictionary *)dictionary{
    self = [super initWithDictionary:dictionary];
    if (self != nil) {
        _loadingScreen = [[SFLoadingScreen alloc] initLoadingScreen];
        _renderFinished = [[NSCondition alloc] init];
    }
    return self;
}

-(void)cleanUp{
    _changingScenes = YES;
    [self cleanUpCurrentScene];
    [_loadingScreen release];
    [_renderFinished release];
    [super cleanUp];
}

-(void)pauseScene:(BOOL)pause{
    id sceneLogic = [self currentLogic];
    if (sceneLogic) {
        [sceneLogic pause:pause];
    }
}

+ (SFGameSingleton**)getGameSingletonPointer{
	return &gSFSceneManager;
}

-(void)dispatchTouchEvents:(SFTouchEvent*)touchEvent{
   // [[self currentScene] pushTouchEvent:touchEvent];
    [[self currentLogic] dispatchTouchEvents:touchEvent]; //this is causing some issues..
}

+(void)dispatchTouchEvents:(SFTouchEvent*)touchEvent{
	[[SFSceneManager alloc] dispatchTouchEvents:touchEvent];
}

-(BOOL)sceneHasInfiniteAmmo{
	return [[self currentLogic] sceneHasInfiniteAmmo];
}

+(BOOL)sceneHasInfiniteAmmo{
	return [[SFSceneManager alloc] sceneHasInfiniteAmmo];
}

@end
