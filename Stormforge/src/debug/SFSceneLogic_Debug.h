//
//  SFSceneLogic_Debug.h
//  ZombieArcade
//
//  Created by Adam Iredale on 23/02/10.
//  Copyright 2010 Stormforge Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SFSceneLogic.h"

@interface SFSceneLogic_Debug : SFSceneLogic {
    //simple logic class - touch the scene and
    //it moves to the next one
}

+(void)debugScenes;
+(void)debugScene:(int)sceneIndex;
@end
