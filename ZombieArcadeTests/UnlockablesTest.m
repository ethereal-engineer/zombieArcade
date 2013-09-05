//
//  UnlockablesTest.m
//  ZombieArcade
//
//  Created by Adam Iredale on 8/07/13.
//  Copyright (c) 2013 Stormforge Software. All rights reserved.
//

#import "UnlockablesTest.h"
#import "SFScoreManager.h"
#import "OCMock.h"
#import "SFPlayer.h"

@interface SFScoreManager (PrivateMethods)

-(NSArray *)combineAchievementsFromDefinitionsWithThoseAlreadyLoaded:(NSArray *)preloadedAchievements;
-(void)processAchievements:(NSArray *)achievements;
-(void)assessAchievements;

@end

@interface SFScoreManagerTestable : SFScoreManager

@property (nonatomic, retain) SFPlayer *testPlayer;

@end

@implementation SFScoreManagerTestable

- (SFPlayer *)localPlayer
{
    return _testPlayer;
}

- (void)setCurrentGrade:(float)grade
{
    _currentGrade = grade;
}

- (void)setLevelIdentifier:(float)levelId
{
    _levelIdentifier = levelId;
}

@end

@interface UnlockablesTest ()

@property (nonatomic, retain) SFScoreManagerTestable *scoreManager;

@end

@implementation UnlockablesTest

#pragma mark - Fixtures

- (void)setUp
{
    [super setUp];
    self.scoreManager = [[SFScoreManagerTestable alloc] initWithDictionary:nil];
    NSArray *achievements = [_scoreManager combineAchievementsFromDefinitionsWithThoseAlreadyLoaded:nil];
    [_scoreManager processAchievements:achievements];
}

- (void)tearDown
{
    [_scoreManager release]; self.scoreManager = nil;
    [super tearDown];
}

#pragma mark - Helpers

#pragma mark - Tests

- (void)testManagerExists
{
    STAssertNotNil(_scoreManager, @"Score manager should exist");
}

- (void)testLevel2IsUnlockedIfGradeIsEqualTo5OnLevel1
{
    id testPlayer = [OCMockObject niceMockForClass:[SFPlayer class]];
    [_scoreManager setTestPlayer:testPlayer];
    [_scoreManager setCurrentGrade:5];
    [_scoreManager setLevelIdentifier:0];
    [[testPlayer expect] unlockLocalAchievement:@"level2" achievementInfo:OCMOCK_ANY];
    [_scoreManager assessAchievements];
    [testPlayer verify];
}

- (void)testLevel3IsUnlockedIfGradeIsEqualTo5OnLevel2
{
    id testPlayer = [OCMockObject niceMockForClass:[SFPlayer class]];
    [_scoreManager setTestPlayer:testPlayer];
    [_scoreManager setCurrentGrade:5];
    [_scoreManager setLevelIdentifier:1];
    [[testPlayer expect] unlockLocalAchievement:@"level3" achievementInfo:OCMOCK_ANY];
    [_scoreManager assessAchievements];
    [testPlayer verify];
}

- (void)testLevel4IsUnlockedIfGradeIsEqualTo5OnLevel3
{
    id testPlayer = [OCMockObject niceMockForClass:[SFPlayer class]];
    [_scoreManager setTestPlayer:testPlayer];
    [_scoreManager setCurrentGrade:5];
    [_scoreManager setLevelIdentifier:2];
    [[testPlayer expect] unlockLocalAchievement:@"level4" achievementInfo:OCMOCK_ANY];
    [_scoreManager assessAchievements];
    [testPlayer verify];
}

- (void)testLevel5IsUnlockedIfGradeIsEqualTo5OnLevel4
{
    id testPlayer = [OCMockObject niceMockForClass:[SFPlayer class]];
    [_scoreManager setTestPlayer:testPlayer];
    [_scoreManager setCurrentGrade:5];
    [_scoreManager setLevelIdentifier:3];
    [[testPlayer expect] unlockLocalAchievement:@"level5" achievementInfo:OCMOCK_ANY];
    [_scoreManager assessAchievements];
    [testPlayer verify];
}

@end
