//
//  SFWidgetMenu.h
//  ZombieArcade
//
//  Created by Adam Iredale on 10/12/09.
//  Copyright 2009 Stormforge Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SFWidget.h"
#import "SFWidgetUI.h"
#import "SFWidgetLabel.h"

#define DEFAULT_MENU_TITLE_FONT @"scoreFont16x16.tga"

@interface SFWidgetMenu : SFWidget {
	//a widget menu is a collection of widgets that form a 
	//menu-driven user interface - each widget menu can
	//have as many items or submenus as desired
	//SFWidget *_helpButton, *_backButton; //menus need a back button
	//if it's the main main menu - we don't need a back button
	//we can tell this - when we are init'd - we request
	//a "back to" menu (which can be a 2D or 3D menu) 
	//if it's nil then we are either main or can't go back
	NSString *_title;
	//SFWidget *_logo; //help button
	BOOL _hideBackButton, _useBackPassthrough;
    CGPoint _menuLines[4];
    int _menuLineCount;
}
-(id)initMenu:(NSString*)atlasName;
-(id)addButton:(CGPoint)overlayIndex largeButton:(BOOL)largeButton;
-(void)setClearBackground;
-(BOOL)hideBackButton;
-(BOOL)usesBackPassthrough;
-(void)setBackPassthrough;
-(NSString*)title;
-(void)setTitle:(NSString*)title;

@property (nonatomic, assign) BOOL _hideBackButton;

@end
