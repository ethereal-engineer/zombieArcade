//
//  SFGameSingleton.m
//  ZombieArcade
//
//  Created by Adam Iredale on 28/01/10.
//  Copyright 2010 Stormforge Software. All rights reserved.
//

#import "SFGameSingleton.h"
#import "SFUtils.h"
#import "SFDebug.h"

#define DEBUG_SINGLEON 0

static SFGameSingleton *gSFGameSingleton = nil;

@implementation SFGameSingleton

//modified version of the developer docs code

+(SFGameSingleton*)sharedManager
{
    SFGameSingleton** singletonInstance = [[self class] getGameSingletonPointer];
	if (*singletonInstance == nil) {
		sfDebug(DEBUG_SINGLEON, "Creating game singleton class %s...", [[[self class] description] UTF8String]);
		*singletonInstance = [[super allocWithZone:NULL] initWithDictionary:nil];
	}
	return *singletonInstance;
}

+(SFGameSingleton**)getGameSingletonPointer{
	return &gSFGameSingleton;
}

+(BOOL)exists{
    return [self getGameSingletonPointer] != nil;
}

+(void)cleanUp{
    //no point in cleaning up if it isn't even born!
    if ([self exists]) {
        [[self alloc] cleanUp];
    }
}

+ (id)allocWithZone:(NSZone *)zone
{
    return [[self sharedManager] retain];
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

- (id)retain
{
    return self;
}

- (NSUInteger)retainCount
{
    return NSUIntegerMax;  //denotes an object that cannot be released
}

-(void)release
{
    //do nothing
}

-(id)autorelease
{
    return self;
}
@end
