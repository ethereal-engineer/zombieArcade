//
//  SFScoreManager.m
//  ZombieArcade
//
//  Created by Adam Iredale on 23/11/09.
//  Copyright 2009 Stormforge Software. All rights reserved.
//

#import "SFScoreManager.h"
#import "SFDefines.h"
#import "SFUtils.h"
#import "SFDebug.h"
#import "SF3DObject.h"
#import "SFGameEngine.h"

#define ZA_MAX_GRADE 10  //generalise these later
#define ZA_EXTRA_ZOMBIES_PER_GRADE 5
#define ZA_BASE_ZOMBIES_PER_GRADE 25
#define ENABLE_LEADERBOARDS 1
#define NIGHTMARE_BONUS_MULTIPLIER 3

typedef enum {
    RC_LT = 0,
    RC_LE,
    RC_EQ,
    RC_GE,
    RC_GT,
    RC_NE
} REQUIREMENT_COMPARISON;

static SFScoreManager *gSFScoreManager = NULL;

@interface SFScoreManager ()

@property (nonatomic, readonly) SFPlayer *localPlayer;

@end

@implementation SFScoreManager

-(id)sceneInfo{
    return [self objectInfoForKey:@"activeScene"];
}

-(float)currentScore{
    return _currentScore;
}

-(float)currentGrade{
    return _currentGrade;
}

-(bool)canReceiveCallbacksNow{
    return YES;
}

- (SFPlayer *)localPlayer
{
    return [SFGameEngine getLocalPlayer];
}

-(void)processAchievements:(NSArray*)achievements{
    
    //syncs our achievements with game center - delayed by internet connection etc
    [_achievements addObjectsFromArray:achievements];
    
    //we can now work with the _achievements array
    //add all LOCKED items to the unlockables array
    
    BOOL localChanges = NO;
    
    NSEnumerator *objects = [_achievements objectEnumerator];
    for (GKAchievement *achievement in objects) {
        if (![achievement isCompleted]) {
            sfDebug(DEBUG_SFSCOREMANAGER, "%s is NOT unlocked", [[achievement identifier] UTF8String]);
            [_lockedAchievements setObject:achievement forKey:[achievement identifier]];
            localChanges = ([self.localPlayer lockLocalAchievement:[achievement identifier]] or localChanges);
        } else {
            sfDebug(DEBUG_SFSCOREMANAGER, "%s is unlocked", [[achievement identifier] UTF8String]);
            localChanges = ([self.localPlayer unlockLocalAchievement:[achievement identifier]] or localChanges);
        }

    }
    _achievementsProcessed = YES;
    [[[self sm] currentLogic] achievementsSynchronised];
}

- (NSArray *)combineAchievementsFromDefinitionsWithThoseAlreadyLoaded:(NSArray *)preloadedAchievements
{
    // create achievement objects for all not loaded
    NSMutableArray *combinedAchievements = [NSMutableArray arrayWithArray:preloadedAchievements];
    NSDictionary *achievementDefs = [[self gi] getAchievementDictionary];
    NSArray *loadedAchievementIds = [preloadedAchievements valueForKey:@"identifier"];
    for (id achievementKey in achievementDefs) {
        if ([loadedAchievementIds containsObject:achievementKey]) {
            continue;
        }
        GKAchievement *achievement = [[GKAchievement alloc] initWithIdentifier:achievementKey];
        [combinedAchievements addObject:achievement];
        [achievement release];
    }
    return combinedAchievements;
}

-(void)loadAchievements{
    //synch with GREE
    [GKAchievement loadAchievementsWithCompletionHandler:^(NSArray *achievements, NSError *error) {
        if (error != nil)
        {
            // handle errors
            sfDebug(TRUE, "Unable to download achievement information!");
        }
        
        NSArray *combinedAchievements = [self combineAchievementsFromDefinitionsWithThoseAlreadyLoaded:achievements];
        // process the array of achievements.
        [self processAchievements:combinedAchievements];
     
     }];
}

-(void)userAuthenticated{
    [self loadAchievements];
}

-(id)initWithDictionary:(NSDictionary*)dictionary{
	self = [super initWithDictionary:dictionary];
	if (self != nil) {
		_currentGrade = 1;
        _lockedAchievements = [[NSMutableDictionary alloc] init];
        _achievements = [[NSMutableArray alloc] init];
	}
	return self;
}

-(void)cleanUp{
    [_lockedAchievements removeAllObjects];
    [_achievements removeAllObjects];
    [_achievements release];
    [_lockedAchievements release];
    [_displayDelegate release];
    [_gradeDelegate release];
    [_playerDelegate release];
    [_weaponDelegate release];
    [super cleanUp];
}

-(float)getStatistic:(NSString*)statKind{
    id stat = [self objectInfoForKey:statKind];
    if (!stat) {
        return 0;
    }
    return [stat floatValue];
}

-(BOOL)updateLeaderboardsWithStatistic:(float)stat boards:(NSArray*)boards{
    
    //update a string list of board unique ids with this stat
    if (stat < 0.0f) {
        //don't allow 0 or negative scores through
        return NO;
    }
    for (id board in boards) {
        sfDebug(DEBUG_SFSCOREMANAGER, "Updating leaderboard %s with stat value %.2f", [board UTF8String], stat);
        GKScore *scoreReporter = [[[GKScore alloc] initWithCategory:board] autorelease];
        scoreReporter.value = lroundf(stat);
        
        [scoreReporter reportScoreWithCompletionHandler:^(NSError *error) {
            if (error != nil)
            {
                // handle the reporting error
            }
        }];
    }
    return YES;
}

-(void)updateLeaderboards:(NSDictionary*)boards{
    //the format of these is as follows - 
    //stat kind name (e.g. score or accuracy) -> array of strings (board identifiers)
    for (id statKind in boards) {
        //the statkind will refer us to one of the stats we have collected while scoring
        if (![self updateLeaderboardsWithStatistic:[self getStatistic:statKind] boards:[boards objectForKey:statKind]]){
            sfDebug(TRUE, "Bad stat value for statkind %s", [statKind UTF8String]);
        }
    }
}

-(void)updateAllLeaderboards{
    //if the game mode says to update the leaderboards, we do
    id gameMode = [[self sceneInfo] objectForKey:@"gameMode"];
    if (!gameMode) {
        return; //only score gamemode scenes
    }
    id updateLeaderboards = [gameMode objectForKey:@"updateLeaderboards"];
    if ((updateLeaderboards != nil) and ([updateLeaderboards boolValue])) {
        //ok, so let's get all the lbs we need to update with which totals...
        //gamemode leaderboards
        [self updateLeaderboards:[gameMode objectForKey:@"leaderboards"]];
        //scene-specific leaderboards
        [self updateLeaderboards:[[self sceneInfo] objectForKey:@"leaderboards"]];
    }
}

-(void)finaliseAllScoring{
    [self breakPerfectStreak]; //allow it to sum up
    [self compileStatistics]; //last compile now...
}

-(void)levelIsOver{
    //the level is over - transmit the high score to GREE for all
    //applicable categories - the level's dictionary is sent as user info
    //so we will know which to send where
#if ENABLE_LEADERBOARDS
    [self finaliseAllScoring];
    [self updateAllLeaderboards];
#endif
}

-(void)playerWasHurt:(NSNotification*)notify{
    [self breakPerfectStreak];
}


-(void)setScoreDisplayDelegate:(id<SFScoreDisplayDelegate>)delegate{
    [_displayDelegate release];
    _displayDelegate = [delegate retain];
}

-(void)setPlayerDelegate:(id<SFPlayerDelegate>)delegate{
    [_playerDelegate release];
    _playerDelegate = [delegate retain];
}

-(void)setWeaponDelegate:(id<SFWeaponDelegate>)delegate{
    [_weaponDelegate release];
    _weaponDelegate = [delegate retain];
}

-(void)setLevelGradeDelegate:(id<SFLevelGradeDelegate>)delegate{
    [_gradeDelegate release];
    _gradeDelegate = [delegate retain];
}

-(BOOL)assessGrade{
	//change the hardness of the game based on the
	//number of targets hit
	if (!_assessGrade) {
        return NO;
    }
    return ((_currentGrade < ZA_MAX_GRADE) 
			and (_targetsHit_Enemy == ((ZA_BASE_ZOMBIES_PER_GRADE * _currentGrade) + (ZA_EXTRA_ZOMBIES_PER_GRADE * (_currentGrade - 1)))));
}

-(char*)interpretComparison:(unsigned char)comparison{
    switch (comparison) {
        case 0:
            return "<";
        case 1:
            return "<=";
        case 2:
            return "==";
        case 3:
            return ">=";
        case 4:
            return ">";
        case 5:
            return "!=";
    }
    return nil;
}

-(BOOL)assessAchievementRequirement:(id)requirement{
    //the requirement is a dictionary with two entries
    //"comparison" is a number from 0 to 5 representing
    // 0 - <
    // 1 - <=
    // 2 - ==
    // 3 - >=
    // 4 - >
    // 5 - !=
    //and we switch on that to know which comparisons to do
    //gradeNumber, levelNumber, levelCount, hitCount, onlyWeapon or longestPerfectStreak
    //that way we can test all but levelCount against the current scene's states  
    
    id key = nil;
    id compareValue = nil;
    
    //get the non-comparison key
    for (id aKey in requirement) {
        if ([aKey isEqualToString:@"comparison"]) {
            continue;
        } else {
            key = [aKey retain];
            compareValue = [requirement objectForKey:key];
        }

    }
    
    sfDebug(DEBUG_SFSCOREMANAGER, 
            "Assessing achievement requirement: %s %s %f", 
            [key UTF8String],
            [self interpretComparison:[[requirement objectForKey:@"comparison"] unsignedCharValue]],
            [compareValue floatValue]);
    
    id value = [self objectInfoForKey:key];
    if (value == nil) {
        sfDebug(DEBUG_SFSCOREMANAGER, "%s comparison value not supported", [key UTF8String]);
        return NO;
    }
    
    [key release];
    
    float actualValue = [value floatValue],
    comparisonValue = [compareValue floatValue];
    
    switch ([[requirement objectForKey:@"comparison"] intValue]) {
        case RC_LT:
            return actualValue < comparisonValue;
        case RC_LE:
            return actualValue <= comparisonValue;
        case RC_NE:
            return actualValue != comparisonValue;
        case RC_GE:
            return actualValue >= comparisonValue;
        case RC_GT:
            return actualValue > comparisonValue;
        default:
            return actualValue == comparisonValue;
    }
}

-(BOOL)assessAchievementRequirements:(id)requirements{
    //expects a NSDictionary of required conditions to be
    //met for this achievement
    if (!requirements) {
        //return yes for nil requirements
        return YES;
    }
    //if all requirements check out then return yes else no
    BOOL passed = YES;
    for (id requirement in requirements) {
        passed = [self assessAchievementRequirement:requirement];
        sfDebug(DEBUG_SFSCOREMANAGER, "Passed: %u", passed);
        if (!passed) {
            break; //one failure means total failure thus far
        }
    }
    return passed;
}

-(void)assessAchievement:(NSString*)resourceId{
    sfDebug(DEBUG_SFSCOREMANAGER,"Assessing achievement number %s", [resourceId UTF8String]);
    NSDictionary *achievement = [[[self gi] getAchievementDictionary] objectForKey:resourceId];
    if (achievement) {
        if ([self assessAchievementRequirements:[achievement objectForKey:@"requirements"]]){
            //the achievement is unlock-ready - let's unlock it!
            if ([[GKLocalPlayer localPlayer] isAuthenticated]) {
                GKAchievement *achievement = [_lockedAchievements objectForKey:resourceId];
                if (achievement)
                {
                    achievement.percentComplete = 100;
                    [achievement reportAchievementWithCompletionHandler:^(NSError *error)
                     {
                         if (error != nil)
                         {
                             // Retain the achievement object and try again later (not shown).
                             sfDebug(TRUE, "Error reporting achievement!", nil);
                         }
                     }];
                    [_lockedAchievements removeObjectForKey:resourceId];
                }
            }
            [self.localPlayer unlockLocalAchievement:resourceId achievementInfo:achievement];
            sfDebug(DEBUG_SFSCOREMANAGER,"Achievement %s unlocked!", [resourceId UTF8String]);
        }
    }
}

-(id)getMasterObjectInfoKey{
    return @"activeScene";
}

-(void)compileWeaponStatistics{
    //which weapons have been used how many times - atm we are only interested
    //in "onlyWeapon" - which indicates that ONLY a certain weapon (single) has
    //been used to make all shots
    //reset onlyWeapon
    id weaponStats = [self objectInfoForKey:@"weaponShots"];
    if (!weaponStats) {
        weaponStats = [[NSMutableDictionary alloc] init];
        [self setObjectInfo:weaponStats forKey:@"weaponShots"];
    }
    [self removeObjectInfoForKey:@"onlyWeapon"];
    int weaponsUsed = 0;
    NSEnumerator *weapons = [[self.localPlayer weapons] objectEnumerator];
    for (SFWeapon *weapon in weapons){
        float shotsFired = [weapon shotsFired];
        if (shotsFired) {
            [weaponStats setObject:[NSNumber numberWithFloat:shotsFired] forKey:[weapon slotNumber]];
            if (!weaponsUsed) {
                [self setObjectInfo:[weapon slotNumber] forKey:@"onlyWeapon"];
            } else {
                [self removeObjectInfoForKey:@"onlyWeapon"];
            }
            ++weaponsUsed;
        }
    }
}

-(void)compileStatistics{
    //take all our active counters and put them in dictionary format so they can be 
    //easily tested for achievement completion
    //gradeNumber, levelNumber, levelCount, hitCount, onlyWeapon or longestPerfectStreak
    [self setObjectInfo:[NSNumber numberWithFloat:_currentGrade] forKey:@"gradeNumber"];
    [self setObjectInfo:[NSNumber numberWithFloat:_targetsHit_Enemy] forKey:@"targetTotal"];
    [self updatePerfectStreak];
    [self setObjectInfo:[NSNumber numberWithFloat:_longestPerfectStreak] forKey:@"longestStreak"];
    [self compileWeaponStatistics];
    [self setObjectInfo:[NSNumber numberWithFloat:_currentScore] forKey:@"score"];
    [self setObjectInfo:[NSNumber numberWithFloat:_levelIdentifier] forKey:@"levelNumber"];
    //levels maxed
    float levelsMaxed = 0;
    NSEnumerator *highestGrades = [[self.localPlayer highestGrades] objectEnumerator];
    for (NSNumber *grade in highestGrades) {
        if ([grade floatValue] == ZA_MAX_GRADE) {
            ++levelsMaxed;
        }
    }
    [self setObjectInfo:[NSNumber numberWithFloat:levelsMaxed] forKey:@"levelsMaxed"];
}

-(void)assessAchievements{
    //achievements are assessed at every grade change 
    //or when the player quits/dies
    
    //we cycle through the locked achievements list
    //and see if any of the achievement requirements have
    //been met
    
    [self compileStatistics];
    
    NSDictionary *assessLocked = [NSDictionary dictionaryWithDictionary:_lockedAchievements];
    
    for (id resourceId in assessLocked) {
        [self assessAchievement:resourceId];
    }
    
}

-(float)getGradeScaledAmount:(float)amount delta:(float)delta{
    float scaledAmount = amount + ((_currentGrade - 1) * delta);
    if (_currentGrade == ZA_MAX_GRADE) {
        scaledAmount += NIGHTMARE_BONUS_MULTIPLIER * delta;
    }
    return scaledAmount;
}

-(void)doAssessGrade{
	if ([self assessGrade]) {
        float oldGrade = _currentGrade,
              newGrade = _currentGrade + 1;
        [_gradeDelegate gradeWillChange:oldGrade newGrade:newGrade];
        ++_currentGrade;
        //save highest grade on each level
        [self.localPlayer saveHighestGrade:_levelIdentifier grade:_currentGrade];
        [self assessAchievements];
        [_gradeDelegate gradeDidChange:_currentGrade oldGrade:oldGrade];
	}
}

-(void)updatePerfectStreak{
    if (_currentPerfectStreak > _longestPerfectStreak) {
        _longestPerfectStreak = _currentPerfectStreak;
    }    
}

-(void)breakPerfectStreak{
    //for some reason our current perfect streak has been tarnished
    [self updatePerfectStreak];
    float oldPerfectStreak = _currentPerfectStreak;
    _currentPerfectStreak = 0;
    [_displayDelegate perfectStreakDidChange:_currentPerfectStreak 
                                   oldStreak:oldPerfectStreak 
                                   topStreak:_longestPerfectStreak];
}

-(void)print{
#if DEBUG_SFSCOREMANAGER
    [self compileStatistics];
	printf("\nSCORE SUMMARY\n");
	printf("=============\n");
	printf("Highest grade: %f\n", _currentGrade);
	printf("Shots fired: %f\n", _shotsFired);
	printf("Shots hit enemy targets: %f\n", _targetsHit_Enemy);
	printf("Shots hit friendly targets: %f\n", _targetsHit_Friendly);
	printf("Shots missed: %f\n", _shotsMissed);
	printf("Total Score: %f\n\n", _currentScore);
    printf("Longest running streak: %f\n\n", _longestPerfectStreak);
    printf("\n\n%s\n\n", [[[self objectInfo] description] UTF8String]);
#endif
}

-(void)compileAndSave:(BOOL)autoSaved{
    //compile our stats and save them to a player saved game file
    [self compileStatistics];
    NSDictionary *originalActiveScene = [[self sceneInfo] retain];
    NSMutableDictionary *activeScene = [[NSMutableDictionary alloc] initWithDictionary:originalActiveScene copyItems:YES];
    [self removeObjectInfoForKey:@"activeScene"];
    [activeScene setObject:[self objectInfo] forKey:@"savedScom"];
    [self.localPlayer addSavedGame:activeScene autoSaved:autoSaved];
    [self setObjectInfo:originalActiveScene forKey:@"activeScene"];
    [activeScene release];
    [originalActiveScene release];
}

-(void)forceGradeChange:(float)grade{
    float oldGrade = _currentGrade;
    [_gradeDelegate gradeWillChange:oldGrade newGrade:grade];
	_currentGrade = grade;
    [_gradeDelegate gradeDidChange:_currentGrade oldGrade:oldGrade];
}

-(void)reset:(id)newScene{
    //this new scene may contain previously saved data.
    //if so, we load it here
    
    float oldScore = _currentScore,
          oldGrade = _currentGrade,
          oldStreak = _currentPerfectStreak;
    [self setObjectInfo:[newScene objectInfo] forKey:@"activeScene"];
    
    [_displayDelegate scoreWillChange:oldScore newScore:0];
    [_gradeDelegate gradeWillChange:oldGrade newGrade:1];
    NSDictionary *loadedScom = [newScene objectInfoForKey:@"savedScom"];
    if (loadedScom) {
        _currentGrade = [[loadedScom objectForKey:@"gradeNumber"] floatValue];
        _targetsHit_Enemy = [[loadedScom objectForKey:@"targetTotal"] floatValue];
        _currentPerfectStreak = 0;
        _longestPerfectStreak = [[loadedScom objectForKey:@"longestStreak"] floatValue];
        _currentScore = [[loadedScom objectForKey:@"score"] floatValue];
        [self.localPlayer setHealth:[[newScene objectInfoForKey:@"playerHealth"] floatValue]];
    } else {
        //otherwise just set to 0
        _targetsHit_Enemy = 0;
        _targetsHit_Friendly = 0;
        _shotsFired = 0;
        _shotsMissed = 0;
        _currentScore = 0;
        _currentGrade = 1;
        _longestPerfectStreak = 0;
        _currentPerfectStreak = 0;
        [self.localPlayer setHealth:PLAYER_FULL_HEALTH];
    }
    //also reset the player's weapon fire counts
    [self.localPlayer resetWeaponStats:[loadedScom objectForKey:@"weaponShots"]];
    _levelIdentifier = [[[self sceneInfo] objectForKey:@"levelNumber"] floatValue];
    id gameMode = [[self sceneInfo] objectForKey:@"gameMode"];
    _assessGrade = ( (gameMode != nil) and 
                    ([gameMode objectForKey:@"assessGrade"] != nil) and 
                    ([[gameMode objectForKey:@"assessGrade"] boolValue]));
    [_displayDelegate perfectStreakDidChange:_currentPerfectStreak oldStreak:oldStreak topStreak:_longestPerfectStreak];
    [_displayDelegate scoreDidChange:_currentScore oldScore:oldScore];
    [_gradeDelegate gradeDidChange:_currentGrade oldGrade:oldGrade];
}

////////////////
//SFAmmoDelegate
////////////////

-(void)ammoMissedTarget:(id)ammo firedFromWeapon:(id)weapon{
    [self breakPerfectStreak];
    ++_shotsMissed;    
}

-(void)ammoHitTarget:(id)ammo target:(id)target firedFromWeapon:(id)weapon{
    float   newScore, 
            oldScore = _currentScore,
            oldStreak = _currentPerfectStreak;
    switch ([target objectAlliance]) {
        case oaEnemy:
            ++_targetsHit_Enemy;
            newScore = oldScore + [weapon getScoreMultiplier];
            [_displayDelegate scoreWillChange:_currentScore newScore:newScore];
             _currentScore = newScore;
            [_displayDelegate scoreDidChange:_currentScore oldScore:oldScore];
            ++_currentPerfectStreak;
            [_displayDelegate perfectStreakDidChange:_currentPerfectStreak
                                           oldStreak:oldStreak 
                                           topStreak:_longestPerfectStreak];
            [self doAssessGrade];
            break;
        case oaFriendly:
            ++_targetsHit_Friendly; //not used atm
            break;
        default:
            break;
    }
}

//////////////////
//SFWeaponDelegate
//////////////////

-(void)weaponDidFire:(id)weapon{
    //the weapon has fired
    //keep a list of which weapons fired how many rounds in a scene
    //for achievements etc
    ++_shotsFired; //all weapons
    [_weaponDelegate weaponDidFire:weapon];
}

//relay it

-(void)weaponDidDryFire:(id)weapon{
    [_weaponDelegate weaponDidDryFire:weapon];
}

-(void)weaponDidStartReloading:(id)weapon reloadTime:(float)reloadTime{
    [_weaponDelegate weaponDidStartReloading:weapon reloadTime:reloadTime];
}

-(void)weaponDidFinishReloading:(id)weapon{
    [_weaponDelegate weaponDidFinishReloading:weapon];
}

//////////////////
//SFPlayerDelegate
//////////////////

-(void)playerHealthWillChange:(float)oldHealth newHealth:(float)newHealth{
    [_playerDelegate playerHealthWillChange:oldHealth newHealth:newHealth];
}

-(void)playerHealthDidChange:(float)newHealth oldHealth:(float)oldHealth{
    if (oldHealth > newHealth) {
        [self breakPerfectStreak];
    }
    [_playerDelegate playerHealthDidChange:newHealth oldHealth:oldHealth];
}

-(void)playerWillDie{
    [_playerDelegate playerWillDie];
}

-(void)playerDidDie{
    [_playerDelegate playerDidDie];
}

-(void)playerWillChangeWeapons:(id)player currentWeapon:(id)currentWeapon newWeapon:(id)newWeapon{
    [_playerDelegate playerWillChangeWeapons:player currentWeapon:currentWeapon newWeapon:newWeapon];
}

-(void)playerDidChangeWeapons:(id)player currentWeapon:(id)currentWeapon oldWeapon:(id)oldWeapon{
    [_playerDelegate playerDidChangeWeapons:player currentWeapon:currentWeapon oldWeapon:oldWeapon];
}

-(void)playerGotWeapon:(id)player weapon:(id)weapon{
    [_playerDelegate playerGotWeapon:player weapon:weapon];
}

-(void)playerUnlockedAchievement:(NSString *)resourceId achievementInfo:(NSDictionary *)achievementInfo{
    [_playerDelegate playerUnlockedAchievement:resourceId achievementInfo:achievementInfo];
}

+(SFGameSingleton**)getGameSingletonPointer{
	return &gSFScoreManager;
}

@end
