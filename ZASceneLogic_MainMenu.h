//
//  ZASceneLogic_MainMenu.h
//  ZombieArcade
//
//  Created by Adam Iredale on 24/11/09.
//  Copyright 2009 Stormforge Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SFSceneLogic.h"
#import "SFWidgetMenu.h"
#import "SFCreditsMenu.h"
#import "SFListingWidget.h"
#import "SFWidgetSlider.h"
#import "SFStack.h"
#import "SFLamp.h"
#import "SFWidgetDialog.h"

#define MAINMENU_HUD_FONT @"scoreFont16x16.tga"

//these correlate to scene item tags!!!!
typedef enum {
	MENU_3D_PICK_TROPHY_CASE = 0,
	MENU_3D_PICK_GREE = 1,
	MENU_3D_PICK_CLIPBOARD = 2,
	MENU_3D_PICK_HIFI = 3,
	MENU_3D_PICK_SHIRT_FRAME = 4,
	MENU_3D_PICK_WEAPON_CASE = 5,
	MENU_3D_PICK_TROPHY_DOOR = 6,
	MENU_3D_PICK_TROPHY = 7,
	MENU_3D_PICK_HIFI_CABINET = 8,
	MENU_3D_PICK_ALL
} MENU_3D_PICK;

typedef enum {
    tsNone,
    tsGetting,
    tsPutting,
    tsSpinning,
    tsAll
} SFTrophyState;

@interface ZASceneLogic_MainMenu : SFSceneLogic {
	//logic for the main menu
	SF3DObject *_currentTrophy; //the trophy we are examining
	float _lastDragDist; //the last distance dragged
	BOOL _handlingDrag; //true when handling a drag op
    SFWidget *_waiting;
    SFCreditsMenu *_menuCredits;
	SFWidgetMenu *_menuTrophies, *_menuSettings, *_menuShirts, *_menuGame, *_menuNewGame;
    SFWidget *_btnNewGame, *_btnResumeGame, *_btnDeleteSave;
    SFWidgetDialog *_dialog;
	SFWidgetSlider *_ambientVol, *_sfxVol;
	SFListingWidget *_gameStyle, *_levelSelect, *_resumeGameWidget;
	SF3DObject *_currentZoomObject, *_shirtFrame, *_trophyViewPos; //the item we are zoomed in on
	SFIpo *_currentTrophyPath, *_shirtFrameIpo;
    SFTransform *_currentTrophyTransform;
    id _helpButton;
    NSMutableDictionary *_gameModes;
    SFStack *_zoomObject;
    SFStack *_zoomUndo;
    NSArray *_trophyPos;
    BOOL _zoomingIn;
    int _shirtMoveDirection;
    SFTrophyState _trophyState;
}
-(id)gameStyleWidget;
-(id)creditTourWidget;
-(id)trophyMenuWidget;
-(id)settingsMenuWidget;
-(id)gameMenuWidget;
-(id)shirtMenuWidget;
-(void)showGameCenterMenu;
-(void)zoomPop;
-(void)zoomPush:(id)object;
-(void)shirtOnWall;
-(void)shirtOffWall;

@end
