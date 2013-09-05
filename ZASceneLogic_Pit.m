//
//  ZASceneLogic_Pit.m
//  ZombieArcade
//
//  Created by Adam Iredale on 30/12/09.
//  Copyright 2009 Stormforge Software. All rights reserved.
//

#import "ZASceneLogic_Pit.h"
#import "btCollisionObject.h"
#import "SFGameEngine.h"
#import "SFDebug.h"

@implementation ZASceneLogic_Pit

-(NSString*)getActiveCameraName{
	return @"Camera.Surviving";
}

-(void)handleTargetHitOther:(id)target otherObject:(id)otherObject{
    [super handleTargetHitOther:target otherObject:otherObject];
    //if the other object is a respawn trigger then teleport them to
    //a spawn point (or just kill them)
    if ((_respawnTrigger != nil) and (_respawnTrigger == otherObject)) {
        //kill the target without causing a ragdoll
        [target instantKill];
    }
}

-(void)loadTargets{
    _extraRagdollTime = 3.0f;
    [super loadTargets];
}

-(void)loadWidgets{
    [super loadWidgets];
    //add help for the in-game menu
    [_btnHelp addHelp:@"helpInGame1" helpName:@"default" helpOffset:Vec4Make(0, 0, 1, 1)];
    [_btnHelp addHelp:@"helpInGame1" helpName:@"default" helpOffset:Vec4Make(0, 2, 1, 2)];
}

-(void)playFirst{
    [super playFirst];
    
    //get the objective respawn trigger if any
    _respawnTrigger = [[[self scene] getItem:@"respawnTrigger" itemClass:[SF3DObject class]] retain];
    
    //if this is the first run of the game, show the game help
    
    id localPlayer = [SFGameEngine getLocalPlayer];
    if ([localPlayer hasSeenHelp:@"pitGame"]) {
        return;
    }
    [self showHelp];
    [localPlayer setHasSeenHelp:@"pitGame"];
}

-(void)cleanUp{
    [_respawnTrigger release];
    [super cleanUp];
}

@end
