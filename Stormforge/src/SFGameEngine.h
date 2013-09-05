//
//  SFGameEngine.h
//  ZombieArcade
//
//  Created by Adam Iredale on 11/11/09.
//  Copyright 2009 Stormforge Software. All rights reserved.
//

#ifndef SFGAMEENGINE_H

#import <UIKit/UIKit.h>
#import "EAGLView.h"
#import <Foundation/Foundation.h>
#import "SFGameSingleton.h"
#import "SFPlayer.h"
#import "SFProtocol.h"
#import "SFDefines.h"
#import "SFOperation.h"
#import "SFLoadingScreen.h"
#import "SFViewController.h"

#define DEBUG_SFGAMEENGINE 0

@class EAGLView;

@interface SFGameEngine : SFGameSingleton <UIAccelerometerDelegate, UIApplicationDelegate, PGameEngine> {
	//generic 3D game engine management object
	//to communicate with SIO2
	//the local player
    
    IBOutlet UIWindow   *window;
    IBOutlet SFViewController *mainViewController;
    
	SFPlayer            *_localPlayer;
	BOOL                _disableRendering; 
	BOOL                _engineStarted, _soundIsReady;
	SFOperationQueue    *_defaultQueue, 
                        *_serialQueue;
	SFLoadingScreen     *_loadingScreen;
    NSMutableArray      *_playableVideo;
    id                  _videoSIO2,
                        _videoSF, 
                        _videoGameIntro;
    
    char				app_path[ SF_MAX_PATH ];
    char				app_name[ SF_MAX_CHAR ];
    
    unsigned int		i_time;
    
    unsigned int		_wid[ 2 ]; //vbo pointers
    
    unsigned char		_tfilter;
    unsigned char		_afilter;
    
    int					cpu_mhz;
    int					bus_mhz;
    
    char				sys[ SF_MAX_CHAR ];
    
    BOOL                _queuingTask;
    SFStack             *_touchEvents, *_gameCenterNotifications;
    NSString            *_appVersion;
    id                  _sceneManager;
    BOOL                _GREEStarted;
    u_int64_t           _renderId;
}

-(void)render;
+(void)render;

-(int64_t)currTime;
-(int64_t)lastSync;
+(int64_t)currTime;
+(int64_t)lastSync;

-(unsigned char)afilter;
-(unsigned char)tfilter;
+(unsigned char)afilter;
+(unsigned char)tfilter;

+(SFViewController*)mainViewController;

//other child-override functions
-(SFPlayer*)createPlayer;
-(void)start;
-(void)startSoundJob;
-(BOOL)gameIsInLandscapeMode;

-(SFOperationQueue*)defaultQueue;
+(SFOperationQueue*)defaultQueue;
+(SFOperationQueue*)serialQueue;
-(SFOperationQueue*)serialQueue;
-(SFPlayer*)getLocalPlayer;

-(void)pushTouchEvent:(SFTouchEvent*)touchEvent;
+(void)pushTouchEvent:(SFTouchEvent*)touchEvent;

+(BOOL)gameIsInLandscapeMode;
+(SFPlayer*)getLocalPlayer;
-(void)swapAllBuffers;
-(void)swapBuffers:(BOOL)performGlSwap;
+(void)swapBuffers:(BOOL)performGlSwap;

+(id)glContext;
-(id)glContext;

+(u_int64_t)renderId;
-(u_int64_t)renderId;

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet SFViewController *mainViewController;

@end

#define SFGAMEENGINE_H
#endif