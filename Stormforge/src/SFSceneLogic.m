//
//  SFSceneLogic.m
//  ZombieArcade
//
//  Created by Adam Iredale on 16/11/09.
//  Copyright 2009 Stormforge Software. All rights reserved.
//

#import "AllSingletons.h"
#import "SFSceneLogic.h"
#import "SFUtils.h"
#import "SF3DObject.h"
#import "SFWidget.h"
#import "SFWidgetLabel.h"
#import "SFScoreManager.h"
#import "SFTarget.h"
#import "SFDefines.h"
#import "SFListingWidget.h"
#import "SFScene.h"
#import "SFSound.h"
#import "btCollisionWorld.h"
#import "SFDebugHud.h"
#import "SFDebug.h"

#define SCENE_DEFAULT_TIME 120
#define MUTE_SCENE_MUSIC 0
#define DEBUG_COLLISIONS 0
#define ONE_CHOICE_PER_PASS 0
#define DEBUG_WIDGET_DELEGATE 0
#define REASONABLE_DRAG_WIDTH 20

#define SOUND_UNLOCK @"unlock.ogg"

typedef enum {
    llpWidgets,
    llpPoints,
    llpTargets,
    llpStripObjects,
    llpAll
} SFLogicLoadPart;

@implementation SFSceneLogic

-(void)setAutoSaveScene:(BOOL)doAutoSave{
    _autoSaveScene = doAutoSave;
}

-(void)autoSaveScene{
    //children - is called if 
    //the app is being terminated (for a call, etc)
    if (_autoSaveScene) {
        [[self scom] compileAndSave:YES];
    }
}

-(void)showAnyAchievements{
    [_ui removeSubWidget:_achievementNotification];
    NSString *resourceId;
    if (_notifyHighScore and !_highScoreNotified) {
        //we only notify once for highscores - because there
        //are many of them...
        [_achievementNotification setHighScore];
        _highScoreNotified = YES;
    } else {
        resourceId = [[_achievementsUnlocked peek] retain];
        [_achievementsUnlocked pop];
        if (!resourceId) {
            [self showGradeScreen];
            return;
        }
        [_achievementNotification setAchievement:resourceId];
        [resourceId release];
    }
    [_ui addSubWidget:_achievementNotification];
    [SFSound quickPlayAmbient:SOUND_UNLOCK];
}

-(BOOL)active{
    return _logicState == LOGIC_PLAYING;
}

-(NSString*)getActiveCameraName{
	//children to override - default camera is "Camera"
	return @"Camera";
}

-(id)playerBox{
    if (!_playerBox) {
        _playerBox = [[self scene] getItem:@"playerHurtTrigger" itemClass:[SF3DObject class]];
    }
    return _playerBox;    
}

-(void)cameraWillMove:(id)camera{
    //the camera is about to start moving - prepare
}

-(void)cameraDidMove:(id)camera{
    //the camera just stopped moving - do whatever
}

-(id)getFirstClassObject:(Class)aClass object1:(id)object1 object2:(id)object2 otherObject:(id*)otherObject{
	//figure out which object is which as FAST as possible
	if ([[object1 class] isSubclassOfClass:aClass]) {
		*otherObject = object2;
		return object1;
	} else if ([[object2 class] isSubclassOfClass:aClass]) {
		*otherObject = object1;
		return object2;
	} else {
		*otherObject = nil;
		return nil;
	}
}

-(id)getFirstWorldObject:(id)object1 object2:(id)object2 otherObject:(id*)otherObject{
	BOOL worldCheckVal = [object1 isWorld];
	if (worldCheckVal) {
		*otherObject = object2;
		return object1;
	} else {
		worldCheckVal = [object2 isWorld];
		if (worldCheckVal) {
			*otherObject = object1;
			return object2;
		} else {
			*otherObject = nil;
			return nil;
		}
	}	
}

-(float)extraRagdollTime{
    return _extraRagdollTime;
}

-(id)getFirstEqualObject:(id)compareWith object1:(id)object1 object2:(id)object2 otherObject:(id*)otherObject{
	if (compareWith == object1) {
		*otherObject = object2;
		return object1;
	} else if (compareWith == object2) {
		*otherObject = object1;
		return object2;
	} else {
		*otherObject = nil;
		return nil;
	}
}

-(void)showGradeScreen{
	//children
}

-(void)handleHitOrder:(id)attacker victim:(id)victim{
    [victim wasHitBy:attacker];
    [attacker didHit:victim];
}

-(void)handleTargetHitPlayer:(id)target player:(id)player{
	//at this point it means that the target has hit the honeybox
	//which is a phys object surrounding the camera
#if DEBUG_SFSCENELOGIC
	sfDebug(TRUE, "Player hit!");
#endif
    [self handleHitOrder:target victim:player];
}

-(id)getFirstTrigger:(id)object1 object2:(id)object2 otherObject:(id*)otherObject{
    if ([object1 doesActAsTrigger]) {
        *otherObject = object2;
        return object1;
    } else if ([object2 doesActAsTrigger]) {
        *otherObject = object1;
        return object2;
    } else {
        *otherObject = nil;
        return nil;
    }

}

-(void)handleObjectCollision:(id)object1 object2:(id)object2{
	//there's been a collision between these two objects
#if DEBUG_COLLISIONS
	sfDebug(TRUE, "COLLISION: %s <-> %s", [[object1 name] UTF8String], [[object2 name] UTF8String]);
#endif
    id otherObject;
	//is this a hitworld? (very common)
	//we will allow each object to handle their own hitworld stuff
	//the rest can go to scene logic
	id world = [self getFirstWorldObject:object1 object2:object2 otherObject:&otherObject];
	if (world) {
		[otherObject hitWorld:world];
		return;
	}
    
    id trigger = [self getFirstTrigger:object1 object2:object2 otherObject:&otherObject];
    if (trigger) {
        [trigger activateTrigger:otherObject];
        return;
    }
    
	//if it isn't a hitworld then...
	//is this ammo hits target?
	id ammo = [self getFirstClassObject:[SFAmmo class] object1:object1 object2:object2 otherObject:&otherObject];
	if (ammo){
		//ammo was involved
		if ([[otherObject class] isSubclassOfClass:[SFTarget class]]){
			//ammo hit a target
            [self handleAmmoHitTarget:ammo target:otherObject];
		} else {
            //ammo hit something else - assign to "other"
            [self handleAmmoHitOther:ammo otherObject:otherObject];
		}
	} else {
		//no ammo was involved at all
		//was this a target hitting another target?
		otherObject = nil;
		id target = [self getFirstClassObject:[SFTarget class] object1:object1 object2:object2 otherObject:&otherObject];
		if (target) {
			//a target class was involved
			if ([[otherObject class] isSubclassOfClass:[SFTarget class]]){
				//target hit another target
				[self handleTargetHitTarget:target target2:otherObject];
			} else if (otherObject == [self playerBox]) {
				//the target has hit the player
				[self handleTargetHitPlayer:target player:[SFGameEngine getLocalPlayer]];
			} else {
				//target hit an unknown object - assign it to "other"
				[self handleTargetHitOther:target otherObject:otherObject];
			}

		} else {
			//no targets and no ammo were involved - assign it to "other"
			[self handleOtherCollision:object1 object2:object2];
		}

	}
}

-(void)handlePlayerHurt:(NSNotification*)hurtNotice{
	//the player has taken hurt - update huds and flash the screen etc
}

-(void)handlePlayerDead:(NSNotification*)deadNotice{
	//the player is dead - show the game over screen
}

-(void)precacheSounds:(NSMutableArray *)sounds{
    [super precacheSounds:sounds];
    [sounds addObject:SOUND_UNLOCK];
}

-(void)uiAction:(SFWidgetUI*)uiWidget{
    //the screen has been touched (possibly scene-picked)
    //and no widget is interested in the data - are we?
    
}

-(id)initWithDrone:(id)drone dictionary:(NSDictionary*)dictionary{
	self = [super initWithDrone:drone dictionary:dictionary];
	if (self != nil) {
        _achievementsUnlocked = [[SFStack alloc] initStack:YES useFifo:YES];
        _spawnPointStack = [[SFStack alloc] initStack:NO useFifo:YES];
        _targets = [[NSMutableArray alloc] init];
        _sceneTimeLimit = SCENE_DEFAULT_TIME;
        _mainAtlasName = [@"main" retain];
        _ui = [[SFWidgetUI alloc] initUI:_mainAtlasName];
        [_ui setWidgetDelegate:self];
        [_ui setScene:drone];
		_firstRun = YES;
	}
	return self;
}

-(SFScene*)scene{
    //override again
    return [self getDrone];
}

-(int)getLoadPartCount{
    //returns the number of load calls required to fully load
    //this logic unit
    return llpAll;
}

-(void)stripObjects{
    //this is where we go through and strip out scene objects that are 
    //not meant for this logic style
    //that is, objects that have a "mode" tag that is not blank
    //and not equal to our logic tag
    [[self scene] stripInvalidSceneObjects];
}

-(void)loadPart:(NSNumber *)loadPart{
    //this will be called as many times as returned by getLoadPartCount
    switch ([loadPart unsignedCharValue]) {
        case llpWidgets:
            [self loadWidgets];
            break;
        case llpPoints:
            [self findAllPoints];
            break;
        case llpTargets:
            [self loadTargets];
            break;
        case llpStripObjects:
            [self stripObjects];
            break;
        default:
            break;
    }
}

-(void)precacheObjects:(NSMutableArray *)objects{
    [super precacheObjects:objects];
    //precache all weaponry resources (sounds, icons etc)
    if (![self objectInfoForKey:@"noWeapons"]) {
        [objects addObjectsFromArray:[[[SFGameEngine getLocalPlayer] weapons] allValues]];
    }
}

-(void)precacheImages:(NSMutableArray *)images{
    [super precacheImages:images];
    //make sure the main and font atlas are ready
    //at least
    [images addObject:[[[self gi] getAtlasInfo:@"main"] objectForKey:@"filename"]];
    [images addObject:[[[self gi] getAtlasInfo:@"font"] objectForKey:@"filename"]];
}

-(void)loadMusic{

}

-(void)playMusic{
    //play also loads to keep the buffer happy that it is playing, so continue to buffer...
    
#if MUTE_SCENE_MUSIC == 0
	NSString *ambientSound;
	if ([[self objectInfoForKey:@"useRandomMusic"] boolValue]) {
		//get a random piece from the style of level we are playing
        id gameMode = [self objectInfoForKey:@"gameMode"];
		id logicStyle = [gameMode objectForKey:@"identifier"];
		NSArray *musicChoices = [[self gi] getMusicArray:logicStyle];
		ambientSound = [SFUtils getRandomFromArray:musicChoices];
        sfDebug(TRUE, "Chose music: %s", [ambientSound UTF8String]);
	} else {
		ambientSound = [self objectInfoForKey:@"ambientMusic"];
	}
    
	if (ambientSound) {
       // _ambientMusic = [SFSound newStreamAmbient:ambientSound];
        ambientSound = [SFUtils getFilePathFromBundle:ambientSound];
        SFAL::instance()->playStreamedMusic([ambientSound UTF8String]);
	}
#endif
}

-(void)findAllPoints{
    _wayPoints = [[[self scene] getItemGroup:@"wayPoint" itemClass:[SF3DObject class]] retain];
    _startPoints = [[[self scene] getItemGroup:@"startPoint" itemClass:[SF3DObject class]] retain];
    _spawnPoints = [[[self scene] getItemGroup:@"spawnPoint" itemClass:[SF3DObject class]] retain];
}

-(void)loadTargets{
	//children to override
}

-(void)loadPlayerData{
	//children to override
	//this is where the player object is used
	//to change things in the scene
}

-(void)createDynamicIpos{
	//children to override - create dynamic ipos and
	//add them to the scene
}

-(void)destroyDynamicIpos{
	//children
}

-(int)getTimeLeft{
	int timeLeft = _sceneTimeLimit - (time(NULL) - _startTime);
	if (timeLeft < 0) {
		timeLeft = 0;
	}
	return timeLeft;
}

-(NSString*)getTimeLeftString{
	return [[NSNumber numberWithInt:[self getTimeLeft]] stringValue];
}

-(void)pauseMusic:(BOOL)doPause{
	if (_ambientMusic) {

	}
}

-(void)stopMusic{
	//if (_ambientMusic) {
//		[_ambientMusic stopPlaying];
//	}
    SFAL::instance()->stopStreamedMusic();
}

-(void)playFirst{
	//for children to set up initial things that must happen when we
	//are active to begin with
    [[self scom] setPlayerDelegate:self];
    [[self scom] setLevelGradeDelegate:self];
    [[self scom] setScoreDisplayDelegate:self];
    [[self scom] reset:[self scene]];
}

-(void)achievementsSynchronised{
    //when achievements have loaded this will be called
    _achievementsSynchronised = YES;
}

-(void)play{
	//start the scene clock
    if (_logicState != LOGIC_PLAYING) {
        _logicState = LOGIC_PLAYING;
        
        //[self playMusic];
        [_ui show];
        if (_firstRun) {
            _startTime = time(NULL);
            _firstRun = NO;
            [self playFirst];
        }
    }
}

-(void)stop{
	//stop the scene clock
    if (_logicState != LOGIC_STOPPED) {
        [_ui hide];
        [self stopMusic];
        _logicState = LOGIC_STOPPED;
    }
}

-(void)cleanUp{
    [self stop];
    [[self scom] setPlayerDelegate:nil];
    [[self scom] setLevelGradeDelegate:nil];
    [[self scom] setScoreDisplayDelegate:nil];
    [_ambientMusic release];
	[_ui cleanUp];
	[self destroyDynamicIpos];
	[_targets removeAllObjects];
	[_ui release];
	[_targets release];
	[_wayPoints release];
	[_startPoints release];
	[_spawnPoints release];
    [_spawnPointStack release];
    [_mainAtlasName release];
    [_achievementNotification release];
    [_achievementsUnlocked release];
    [super cleanUp];
}

-(void)pause:(BOOL)pauseState{
    if (pauseState) {
        _logicState = LOGIC_PAUSED;
    } else {
        _logicState = LOGIC_PLAYING;
    }
}

-(void)handleAmmoHitTarget:(id)ammo target:(id)target{
    if (![ammo isLive]) {
        return;
    }
    [self handleHitOrder:ammo victim:target];
}

-(void)handleOtherCollision:(id)object1 object2:(id)object2{
}

-(void)handleAmmoHitOther:(id)ammo otherObject:(id)otherObject{}

-(void)handleTargetHitOther:(id)target otherObject:(id)otherObject{}

-(void)handleTargetHitTarget:(id)target1 target2:(id)target2{}

-(void)renderWidgets{
	[_ui render];
}

-(void)loadWidgets{
    //the achievement notification dialog
    _achievementNotification = [[SFAchievementNotification alloc] initNotification];
}

-(void)updateSceneActors{
	if (![self active]) {
		return; 
	}
}

-(BOOL)activateTarget:(SF3DObject*)spawnPoint{
    SFTarget *target = [self getSpawnableTarget];
    if (!target) {
        sfDebug(TRUE, "Unable to activate target at this time - none available");
        return NO;
    }
    id targetInfo = [self objectInfoForKey:@"targets"];
    [[target logic] setMovementInfo:targetInfo];
    //if the game mode has an objective, push that objective first
    NSString *objectiveName = [[[self scene] objectInfoForKey:@"gameMode"] objectForKey:@"targetObjective"];
    if (objectiveName) {
        id objective = [[self scene] getItem:objectiveName itemClass:[SF3DObject class]];
        if (objective) {
            //we do!  give them thirst!
            [[target logic] pushObjective:objective objectiveAction:objectiveActionAttack];
        }
    }
    //if the spawnpoint has an objective, set that objective in the target - but make it so that 
    //immediately after, we move on - i.e. forget the objective and continue as normal
    objectiveName = [[spawnPoint getBlenderInfo:@"objective"] retain];
    if (objectiveName) {
        id spawnObjective = [[self scene] getItemFromMemory:objectiveName itemClass:[SF3DObject class]];
        [[target logic] pushObjective:spawnObjective objectiveAction:objectiveActionMoveOn];
        [objectiveName release];
    }
	[[self scene] spawnObject:target withTransform:[spawnPoint transform] adjustZAxis:YES];
    ++_activeTargetCount;
    return YES;
}

-(void)deactivateTarget{
    --_activeTargetCount;
}

-(void)addTarget{
    //if we can get a target we contine, otherwise, skip
    SFTarget *target = [self getSpawnableTarget];
    sfAssert(target!=nil, "Unable to add target - not available");
    [_targets addObject:target];
}

-(SF3DObject*)getSpawnableTarget{
    //children to override
    return nil;
}
						 
-(void)makeSceneChoices{
#if ONE_CHOICE_PER_PASS
	//tell all the actors to think about what they are doing
    //but not all at once - one per pass in sequence
    static int targetId = -1;
    //move to a new target each frame - so we aren't overtaxing
    int targetCount = [_targets count];
    if (!targetCount) {
        return;
    }
    targetId = (targetId + 1) % [_targets count];
    id target = [[_targets objectAtIndex:targetId] retain];
    if (![target updateAI]) {
        [self spawnRandomTarget];
    }
    [target release];
#else
    //in this case we check up ALL targets every pass
    for (SFTarget *target in _targets) {
        if (![target updateAI]) {
            [self spawnRandomTarget];
        }   
    }
#endif
}

-(void)spawnRandomTarget{
	//children to override or this might go into an infinite loop!
}

-(void)updateSceneMain{
	//called to tell us to progress the game as it should
	if (![self active]) {
		return;
	}
	
	if (([self getTimeLeft] <= 0) and (!_timeUpFired)) {
		_timeUpFired = true;
		[self timeUpEvent];
	}	 
    
	[self makeSceneChoices];
}

-(void)updateScene{
	[self updateSceneMain]; 
}

-(void)timeUpEvent{
	//fires when the timer reaches zero
}

-(SF3DObject*)selectRandomWayPoint{
	//when doing computer ai movement, this will allow them to
	//move around, seemingly doing their own thing at random
	return [SFUtils getRandomFromArray:_wayPoints];
}

-(SF3DObject*)selectRandomStartPoint{
	return [SFUtils getRandomFromArray:_startPoints];
}

-(void)incNextSpawnPoint{
	++_nextSpawnPoint;
	if (_nextSpawnPoint >= [_spawnPoints count]) {
		_nextSpawnPoint = 0;
	}
}

-(SF3DObject*)selectRandomUnusedSpawnPoint{
	[self incNextSpawnPoint];
	return [_spawnPoints objectAtIndex:_nextSpawnPoint];
    //return [SFUtils getRandomFromArray:_spawnPoints];
}

-(SF3DObject*)selectRandomSpawnPoint{
	return [SFUtils getRandomFromArray:_spawnPoints];
}

+(int)getMinimumTargetCount{
	//if this is non-zero, every time it's time to make scene choices, 
	//new targets will spawn at random spawn points until the number
	//of targets is made up again
	return 0; //children override
}

-(BOOL)sceneHasInfiniteAmmo{
	//for relaxer games/levels, we may want to allow infinite ammo
	//or perhaps infinite ammo but the challenge lies elsewhere
	return [[self class] sceneHasInfiniteAmmo];
}

+(BOOL)sceneHasInfiniteAmmo{
	//for relaxer games/levels, we may want to allow infinite ammo
	//or perhaps infinite ammo but the challenge lies elsewhere
	return YES;
}

-(void)dispatchTouchEvents:(SFTouchEvent*)touchEvent{
    //figure out whether we are in landscape or portrait mode and send the
    //correct modified touch
    vec2 localTouchPos = [touchEvent getFirstTouchPosLandscape];
	[_ui processTouchEvent:touchEvent localTouchPos:localTouchPos];
}

-(void)dispatchOtherEvents:(NSArray *)otherEvents{
    //at the moment we just use this for GREE notifications
//    for (OFNotificationData *notificationData in otherEvents) {
//        switch (notificationData.notificationCategory) {
//            case kNotificationCategoryHighScore:
//                if (!_highScoreNotified) {
//                    _notifyHighScore = YES;
//                    [self showAnyAchievements];
//                }
//                break;
//            case kNotificationCategoryAchievement:
//                //well, let's leave this for now...
//                break;
//            default:
//                break;
//        }
//    }
}

/////////////////
//widget delegate
/////////////////

-(void)widgetWillShow:(id)widget{
    sfDebug(DEBUG_WIDGET_DELEGATE, "%s will show", [widget UTF8Description]);
}

-(void)widgetDidShow:(id)widget{
    sfDebug(DEBUG_WIDGET_DELEGATE, "%s did show", [widget UTF8Description]);    
}

-(void)widgetWillHide:(id)widget{
    sfDebug(DEBUG_WIDGET_DELEGATE, "%s will hide", [widget UTF8Description]);    
}

-(void)widgetDidHide:(id)widget{
    sfDebug(DEBUG_WIDGET_DELEGATE, "%s did hide", [widget UTF8Description]);    
}

-(void)widgetCallback:(id)widget reason:(unsigned char)reason{
    sfDebug(DEBUG_WIDGET_DELEGATE, "%s event %s", [widget UTF8Description], [SFWidgetShade translateCallback:reason]);
    switch (reason) {
        case CR_MENU_BACK:
            [_ui popMenu];
            break;
        default:
            break;
    }
}

-(void)widgetGotScenePick:(id)widget pickObject:(id)pickObject pickVector:(vec3)pickVector{
    sfDebug(DEBUG_WIDGET_DELEGATE, "%s got scene pick", [widget UTF8Description]);
}

-(void)widgetWasTouched:(id)widget touchKind:(unsigned char)touchKind dragRect:(CGRect)dragRect{
    sfDebug(DEBUG_WIDGET_DELEGATE, "%s touched %s", [widget UTF8Description], [SFWidgetShade translateCallback:touchKind]);
    if ((widget == _ui) and (touchKind == CR_WIDGET_ACTIVATED)) {
        //perform a scene pick because the back layer has been touched
        vec3 pickVector;
        SF3DObject *pickedObject = [[self scene] pick:Vec2Make(dragRect.origin.x + dragRect.size.width, 
                                                               dragRect.origin.y + dragRect.size.height) vectorOut:&pickVector];
        [_ui sceneWasPicked:pickedObject pickVector:pickVector];
    } else {
        switch (touchKind) {
            case CR_TOUCH_TAP_UP:
                if ((widget == _achievementNotification) and (ABS(dragRect.size.width) >= REASONABLE_DRAG_WIDTH)) {
                    [self showAnyAchievements];
                }
                break;
            default:
                break;
        }       
    }

}

////////////////////////
//SFScoreDisplayDelegate
////////////////////////

-(void)scoreWillChange:(float)oldScore newScore:(float)newScore{

}

-(void)scoreDidChange:(float)newScore oldScore:(float)oldScore{
    
}

-(void)perfectStreakDidChange:(float)newStreak oldStreak:(float)oldStreak topStreak:(float)topStreak{
}

//////////////////////
//SFLevelGradeDelegate
//////////////////////

-(void)gradeWillChange:(float)oldGrade newGrade:(float)newGrade{

}

-(void)gradeDidChange:(float)newGrade oldGrade:(float)oldGrade{
    [self showAnyAchievements];
}

//////////////////
//SFPlayerDelegate
//////////////////

-(void)playerHealthWillChange:(float)oldHealth newHealth:(float)newHealth{

}

-(void)playerHealthDidChange:(float)newHealth oldHealth:(float)oldHealth{

}

-(void)playerWillDie{

}

-(void)playerDidDie{

}

-(void)playerWillChangeWeapons:(id)player currentWeapon:(id)currentWeapon newWeapon:(id)newWeapon{
    
}

-(void)playerDidChangeWeapons:(id)player currentWeapon:(id)currentWeapon oldWeapon:(id)oldWeapon{

}

-(void)playerGotWeapon:(id)player weapon:(id)weapon{
    //precache it!
    [weapon precache];
}

-(void)playerUnlockedAchievement:(NSString*)resourceId achievementInfo:(NSDictionary*)achievementInfo{
    [_achievementsUnlocked push:resourceId];
}

@end
