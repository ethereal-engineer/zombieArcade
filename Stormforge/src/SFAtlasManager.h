//
//  SFAtlasManager.h
//  ZombieArcade
//
//  Created by Adam Iredale on 13/04/10.
//  Copyright 2010 Stormforge Software. All rights reserved.
//

#ifndef SFATLASMANAGER_H

#import <Foundation/Foundation.h>
#import "SFGameSingleton.h"
#import "SFTextureAtlas.h"
#import "SFProtocol.h"

@interface SFAtlasManager : SFGameSingleton <PAtlasManager> {
    //manages atlas resources so that they are
    //loaded only once each and shared accordingly
    NSMutableDictionary *_loadedAtlases;
}

@end

#define SFATLASMANAGER_H
#endif