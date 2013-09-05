//
//  SFSIO2ResourceManager.h
//  ZombieArcade
//
//  Created by Adam Iredale on 9/11/09.
//  Copyright 2009 Stormforge Software. All rights reserved.
//

#ifndef SFSCENEMANAGER_H

#import <Foundation/Foundation.h>
#import "SFGameSingleton.h"
#import "SFScene.h"
#import "SFProtocol.h"
#import "SFPlayer.h"
#import "SFTouchEvent.h"
#import "SFOperation.h"
#import "SFLoadingScreen.h"

@interface SFSceneManager : SFGameSingleton <PSceneManager> {
	//a custom class for handling the many SIO2 resources we will use
	//specifically, for handling the scene resources 
	SFScene *_currentScene;
    unsigned int _renderDelay;
	id _cameraIpoCallbackObject;
	SEL _cameraIpoCallbackSelector;
	id _cameraDestObj;
    BOOL _changingScenes, _ackRenderOver, _startChangingScenes;
    NSCondition *_renderFinished;
    SFLoadingScreen *_loadingScreen;
    id _nextSceneInfo;
}

-(void)changeScene:(NSDictionary *)newSceneInfo;
+(BOOL)sceneHasInfiniteAmmo;
-(void)dispatchTouchEvents:(SFTouchEvent*)touchEvent;
+(void)dispatchTouchEvents:(SFTouchEvent*)touchEvent;

@end

#define SFSCENEMANAGER_H
#endif