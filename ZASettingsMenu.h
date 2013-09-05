//
//  ZASettingsMenu.h
//  ZombieArcade
//
//  Created by Adam Iredale on 15/01/10.
//  Copyright 2010 Stormforge Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SFWidgetMenu.h"
#import "SFWidgetSlider.h"

@interface ZASettingsMenu : SFWidgetMenu {
	//a standard widget menu - just in a class
	//to allow us easy access
	SFWidgetSlider *_ambientVol, *_sfxVol;
    SFWidgetLabel *_labelAmbient, *_labelSfx;
}

-(id)initSettingsMenu:(NSString*)atlasName;

@end
