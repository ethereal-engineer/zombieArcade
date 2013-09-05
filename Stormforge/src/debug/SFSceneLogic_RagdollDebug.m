//
//  SFSceneLogic_RagdollDebug.m
//  ZombieArcade
//
//  Created by Adam Iredale on 21/04/10.
//  Copyright 2010 Stormforge Software. All rights reserved.
//

#import "SFSceneLogic_RagdollDebug.h"
#import "SFScene.h"

@implementation SFSceneLogic_RagdollDebug

-(NSString*)getActiveCameraName{
    return @"Camera.Invasion";
}

-(void)playMusic{
    [[self scene] spawnObject:_target withTransform:[(SF3DObject*)[_wayPoints objectAtIndex:3] transform] adjustZAxis:NO];
}

-(void)loadTargets{
    [super loadTargets];
    _target = [[[self rm] getItem:@"ragdollZombie" itemClass:[SFRagdoll class] tryLoad:YES] retain];
    [_target buildRagdoll];
    [_target setScene:[self scene]];
    [[self scene] appendSceneObject:_target];
}

-(void)cleanUp{
    [super cleanUp];
    [_target release];
}

@end
