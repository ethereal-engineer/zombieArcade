//
//  SFPlayer.h
//  ZombieArcade
//
//  Created by Adam Iredale on 11/11/09.
//  Copyright 2009 Stormforge Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SFGameObject.h"
#import "SFWeapon.h"
#import <GameKit/GameKit.h>

#define DEBUG_SFPLAYER 0
#define PLAYER_FULL_HEALTH 100.0f

@interface SFPlayer : SFGameObject {
	//the player - a game always has at least one, right?
	//in the future I might break this up into shooterplayer
	//and other classes but for now I am just assuming that
	//all players are shooter style players
	NSMutableDictionary *_weapons; //the weapons our hero has
	SFWeapon *_currentWeapon; //the weapon currently equipped
	float _currentHealth;
	BOOL _isDead;
    id<SFPlayerDelegate> _delegate;
    NSMutableArray *_localAchievements;
    NSMutableDictionary *_savedGames, *_highestGrades;
    GKLocalPlayer *_gkLocalPlayer;
}
//equip your weapon
-(void)equipWeapon:(id)weapon;

//the game giveth
-(void)giveWeapon:(id)weaponName;

//the game taketh
-(void)stripWeapon:(id)weapon;

-(void)resetWeaponStats:(NSDictionary*)weaponShotsBySlot;

-(BOOL)unlockLocalAchievement:(NSString*)resourceId;
-(BOOL)unlockLocalAchievement:(NSString*)resourceId achievementInfo:(NSDictionary*)achievementInfo;
-(BOOL)lockLocalAchievement:(NSString*)resourceId;
-(BOOL)achievementIsUnlocked:(NSString*)resourceId;
-(void)giveUnlockedWeapons;

-(BOOL)hasSeenHelp:(id)helpCategory;
-(void)setHasSeenHelp:(id)helpCategory;

-(SFWeapon*)currentWeapon;
-(id)weapons;
-(void)addSavedGame:(NSDictionary*)compiledScomData autoSaved:(BOOL)autoSaved;
-(void)deleteSavedGame:(NSDictionary*)savedGame;
-(NSMutableDictionary*)savedGames;
-(void)setHealth:(float)health;

-(void)saveHighestGrade:(float)levelIdentifier grade:(float)grade;
-(NSMutableDictionary*)highestGrades;

@end
