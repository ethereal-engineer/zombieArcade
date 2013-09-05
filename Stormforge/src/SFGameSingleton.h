//
//  SFGameSingleton.h
//  ZombieArcade
//
//  Created by Adam Iredale on 28/01/10.
//  Copyright 2010 Stormforge Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SFGameObject.h"

@interface SFGameSingleton : SFGameObject {
	//a singleton class based on the game object
}

+(SFGameSingleton**)getGameSingletonPointer;
//points to the singleton pointer allowing easy subclassing
//note that this should only ever be implemented by the
//immediate descendant of the singleton base class (that is, that you want to be unique)
+(void)cleanUp;
@end
