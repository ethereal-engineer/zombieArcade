//
//  SFProtocol.h
//  ZombieArcade
//
//  Created by Adam Iredale on 16/11/09.
//  Copyright 2009 Stormforge Software. All rights reserved.
//

#import "btBulletCollisionCommon.h"
#import "SFVec.h"

typedef enum{
    rrRenderedOk,
    rrDroppedFrame,
    rrLoadedDelta,
    rrWaitingForSound,
    rrChangingScenes,
    rrWaitingToLoad
} SFRenderResult;

@protocol PObject <NSObject>
-(void)cleanUp;
@end

@protocol PPrecachable <PObject>
-(void)precache;
@end

@protocol SFIpoDelegate <PObject>
-(void)ipoStopped:(id)ipo;
@end

@protocol SFCameraDelegate <PObject>
-(void)cameraWillMove:(id)camera;
-(void)cameraDidMove:(id)camera;
@end

@protocol SFWidgetDelegate <PObject>
-(void)widgetWillShow:(id)widget;
-(void)widgetDidShow:(id)widget;
-(void)widgetWillHide:(id)widget;
-(void)widgetDidHide:(id)widget;
-(void)widgetCallback:(id)widget reason:(unsigned char)reason;
-(void)widgetWasTouched:(id)widget touchKind:(unsigned char)touchKind dragRect:(CGRect)dragRect;
-(void)widgetGotScenePick:(id)widget pickObject:(id)pickObject pickVector:(vec3)pickVector;
@end

@protocol SFWeaponDelegate <PObject>
-(void)weaponDidFire:(id)weapon;
-(void)weaponDidDryFire:(id)weapon;
-(void)weaponDidStartReloading:(id)weapon reloadTime:(float)reloadTime;
-(void)weaponDidFinishReloading:(id)weapon;
@end

@protocol SFAmmoDelegate <PObject>
-(void)ammoMissedTarget:(id)ammo firedFromWeapon:(id)weapon;
-(void)ammoHitTarget:(id)ammo target:(id)target firedFromWeapon:(id)weapon;
@end

@protocol SFScoreDisplayDelegate <PObject>
-(void)scoreWillChange:(float)oldScore newScore:(float)newScore;
-(void)scoreDidChange:(float)newScore oldScore:(float)oldScore;
-(void)perfectStreakDidChange:(float)newStreak oldStreak:(float)oldStreak topStreak:(float)topStreak;
@end

@protocol SFLevelGradeDelegate <PObject>
-(void)gradeWillChange:(float)oldGrade newGrade:(float)newGrade;
-(void)gradeDidChange:(float)newGrade oldGrade:(float)oldGrade;
@end

@protocol SFPlayerDelegate <PObject>
-(void)playerHealthWillChange:(float)oldHealth newHealth:(float)newHealth;
-(void)playerHealthDidChange:(float)newHealth oldHealth:(float)oldHealth;
-(void)playerWillDie;
-(void)playerDidDie;
-(void)playerWillChangeWeapons:(id)player currentWeapon:(id)currentWeapon newWeapon:(id)newWeapon;
-(void)playerDidChangeWeapons:(id)player currentWeapon:(id)currentWeapon oldWeapon:(id)oldWeapon;
-(void)playerGotWeapon:(id)player weapon:(id)weapon;
-(void)playerUnlockedAchievement:(NSString*)resourceId achievementInfo:(NSDictionary*)achievementInfo;
@end

@protocol PGameEngine <PObject>
@end

@protocol PGameInfo <PObject>
-(int)getLevelCount;
-(id)getLevelDictionary:(int)levelIndex;
-(id)getDefaultSettingsDictionary;
-(id)getMainMenuDictionary;
-(id)getMusicArray:(NSString*)musicKind;
-(id)getLevelArray;
-(id)getResourceArray:(Class)itemClass;
-(id)getGameTextArray:(NSString*)textKind;
-(id)getGameModeArray;
-(id)getAchievementDictionary;
-(id)getGREEInfo:(id)infoKey;
-(id)getWeaponDictionary:(NSString*)weaponName;
-(id)getWeaponsDictionary;
-(id)getDefaultWeaponDictionary;
-(id)getFontDictionary:(NSString *)fontName size:(int)size;
-(int)getCreditCount;
-(CGRect)getImageOffset:(NSString*)imageName;
-(id)getMovieList:(NSString*)movieListName;
-(id)getCreditString:(int)creditIndex;
-(NSDictionary*)getAtlasInfo:(NSString*)atlasName;
-(id)getAchievementInfo:(NSString*)achievementId;
-(id)getGameText:(NSString*)identifier;
@end

@protocol PAtlasManager <PObject>
//returns a texture atlas, fully indexed
-(id)loadAtlas:(NSString*)atlasName;
//to free up memory we can unload atlases at any time
-(void)unloadAtlas:(NSString*)atlasName;
@end

@protocol PResource <PObject>
@end

@protocol PScene <PResource>
-(id)camera;
-(float)timeToRenderPasses:(float)seconds;
-(BOOL)sfPhysicsCollisionCallback:(btManifoldPoint)cp 
                          colObj0:(const btCollisionObject*)colObj0 
                          partId0:(int)partId0 
                           index0:(int)index0 
                          colObj1:(const btCollisionObject*)colObj1 
                          partId1:(int)partId1 
                           index1:(int)index1;
-(float)frameRate;
-(void)spawnObject:(id)spwnObj withTransform:(void*)transform adjustZAxis:(BOOL)adjustZAxis;
-(void)appendSceneObject:(id)object;
@end

@protocol PSceneLogic <PObject, SFCameraDelegate, SFWidgetDelegate, SFScoreDisplayDelegate, SFLevelGradeDelegate, SFPlayerDelegate>
-(int)getLoadPartCount;
-(void)loadPart:(NSNumber *)loadPart;
-(BOOL)sceneHasInfiniteAmmo;
-(void)stop;
-(void)play;
-(void)pause:(BOOL)pauseState;
-(void)renderWidgets;
-(void)updateSceneActors;
-(void)updateScene;
-(void)makeSceneChoices;
-(void)dispatchTouchEvents:(id)touchEvent;
-(id)selectRandomWayPoint;
-(id)selectRandomStartPoint;
-(id)selectRandomSpawnPoint;
-(void)handleObjectCollision:(id)object1 object2:(id)object2;
-(void)autoSaveScene;
-(void)dispatchOtherEvents:(NSArray*)otherEvents;
-(void)achievementsSynchronised;
-(float)extraRagdollTime;
@end

@protocol PSceneManager <PObject>
-(id<PScene>)currentScene;
-(id<PSceneLogic>)currentLogic;
-(void)changeScene:(NSDictionary*)newSceneInfo;
-(SFRenderResult)render:(BOOL)soundAvailable 
         allowLoadDelta:(BOOL)allowLoadDelta 
            touchEvents:(NSArray*)touchEvents
            otherEvents:(NSArray*)otherEvents;
-(void)processOtherEvents:(NSArray*)otherEvents;
@end

@protocol PScoreObject <PObject>
-(float)getScoreMultiplier;
@end

@protocol PResourceManager <PObject>
-(void)removeItem:(NSObject *)item;
-(id)getItem:(NSString*)itemName itemClass:(Class)itemClass tryLoad:(BOOL)tryLoad dictionary:(NSDictionary*)dictionary;
-(id)getItem:(NSString*)itemName itemClass:(Class)itemClass tryLoad:(BOOL)tryLoad;
-(id)getItem:(NSString*)itemName itemClass:(Class)itemClass;
-(NSArray*)getItemGroup:(NSString*)groupPrefix itemClass:(Class)itemClass;
-(id)getResourceWithDictionary:(NSDictionary*)resourceInfo;
-(void)removeResource:(id)resourceKey;
-(id)newOnceOffItemFromDisk:(NSString*)filename itemClass:(Class)itemClass dictionary:(NSDictionary*)dictionary;
-(void)flushResources;
@end

@protocol PScoreManager <PObject, SFWeaponDelegate, SFAmmoDelegate, SFPlayerDelegate>
//this is turning into an event manager!
-(void)print;
-(void)forceGradeChange:(int)grade;
-(void)reset:(id)newScene;
-(float)currentScore;
-(float)currentGrade;
-(void)levelIsOver;
-(float)getGradeScaledAmount:(float)amount delta:(float)delta;
-(void)setScoreDisplayDelegate:(id<SFScoreDisplayDelegate>)delegate;
-(void)setLevelGradeDelegate:(id<SFLevelGradeDelegate>)delegate;
-(void)setPlayerDelegate:(id<SFPlayerDelegate>)delegate;
-(void)setWeaponDelegate:(id<SFWeaponDelegate>)delegate;
-(void)compileAndSave:(BOOL)autoSaved;
-(void)userAuthenticated;
@end
