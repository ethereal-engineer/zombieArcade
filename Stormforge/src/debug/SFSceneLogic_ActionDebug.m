//
//  SFSceneLogic_ActionDebug.m
//  ZombieArcade
//
//  Created by Adam Iredale on 19/03/10.
//  Copyright 2010 Stormforge Software. All rights reserved.
//

#import "SFSceneLogic_ActionDebug.h"
#import "SFTarget.h"
#import "SFScene.h"

@implementation SFSceneLogic_ActionDebug

-(NSString*)getActiveCameraName{
    return @"Camera.Invasion";
}

-(void)playMusic{
    //axe the music
}

-(void)gameObjectBorrowedOk:(id)gameObject{
    _target = [gameObject retain];
    [_target resolveDependantItems:nil];
}

-(void)changeAction{
  //  if (!_targetSetup) {
//       // SFTransform *spawnPointTrans = [SFTransform transformWithTransform:[(SFCamera*)[[self scene] camera] transform] dictionary:nil];
//        //move it a little away from the camera
//       // [[spawnPointTrans loc] add:[SFVec vectorWithSFVec:(SFVec){0, 2.0f, 0}]];
//        //move it
//        [_target setFirstSpawnTransform:spawnPointTrans];
//        [_target physicsSetLinearFactor:[SFVec vectorWithSFVec:(SFVec){0,0,0}]];
//        [[self scene] addObjectToScene:_target];
//        _actionList = [[[[_target class] actionDictionary] allKeys] retain];
//        _targetSetup = YES;
//    }
//    [_target playAction:[[[_target class] actionDictionary] objectForKey:[_actionList objectAtIndex:_actionIndex]] loopAction:YES];
//    _actionIndex = (_actionIndex + 1) % [_actionList count];
}

-(void)loadTargets{
    [super loadTargets];
    //cache made into queue...
   // [[[self scene] cache] borrowGameObject:@"targetZombie" objectClass:[SFTarget class] forObject:self];
}

//-(void)makeSceneChoices{
//    [super makeSceneChoices];
//    if (_target) {        
//        [_target physicsSetAngularVelocity:[SFVec vectorWithSFVec:(SFVec){0,0,0.1f}]];
//    }
//}

-(void)cleanUp{
    [_target release];
    [_spawnPoint release];
    [_actionList release];
    [super cleanUp];
}

//-(void)uiAction:(SFWidget *)uiWidget{
//    [super uiAction:uiWidget];
//    switch ([uiWidget callbackReason]) {
//        case CR_SCENE_PICK_OBJECT:
//            [self changeAction];
//            break;
//        default:
//            break;
//    }
//}

@end
