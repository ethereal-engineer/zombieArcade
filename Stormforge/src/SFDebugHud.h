//
//  SFDebugHud.h
//  ZombieArcade
//
//  Created by Adam Iredale on 11/02/10.
//  Copyright 2010 Stormforge Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SFWidgetLabel.h"

#define DEFAULT_DEBUG_HUD_FONT @"courier16x16.tga"
#define DEFAULT_DEBUG_HUD_OFFSET 16

@interface SFDebugHud : SFWidgetLabel {
    //a label for debugging
    NSMutableDictionary *_observedValues;
}

@end
