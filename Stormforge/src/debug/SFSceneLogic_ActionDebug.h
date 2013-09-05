//
//  SFSceneLogic_ActionDebug.h
//  ZombieArcade
//
//  Created by Adam Iredale on 19/03/10.
//  Copyright 2010 Stormforge Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SFSceneLogic.h"

@interface SFSceneLogic_ActionDebug : SFSceneLogic{
    //simple scene logic that spawns a zombie 
    //very close to the camera and rotates it 
    //whilst performing actions
    //touching the screen changes the action
    id _target, _spawnPoint, _actionList;
    int _actionIndex;
    BOOL _targetSetup;
}

@end
