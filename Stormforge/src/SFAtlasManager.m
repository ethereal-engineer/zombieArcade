//
//  SFAtlasManager.m
//  ZombieArcade
//
//  Created by Adam Iredale on 13/04/10.
//  Copyright 2010 Stormforge Software. All rights reserved.
//

#import "SFAtlasManager.h"
#import "SFUtils.h"

static SFAtlasManager *gSFAtlasManager = nil;

@implementation SFAtlasManager

-(id)initWithDictionary:(NSDictionary *)dictionary{
    self = [super initWithDictionary:dictionary];
    if (self != nil) {
        _loadedAtlases = [[NSMutableDictionary alloc] init];
    }
    return self;
}

-(SFTextureAtlas*)loadAtlas:(NSString *)atlasName{
    //has this atlas already been loaded?
    SFTextureAtlas *atlas = [_loadedAtlases objectForKey:atlasName];
    if (!atlas) {
        //then we load it
        //and add it for later
        NSDictionary *atlasInfo = [[[self gi] getAtlasInfo:atlasName] retain];
        [SFUtils assert:(atlasInfo != nil) failText:@"\nAtlas info not found for tex atlas\n"];
        atlas = [[SFTextureAtlas alloc] initWithDictionary:atlasInfo];
        [_loadedAtlases setObject:atlas forKey:atlasName];
        [atlas release];
        [atlasInfo release];
    }
    return atlas;
}

-(void)unloadAtlas:(NSString *)atlasName{
    [_loadedAtlases removeObjectForKey:atlasName];
    //provided there are no other items linking to it, it will clean itself and release...
}

-(void)cleanUp{
    [_loadedAtlases release];
    [super cleanUp];
}

+(SFGameSingleton**)getGameSingletonPointer{
    return &gSFAtlasManager;
}

@end
