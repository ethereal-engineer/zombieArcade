//
//  ZASceneLogic_Pit.h
//  ZombieArcade
//
//  Created by Adam Iredale on 30/12/09.
//  Copyright 2009 Stormforge Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZASceneLogic_Base.h"

@interface ZASceneLogic_Pit : ZASceneLogic_Base {
	//surviving boredom style of game logic
	//basic notion:
	//* camera raised
	//* attack sensor deactivated
    SF3DObject *_respawnTrigger;
}

@end
