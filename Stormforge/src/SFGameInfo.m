//
//  SFGameInfo.m
//  ZombieArcade
//
//  Created by Adam Iredale on 22/01/10.
//  Copyright 2010 Stormforge Software. All rights reserved.
//

#import "SFGameInfo.h"
#import "SFUtils.h"

#define USE_QUICK_MUSIC 0

static SFGameInfo *gSFGameInfo = NULL;

@implementation SFGameInfo

-(id)init{
	self = [super init];
	if (self != nil) {
		_gameInfo = [[NSDictionary alloc] initWithContentsOfFile:[SFUtils getFilePathFromBundle:@"SFGameInfo.plist"]];
	}
	return self;
}

-(NSDictionary*)getAtlasDictionary{
    return [_gameInfo objectForKey:@"atlas"];
}

-(NSDictionary*)getAtlasInfo:(NSString*)atlasName{
    return [[self getAtlasDictionary] objectForKey:atlasName];
}

-(id)getMovieListDictionary{
    return [_gameInfo objectForKey:@"movies"];
}

-(id)getMovieList:(NSString*)movieListName{
    return [[self getMovieListDictionary] objectForKey:movieListName];
}

-(id)getImageOffsetsDictionary{
    return [_gameInfo objectForKey:@"imageOffsets"];
}

-(CGRect)getImageOffset:(NSString*)imageName{
    //returns the rectangle in which the image resides (within a power of two map)
    //later maybe use this to help with button maps
    //the format is as follows:
    //0 - x
    //1 - y
    //2 - width
    //3 - height
    NSArray *offsets = [[self getImageOffsetsDictionary] objectForKey:imageName];
    if (!offsets) {
        return CGRectZero;
    }
    return CGRectMake([[offsets objectAtIndex:0] floatValue], 
                      [[offsets objectAtIndex:1] floatValue], 
                      [[offsets objectAtIndex:2] floatValue], 
                      [[offsets objectAtIndex:3] floatValue]);
}

-(id)getFontsDictionary{
    return [_gameInfo objectForKey:@"fonts"];
}

-(id)getFontDictionary:(int)size{
    return [[self getFontsDictionary] objectForKey:[@"font" stringByAppendingFormat:@"%u", size]];
}

-(id)getWeaponsDictionary{
    return [_gameInfo objectForKey:@"weapons"];
}

-(id)getWeaponDictionary:(NSString*)weaponName{
    return [[self getWeaponsDictionary] objectForKey:weaponName];
}

-(id)getDefaultWeaponDictionary{
    id defaultName = [_gameInfo objectForKey:@"defaultWeapon"];
    return [self getWeaponDictionary:defaultName];
}

-(id)getAchievementDictionary{
	return [_gameInfo objectForKey:@"achievements"];
}

-(id)getAchievementInfo:(NSString*)achievementId{
    return [[self getAchievementDictionary] objectForKey:achievementId];
}

-(id)getGREEInfo:(id)infoKey{
    return [[_gameInfo objectForKey:@"GREE"] objectForKey:infoKey];
}

-(id)getTextDictionary{
	return [_gameInfo objectForKey:@"text"];
}

-(id)getGameModeArray{
	return [_gameInfo objectForKey:@"gameModes"];
}

-(id)getGameTextArray:(NSString *)textKind{
	return [[self getTextDictionary] objectForKey:textKind];
}

-(id)getGameText:(NSString*)identifier{
    return [[[self getTextDictionary] objectForKey:@"singles"] objectForKey:identifier];
}

-(id)getResourceDictionary{
	return [_gameInfo objectForKey:@"resources"];
}

-(id)getResourceArray:(Class)itemClass{
	return [[self getResourceDictionary] objectForKey:[itemClass description]];
}

-(id)getCreditString:(int)creditIndex{
    return [[_gameInfo objectForKey:@"credits"] objectAtIndex:creditIndex];
}

-(int)getCreditCount{
    return [[_gameInfo objectForKey:@"credits"] count];
}

-(id)getLevelArray{
	return [_gameInfo objectForKey:@"levels"];
}

-(id)getMusicDictionary{
#if USE_QUICK_MUSIC
    NSArray *quickMusic = [NSArray arrayWithObject:@"quickMusic.ogg"];
    return [NSDictionary dictionaryWithObjectsAndKeys:quickMusic, @"relax", quickMusic, @"challenge", nil];
#else
	return [_gameInfo objectForKey:@"music"];
#endif
}

-(int)getLevelCount{
	return [[self getLevelArray] count];
}

-(id)getLevelDictionary:(int)levelIndex{
	return [[self getLevelArray] objectAtIndex:levelIndex];
}

-(id)getDefaultSettingsDictionary{
	return [_gameInfo objectForKey:@"settings"];
}

-(id)getMainMenuDictionary{
	return [_gameInfo objectForKey:@"mainMenu"];
}

-(id)getMusicArray:(NSString*)musicKind{
	return [[self getMusicDictionary] objectForKey:musicKind];
}

+(SFGameSingleton**)getGameSingletonPointer{
	return &gSFGameInfo;
}

@end
