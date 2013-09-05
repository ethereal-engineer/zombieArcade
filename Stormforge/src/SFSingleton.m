//
//  SFSingleton.m
//  ZombieArcade
//
//  Created by Adam Iredale on 12/11/09.
//  Copyright 2009 Stormforge Software. All rights reserved.
//

#import "SFSingleton.h"
#import "SFUtils.h"
#import "SFDebug.h"

static SFSingleton *gSFSingleton = nil;

#define DEBUG_SINGLETON_ORIG 0

@implementation SFSingleton

//modified version of the developer docs code

+ (SFSingleton*)sharedManager
{
    SFSingleton** singletonInstance = [[self class] getSingletonPointer];
	if (*singletonInstance == nil) {
		sfDebug(DEBUG_SINGLETON_ORIG, "Creating singleton class %s...", [[[self class] description] UTF8String]);
		*singletonInstance = [[super allocWithZone:NULL] init];
	}
	return *singletonInstance;
}

+ (SFSingleton**)getSingletonPointer{
	return &gSFSingleton;
}

+(BOOL)exists{
    return [self getSingletonPointer] != nil;
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

- (void)release
{
    //do nothing
}

- (id)autorelease
{
    return self;
}
@end
