//
//  SFSceneLogic_Debug.m
//  ZombieArcade
//
//  Created by Adam Iredale on 23/02/10.
//  Copyright 2010 Stormforge Software. All rights reserved.
//

#import "SFSceneLogic_Debug.h"
#import "SFSceneManager.h"
#import "SFGameInfo.h"
#import "SFUtils.h"

@implementation SFSceneLogic_Debug

-(NSString*)getActiveCameraName{
    return @"Camera.Invasion";
}

-(void)loadTargets{
    //add a few zombies to wander around for lighting
  //  for (id sp in _startPoints) {
//        [self addTarget:@"targetZombie" spawnPoint:sp];
//    }
}

-(void)moveToNextScene{
    int levelCount = [[self gi] getLevelCount];
    int nextLevel = [[self objectInfoForKey:@"levelNumber"] integerValue] + 1;
    if (nextLevel > (levelCount - 1)) {
        nextLevel = 0; //cycle around
    }
    [[self class] debugScene:nextLevel];
}

//-(void)uiAction:(SFWidget *)uiWidget{
//    [super uiAction:uiWidget];
//    if ([uiWidget wasPressed]) {
//        [self moveToNextScene];
//    }
//}

+(void)debugScene:(int)sceneIndex{
    NSMutableDictionary *debugScene = [NSMutableDictionary dictionaryWithDictionary:[[SFGameInfo alloc] getLevelDictionary:sceneIndex]];
    [debugScene setObject:@"SFSceneLogic_Debug" forKey:@"logicClass"];
    [debugScene setObject:[NSNumber numberWithBool:YES] forKey:@"noWeapons"];
    [[SFSceneManager alloc] changeScene:debugScene];
    return;
}

+(void)debugScenes{
    [self debugScene:0];
}

@end
