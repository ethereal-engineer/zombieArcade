//
//  SFScoreManager.h
//  ZombieArcade
//
//  Created by Adam Iredale on 23/11/09.
//  Copyright 2009 Stormforge Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SFGameSingleton.h"
#import "SFProtocol.h"

#define DEBUG_SFSCOREMANAGER 1

typedef enum {
	SF_SCORE_FIRED_WEAPON,
	SF_SCORE_HIT_TARGET_ENEMY,
	SF_SCORE_HIT_TARGET_FRIENDLY,
	SF_SCORE_HIT_WORLD
} SF_SCORE_ACTION;

@interface SFScoreManager : SFGameSingleton <PScoreManager> {
	//the scene logic lets the score manager know about events
	//and they are scored in a certain way
	//the score label rendering process continually queries
	//this object for the latest score
	float _currentScore;
	float _currentMultiplier;
	float _currentGrade;
	float _targetsHit_Enemy;
	float _targetsHit_Friendly;
	float _shotsFired;
	float _shotsMissed;
    float _longestPerfectStreak, _currentPerfectStreak;
    float _levelIdentifier;
    NSMutableDictionary *_lockedAchievements;
    NSMutableArray *_achievements;
    BOOL _achievementsProcessed, _assessGrade;
    id<SFScoreDisplayDelegate> _displayDelegate;
    id<SFWeaponDelegate> _weaponDelegate;
    id<SFPlayerDelegate> _playerDelegate;
    id<SFLevelGradeDelegate> _gradeDelegate;
}
-(void)loadAchievements;
-(void)print;
-(void)forceGradeChange:(float)grade;
-(void)breakPerfectStreak;
-(void)updatePerfectStreak;
-(void)setScoreDisplayDelegate:(id<SFScoreDisplayDelegate>)delegate;
-(void)setLevelGradeDelegate:(id<SFLevelGradeDelegate>)delegate;
-(void)setPlayerDelegate:(id<SFPlayerDelegate>)delegate;
-(void)setWeaponDelegate:(id<SFWeaponDelegate>)delegate;
-(void)compileStatistics;

@end
