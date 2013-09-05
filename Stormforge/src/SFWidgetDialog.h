//
//  SFWidgetDialog.h
//  ZombieArcade
//
//  Created by Adam Iredale on 6/01/10.
//  Copyright 2010 Stormforge Software. All rights reserved.
//

#ifndef SFWIDGETDIALOG_H

#import <Foundation/Foundation.h>
#import "SFWidgetMenu.h"

@interface SFWidgetDialog : SFWidgetMenu {
	//basic question yes no fullscreen 
	//dialog
    SFWidgetLabel *_question;
    SFWidget *_btnYes, *_btnNo, *_btnCancel;
}
-(id)initDialog:(NSString*)question;

@end

#define SFWIDGETDIALOG_H
#endif