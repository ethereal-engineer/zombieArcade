//
//  SFOSVersion.m
//  ZombieArcade
//
//  Created by Adam Iredale on 28/06/10.
//  Copyright 2010 Stormforge Software. All rights reserved.
//

#import "SFOSVersion.h"
#import <MediaPlayer/MediaPlayer.h>

#define keyOSFeatures @"OSFeatures"

static const SFOSVersion *gSFOSVersion;

@implementation SFOSVersion

-(void)buildFeatureArray{
    //go through our features and add identifiers to the feature
    //array if they are supported on this operating system
    UIDevice* device = [UIDevice currentDevice];
    NSString *currSysVer = [device systemVersion];
    NSMutableArray *features = [[NSMutableArray alloc] init];
    //multitasking
    if ([device respondsToSelector:@selector(isMultitaskingSupported)] and device.multitaskingSupported){
        [features addObject:[NSNumber numberWithUnsignedChar:osfMultitasking]];
    }
    //MPC controller with view
    if ([MPMoviePlayerController instancesRespondToSelector:@selector(view)]) {
        [features addObject:[NSNumber numberWithUnsignedChar:osfMoviePlayerControllerView]];
    }
    //>=3.1 features
    if ([currSysVer compare:@"3.1" options:NSNumericSearch] != NSOrderedAscending){
        //CADisplayLink
        [features addObject:[NSNumber numberWithUnsignedChar:osfCADisplayLink]];
        [features addObject:[NSNumber numberWithUnsignedChar:osfUIVideoEditorController]];
    }
    [self setObjectInfo:features forKey:keyOSFeatures];
    [features release];
}

-(id)init{
    self = [super init];
    if (self != nil) {
        [self buildFeatureArray];
    }
    return self;
}

-(BOOL)featureSupported:(OSFeature)feature{
    //return true if the feature requested is supported in this
    //OS version
    NSArray *featuresArray = [self objectInfoForKey:keyOSFeatures];
    if (featuresArray) {
        //this is >= 3.1
        return [featuresArray containsObject:[NSNumber numberWithUnsignedChar:feature]];
    } else {
        return NO;
    }
}

+(BOOL)featureSupported:(OSFeature)feature{
    return [[self alloc] featureSupported:feature];
}

+(SFSingleton**)getSingletonPointer{
    return (id*)&gSFOSVersion;
}

@end
