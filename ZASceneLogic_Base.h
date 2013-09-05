//
//  ZASceneLogic_Pit.h
//  ZombieArcade
//
//  Created by Adam Iredale on 16/11/09.
//  Copyright 2009 Stormforge Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SFSceneLogic.h"
#import "SFWeaponHud.h"
#import "SFWidgetMenu.h"
#import "SFTarget.h"
#import "ZASettingsMenu.h"

#define PIT_HUD_FONT @"scoreFont16x16.tga"

@interface ZASceneLogic_Base : SFSceneLogic {
	//scene logic for the pit-style level
    SFWidget *_fknRun, *_btnResume, *_btnOptions, *_btnQuit, *_btnHelp;
	SFWidgetMenu *_inGameMenu;
	SFWeaponHud *_weaponHud;
    ZASettingsMenu *_inGameSettings;
    BOOL _quitting, _showingInGameMenu, _showingHelp;
    SFTarget *_masterZombie;
    SFRagdoll *_masterRagdoll;
    float _zombieSearchRadius;
    SF3DObject *_spawnEffect;
    SFWidget *_gameHelp;
    int _currentHelpIndex;
}

-(void)doQuit;
-(BOOL)showHelp;

@end
