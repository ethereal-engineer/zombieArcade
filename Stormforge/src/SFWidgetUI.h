//
//  SFWidgetUI.h
//  ZombieArcade
//
//  Created by Adam Iredale on 22/12/09.
//  Copyright 2009 Stormforge Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SFWidget.h"
#import "SFWidgetLabel.h"
#import "SFStack.h"
#import "SF3DObject.h"
#import "SFSound.h"

@interface SFWidgetUI : SFWidget {
	//the widget ui is the core of 
	//all onscreen overlay ui
	
	//all touch events are passed through
	//a widget ui component
	
	//if the ui has no 3d scene behind it
	//then use an alternate init (later)
    SFWidgetLabel       *_title;        //topbar title
    SFWidget            *_logo,
                        *_help;         //if a logo is used for an overlay, also help screens
    SFWidget            *_backButton,
                        *_helpButton;   //when menus are used, a back button is overlaid (and help)
    SFWidget            *_topBar;       //if this UI has a top bar it will be rendered
    SFStack             *_menus;        //menus that write over the top of everything except overlays
    NSMutableArray      *_overlays;     //transparent overlays drawn last
    int                 _currentHelpIndex;
    SFSound             *_sndPopMenu, *_sndHelp;
}
-(id)initUI:(NSString*)atlasName;
-(void)updateTopBar;
-(void)customiseUI;
-(id)addMenu:(SFWidget*)menu;
-(id)addOverlay:(SFWidget*)overlay;
-(id)addOverlay:(NSString*)atlasName atlasItem:(NSString*)atlasItem position:(vec2)position;
-(void)popMenu;
-(void)popOverlay;
-(void)sceneWasPicked:(SF3DObject*)pickObject pickVector:(vec3)pickVector;
-(BOOL)invokeHelp;
-(void)enableLogo:(BOOL)enable;
-(SFWidget*)topBar;
-(void)setTopBarOffset:(CGPoint)offset;
-(void)setPopMenuSound:(NSString*)sound;
-(void)setHelpSound:(NSString*)sound;
@end
