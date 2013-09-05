//
//  SFWeaponHud.h
//  ZombieArcade
//
//  Created by Adam Iredale on 22/02/10.
//  Copyright 2010 Stormforge Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SFWidgetSlideTray.h"

@interface SFWeaponHud : SFWidgetSlideTray <SFWeaponDelegate, SFPlayerDelegate> {
    //populates and updates it's items from the player's
    //weapon dictionary
    BOOL _springRetract;
    int _maxWeaponCount;
}

-(id)initWeaponHud:(NSString*)atlasName;

@end
