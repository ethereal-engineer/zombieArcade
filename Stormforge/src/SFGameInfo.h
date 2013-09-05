//
//  SFGameInfo.h
//  ZombieArcade
//
//  Created by Adam Iredale on 22/01/10.
//  Copyright 2010 Stormforge Software. All rights reserved.
//


#ifndef SFGAMEINFO_H

#import <Foundation/Foundation.h>
#import "SFGameSingleton.h"

@interface SFGameInfo : SFGameSingleton {
	//an easy global singleton access class
	//to get to game information and settings
	NSDictionary *_gameInfo;
}

@end

#define SFGAMEINFO_H
#endif