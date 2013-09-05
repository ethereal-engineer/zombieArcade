//
//  SFWidgetSlider.h
//  ZombieArcade
//
//  Created by Adam Iredale on 4/01/10.
//  Copyright 2010 Stormforge Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SFWidget.h"
#import "SFWidgetLabel.h"

@interface SFWidgetSlider : SFWidget {
	//the usual slider (win32 style) for 
	//volume control etc
	//it consists of two widgets and a label
	//the main widget (self) is the bar
	//it has no position in the init because
	//it is designed to go straight into a menu
	//screen
	SFWidget *_carot;
	float _value;
    id<SFWidgetDelegate> _externalDelegate;
}

-(id)initSlider:(NSString*)atlasName;
-(void)setCurrentValue:(float)value;
-(float)currentValue;

@end
