//
//  SFOSVersion.h
//  ZombieArcade
//
//  Created by Adam Iredale on 28/06/10.
//  Copyright 2010 Stormforge Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SFSingleton.h"

//features
typedef enum {
    osfMoviePlayerControllerView,
    osfCADisplayLink,
    osfUIVideoEditorController,
    osfMultitasking,
    osfAll
} OSFeature;

@interface SFOSVersion : SFSingleton {
    //the idea behind this class is a way of knowing what we can
    //do based on the OS version of this device
}

-(BOOL)featureSupported:(OSFeature)feature;
+(BOOL)featureSupported:(OSFeature)feature;

@end
