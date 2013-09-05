//
//  SFPlayer.m
//  ZombieArcade
//
//  Created by Adam Iredale on 11/11/09.
//  Copyright 2009 Stormforge Software. All rights reserved.
//

#import "SFPlayer.h"
#import "SFDefines.h"
#import "SFUtils.h"
#import "SFTarget.h"
#import "SFDebug.h"
#import "SFSettingManager.h"

#define INSTANT_DEATH 0 //die as soon as a zombie touches you
#define BYPASS_UNLOCKING 0
@implementation SFPlayer

-(SFWeapon*)currentWeapon{
    return _currentWeapon;
}

-(NSMutableDictionary*)highestGrades{
    if (!_highestGrades) {
        _highestGrades = [self objectInfoForKey:@"highestGrades" useMasterInfo:NO createOk:NO];
        if (!_highestGrades) {
            _highestGrades = [[NSMutableDictionary alloc] init];
            [self setObjectInfo:_highestGrades forKey:@"highestGrades"];
        }
    }
    return _highestGrades;
}

-(void)saveHighestGrade:(float)levelIdentifier grade:(float)grade{
    //keep track of only the highest for each level id
    NSNumber *levelGrade = [_highestGrades objectForKey:[NSNumber numberWithFloat:levelIdentifier]];
    if (!levelGrade or ([levelGrade floatValue] < grade)) {
        [_highestGrades setObject:[NSNumber numberWithFloat:grade] forKey:[NSNumber numberWithFloat:levelIdentifier]];
    }
}

-(NSMutableArray*)localAchievements{
    if (!_localAchievements) {
        _localAchievements = [self objectInfoForKey:@"localAchievements" useMasterInfo:NO createOk:NO];
        if (!_localAchievements) {
            _localAchievements = [[NSMutableArray alloc] init];
            [self setObjectInfo:_localAchievements forKey:@"localAchievements"];
        }
    }
    return _localAchievements;
}

-(id)addWeaponFromDictionary:(id)weaponDictionary{
    //add it only if we don't already have it
    SFWeapon *newWeapon = [_weapons objectForKey:[weaponDictionary objectForKey:@"slotNumber"]];
    if (newWeapon != nil) {
        return newWeapon;
    }
    newWeapon = [[SFWeapon alloc] initWithDictionary:weaponDictionary];
    [_weapons setObject:newWeapon forKey:[newWeapon slotNumber]];
    [newWeapon release];
    return newWeapon;
}

-(void)giveUnlockedWeapons{
    id weapons = [[self gi] getWeaponsDictionary];
    for (id weapon in weapons) {
        id weaponInfo = [weapons objectForKey:weapon];
        NSString *resourceId = [weaponInfo objectForKey:@"achievementId"];
        if ([self achievementIsUnlocked:resourceId]) {
            [self addWeaponFromDictionary:weaponInfo];
        }
    }
}

-(id)seenHelpInfo{
    return [self objectInfoForKey:@"seenHelpInfo" useMasterInfo:NO createOk:YES];
}

-(BOOL)hasSeenHelp:(id)helpCategory{
    //return true if the player has seen this help category before
    //we use the user defaults to save if this is the case or not
//    return [[self seenHelpInfo] objectForKey:helpCategory] != nil;
    return YES; // never autoshow help - it's boring
}

-(void)setHasSeenHelp:(id)helpCategory{
    //mark this help category as seen so we don't display it again
    //automatically
    [[self seenHelpInfo] setObject:@"SEENIT" forKey:helpCategory];
}

-(void)saveToFile:(NSString *)fileName{
    //save our player dictionary for later use
    NSData* encoded = [NSKeyedArchiver archivedDataWithRootObject:[self objectInfo]];
    [SFSettingManager saveObject:@"StormforgePlayerDictionary" settingValue:encoded];
    sfDebug(DEBUG_SFPLAYER, "Saved Player Dictionary:%s", [[[self objectInfo] description] UTF8String]);
    [super saveToFile:fileName];
}

-(BOOL)achievementIsUnlocked:(NSString *)resourceId{
#if BYPASS_UNLOCKING
    return YES;
#endif
    sfDebug(TRUE, "Checking unlock status for %s", [resourceId UTF8String]);
    return ((resourceId == nil) or ([[self localAchievements] indexOfObject:resourceId] != NSNotFound));
}

-(BOOL)lockLocalAchievement:(NSString *)resourceId{
    NSMutableArray *localAchievements = [self localAchievements];
    int identicalIndex = [localAchievements indexOfObject:resourceId];
    if (identicalIndex != NSNotFound) {
        [localAchievements removeObjectAtIndex:identicalIndex]; 
        return YES;
    }
    return NO;
}

-(BOOL)unlockLocalAchievement:(NSString*)resourceId achievementInfo:(NSDictionary*)achievementInfo{
    NSMutableArray *localAchievements = [self localAchievements];
    if ([localAchievements indexOfObject:resourceId] == NSNotFound) {
        [localAchievements addObject:resourceId];
        NSDictionary *achievement = achievementInfo;
        if (!achievement) {
            //no info passed - go get it
            achievement = [[self gi] getAchievementInfo:resourceId];
        }
        //tell the delegate first then act on it
        [_delegate playerUnlockedAchievement:resourceId achievementInfo:achievement];
        //we have just unlocked this - what to do with it?
        //presently only interested in weaponry
        NSString *kind = [achievement objectForKey:@"kind"];
        if ([kind isEqualToString:@"weapon"]) {
            //weaponry added
            [self giveWeapon:[achievement objectForKey:@"objectName"]];
        }
        return YES;
    }
    return NO;
}

-(BOOL)unlockLocalAchievement:(NSString *)resourceId{
    return [self unlockLocalAchievement:resourceId achievementInfo:nil];
}

-(NSMutableDictionary*)savedGames{
    if (!_savedGames){
        _savedGames = [self objectInfoForKey:@"savedGames" useMasterInfo:NO createOk:YES];
    }
    return _savedGames;
}

-(void)deleteSavedGame:(id)saveKey{
    //remove a saved game from our list
    [[self savedGames] removeObjectForKey:saveKey];
    [self doSaveToFile];
}

-(void)addSavedGame:(NSDictionary*)compiledScomData autoSaved:(BOOL)autoSaved{
    //save the scom data with the date and time and the current health level
    //and whether or not it was autosaved (due to interruption)
    NSMutableDictionary *newSavedGame = [[NSMutableDictionary alloc] initWithDictionary:compiledScomData copyItems:YES];
    NSDate *saveDate = [NSDate dateWithTimeIntervalSinceNow:0];
    [newSavedGame setObject:saveDate forKey:@"timestamp"];
    [newSavedGame setObject:[NSNumber numberWithBool:autoSaved] forKey:@"autoSaved"];
    [newSavedGame setObject:[NSNumber numberWithFloat:_currentHealth] forKey:@"playerHealth"];
    [[self savedGames] setObject:newSavedGame forKey:saveDate];
    [newSavedGame release];
    //for data safety, save when this happens
    [self doSaveToFile];
}

-(void)resetWeaponStats:(NSDictionary*)weaponShotsBySlot{
    //set all the fire counts to 0 or loaded value
    NSEnumerator *weapons = [_weapons objectEnumerator];
    for (SFWeapon *weapon in weapons) {
        [weapon setShotsFired:[[weaponShotsBySlot objectForKey:[weapon slotNumber]] floatValue]];
    }
}

-(void)loadFromFile:(NSString*)fileName{
	//after we are init'ed we load
    [super loadFromFile:fileName];
	//add our saved entried into (and overwrite) our dictionary
    NSData* encoded = [SFSettingManager loadObject:@"StormforgePlayerDictionary"];
    if (encoded) {
        id playerDictionary = [[NSKeyedUnarchiver unarchiveObjectWithData:encoded] retain];
        //check that this dictionary is compatible with the app
        [[self objectInfo] addEntriesFromDictionary:playerDictionary];
        sfDebug(DEBUG_SFPLAYER, "Loaded Player Dictionary:%s", [[playerDictionary description] UTF8String]);
        [playerDictionary release];
    }
    [self giveUnlockedWeapons];
}

- (id)initWithDictionary:(NSDictionary *)dictionary
{
	self = [super initWithDictionary:dictionary];
	if (self != nil) {
        _delegate = [self scom];
		_weapons = [[NSMutableDictionary alloc] init];
		_currentHealth = PLAYER_FULL_HEALTH;
		[self setAutoSave:YES];
        _gkLocalPlayer = [GKLocalPlayer localPlayer];
        [_gkLocalPlayer authenticateWithCompletionHandler:^(NSError *error) {
            if (_gkLocalPlayer.isAuthenticated)
            {
                // Perform additional tasks for the authenticated player.
                [[self scom] userAuthenticated];
            }
        }];
	}
	return self;
}

-(void)cleanUp{
    _gkLocalPlayer = nil;
    [_currentWeapon release];
    [_weapons release];
    [_delegate release];
    [super cleanUp];
}

-(id)weapons{
    //returns the player's weapons
    return _weapons;
}

-(id)defaultWeapon{
    return [_weapons objectForKey:[NSNumber numberWithInt:0]];
}

-(void)equipWeapon:(id)weapon{
    [_delegate playerWillChangeWeapons:self currentWeapon:_currentWeapon newWeapon:weapon];
	//gets a weapon from the weapon stash we have 
	//and makes it the current weapon, playing the
	//cock sound for it in the meantime
    if (!weapon) {
        weapon = [self defaultWeapon];
    }
    //if this is the current weapon then we do nothing!
    if (weapon == _currentWeapon) {
        return;
    }
    if (_currentWeapon) {
        //if we have a weapon out already and we are equipping a different weapon, we
        //must remove all the original weapon's ammo from the scene (if it has any)
        //so that if we re-equip the same weapon it doesn't run out of ammo
        //and so that the scene doesn't get too render-hard
        [_currentWeapon cleanSceneAmmo];
    }
    [_currentWeapon release];
	SFWeapon *oldWeapon = [_currentWeapon retain];
    _currentWeapon = nil;
	[weapon draw];
	[weapon reload:YES]; //silent reload - for shag ;)
	_currentWeapon = [weapon retain];
    [_delegate playerDidChangeWeapons:self currentWeapon:_currentWeapon oldWeapon:oldWeapon];
    [oldWeapon release];
}

-(void)giveWeapon:(id)weaponName{
	//give the player this weapon class
	//if we already have this weapon then we increase our
	//ammo for that weapon by the default ammo for that weapon
	//because we are stealing dickweeds like freeman
	
	SFWeapon *newWeapon = [self addWeaponFromDictionary:[[[self gi] getWeaponsDictionary] objectForKey:weaponName]];

    [_delegate playerGotWeapon:self weapon:newWeapon];
    
	//if this is our first weapon then equip it
    [self equipWeapon:newWeapon];
}

-(void)hurt:(float)damageAmount inflictor:(id)inflictor{
	if (damageAmount == 0) {
		return;
	}
    [self setHealth:_currentHealth - damageAmount];
#if DEBUG_SFPLAYER
	sfDebug(TRUE, "Player hurt by %s - health now %.2f", [[inflictor name] UTF8String], _currentHealth);
#endif
}

-(void)setHealth:(float)health{
    float oldHealth = _currentHealth;
    [_delegate playerHealthWillChange:_currentHealth newHealth:health];
	_currentHealth= health;
    _isDead = NO;
    [_delegate playerHealthDidChange:_currentHealth oldHealth:oldHealth];    
}

-(void)die:(id)killer{
    [_delegate playerWillDie];
	_isDead = YES;
	_currentHealth = 0.0f;
#if DEBUG_SFPLAYER
	sfDebug(TRUE, "Player was killed by %s.", [[killer name] UTF8String]);
#endif
	[_delegate playerDidDie];
}

+(BOOL)takesDamageFrom:(Class)attackerClass{
    return ([attackerClass isSubclassOfClass:[SFTarget class]]);
}

-(void)takeDamage:(float)damageAmount fromInflictor:(id)inflictor{
#if INSTANT_DEATH
    damageAmount = _currentHealth;
#endif
	if (_isDead) {
		return;
	}
	if (_currentHealth <= damageAmount) {
		[self die:inflictor];
	} else {
		[self hurt:damageAmount inflictor:inflictor];
	}
}

-(void)wasHitBy:(SF3DObject*)attacker{
    //we have been hit by something - that is, we are the victim
    //we should only change things on ourself
    if ([[self class] takesDamageFrom:[attacker class]]) {
        [self takeDamage:[attacker damageAmount] fromInflictor:attacker];
    }
}

-(void)didHit:(SF3DObject*)victim{
	//we have hit somethign - that is, we are the attacker
    //we should only change things on ourself
}


-(void)stripWeapon:(id)weapon{
	//take away a player's weapon
}

@end
