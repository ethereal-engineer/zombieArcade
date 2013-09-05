//
//  ZASettingsMenu.m
//  ZombieArcade
//
//  Created by Adam Iredale on 15/01/10.
//  Copyright 2010 Stormforge Software. All rights reserved.
//

#import "ZASettingsMenu.h"
#import "SFDefines.h"
#import "SFSettingManager.h"
#import "SFSound.h"
#import "SFGameEngine.h"

#define DEFAULT_DEMO_SOUND @"golfBallHit.ogg"

@implementation ZASettingsMenu

-(id)initSettingsMenu:(NSString*)atlasName{
    self = [self initMenu:atlasName];
	if (self != nil) {
        
        SFWidget *musicLabel = [[SFWidget alloc] initWidget:_atlasName
                                                  atlasItem:@"captions"
                                                   position:Vec2Zero
                                                   centered:YES
                                              visibleOnShow:YES
                                               enableOnShow:NO];
        [musicLabel setImageOffset:CGPointMake(0, 1)];
        [self addSubWidget:musicLabel];
        [musicLabel release];
        
        _ambientVol = [[SFWidgetSlider alloc] initSlider:_atlasName];
		[self addSubWidget:_ambientVol];
        
        SFWidget *sfxLabel = [[SFWidget alloc] initWidget:_atlasName
                                                  atlasItem:@"captions"
                                                   position:Vec2Zero
                                                   centered:YES
                                              visibleOnShow:YES
                                               enableOnShow:NO];
        [self addSubWidget:sfxLabel];
        [sfxLabel release];
        
        _sfxVol = [[SFWidgetSlider alloc] initSlider:_atlasName];
		[self addSubWidget:_sfxVol];
        
       // [_helpButton setVisibleOnShow:NO];
        [self arrangeSubWidgets];
        
        [_ambientVol setCurrentValue:SFAL::instance()->volume(SF_VOLUME_CATEGORY_AMBIENT)];
        [_sfxVol setCurrentValue:SFAL::instance()->volume(SF_VOLUME_CATEGORY_SFX)];
	}
	return self;
}

//////////////////
//SFWidgetDelegate
//////////////////

-(void)widgetCallback:(id)widget reason:(unsigned char)reason{
    [super widgetCallback:widget reason:reason];
    switch (reason) {
        case CR_MENU_AUX:
            //a slider has changed value
            if (widget == _sfxVol) {
                //play a sound effect to demonstrate the sound volume chosen
                SFAL::instance()->setVolume(SF_VOLUME_CATEGORY_SFX, [widget currentValue]);
                [[SFGameEngine defaultQueue] addOperation:[SFSound class] 
                                                 selector:@selector(quickPlayAmbient:) 
                                                   object:DEFAULT_DEMO_SOUND];
            } else if (widget == _ambientVol) {
                SFAL::instance()->setVolume(SF_VOLUME_CATEGORY_AMBIENT, [widget currentValue]);
                //if there is music playing it will change volume to reflect the setting
            }
            break;
    }
}

@end
