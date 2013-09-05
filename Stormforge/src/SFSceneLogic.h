//
//  SFSceneLogic.h
//  ZombieArcade
//
//  Created by Adam Iredale on 16/11/09.
//  Copyright 2009 Stormforge Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SFGameLogic.h"
#import "SFProtocol.h"
#import "SFWidget.h"
#import "SFTouchEvent.h"
#import "SFWidgetUI.h"
#import "SFStack.h"
#import "SF3DObject.h"
#import "SFTarget.h"
#import "SFAchievementNotification.h"

#define DEBUG_SFSCENELOGIC 0

typedef enum {
    LOGIC_STOPPED,
    LOGIC_PLAYING,
    LOGIC_PAUSED
} SCENE_LOGIC_STATE;

@interface SFSceneLogic : SFGameLogic <PSceneLogic> {
	//this class is a superclass, the children of which
	//are designed to be invoked at runtime only
	//the blender scenes point to a particular SFSceneLogic
	//descendant that handles their internal workings etc
	BOOL _achievementsSynchronised;
	NSMutableArray *_targets; //all targets in the scene
	NSMutableArray *_wayPoints; //all waypoints in the scene
	NSMutableArray *_spawnPoints; //spawnpoints
	NSMutableArray *_startPoints; //start points
	unsigned char _logicState;
	int _startTime;
	int _sceneTimeLimit;
	BOOL _timeUpFired;
	id _ambientMusic; //music
	float _2dLayer; //the top layer we are rendering
	unsigned int _lastTouchEvent;
	unsigned char _lastTouchKind;
	id _lastTouchWidget;
	SFWidgetUI *_ui;
	int _nextSpawnPoint;
	BOOL _firstRun;
	id _opBufferLoop;
    unsigned int _activeTargetCount;
    id _debugHud;
    id _playerBox;
    SFStack *_spawnPointStack;
    NSString *_mainAtlasName;
    BOOL _needsTarget;
    BOOL _autoSaveScene;
    SFAchievementNotification *_achievementNotification;
    SFStack *_achievementsUnlocked;
    BOOL _highScoreNotified, _notifyHighScore;
    float _extraRagdollTime; //some modes might want more...
}

-(void)play;
-(void)playFirst;
-(void)pause:(BOOL)pauseState;
-(void)stop;
-(void)loadTargets;
-(void)findAllPoints;
-(void)loadPlayerData;

-(SFTarget*)getSpawnableTarget;

-(void)handleObjectCollision:(id)object1 object2:(id)object2;
-(void)handleAmmoHitTarget:(id)ammo target:(id)target;
-(void)handleOtherCollision:(id)object1 object2:(id)object2;
-(void)handleTargetHitTarget:(id)target1 target2:(id)target2;
-(void)handleTargetHitPlayer:(id)target player:(id)player;
-(void)handleAmmoHitOther:(id)ammo otherObject:(id)otherObject;
-(void)handleTargetHitOther:(id)target otherObject:(id)otherObject;

-(BOOL)sceneHasInfiniteAmmo;
-(void)showAnyAchievements;

-(void)handlePlayerHurt:(NSNotification*)hurtNotice;
-(void)handlePlayerDead:(NSNotification*)deadNotice;

-(void)loadWidgets;
-(void)renderWidgets;

-(void)updateSceneActors;
-(void)updateScene;

-(void)makeSceneChoices;

-(void)addTarget;
-(BOOL)activateTarget:(SF3DObject*)spawnPoint;
-(void)deactivateTarget;

-(int)getTimeLeft;
-(NSString*)getTimeLeftString;

-(void)timeUpEvent;

-(void)playMusic;

-(SF3DObject*)selectRandomUnusedSpawnPoint;

-(void)stopMusic;
-(void)dispatchTouchEvents:(SFTouchEvent*)touchEvent;

-(SF3DObject*)selectRandomWayPoint;
-(SF3DObject*)selectRandomStartPoint;
-(SF3DObject*)selectRandomSpawnPoint;

-(id)playerBox;

-(void)uiAction:(SFWidget*)uiWidget;

-(void)showGradeScreen;

+(int)getMinimumTargetCount;
+(BOOL)sceneHasInfiniteAmmo;

-(void)spawnRandomTarget;

-(NSString*)getActiveCameraName;

-(BOOL)active;

-(void)autoSaveScene;
-(void)setAutoSaveScene:(BOOL)doAutoSave;
-(float)extraRagdollTime;

@end
