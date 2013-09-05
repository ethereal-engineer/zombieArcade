//
//  SFWidgetSlideTray.h
//  ZombieArcade
//
//  Created by Adam Iredale on 18/12/09.
//  Copyright 2009 Stormforge Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SFWidget.h"

@interface SFWidgetSlideTray : SFWidget {
	//the slide tray is a widget that 
	//sits in (say) a corner and when
	//opened, slides out to it's full size
	//and shows sub items
	
	//each of its items are widgets
	//and when they are tapped once
	//they activate and close the menu again
	
	//adding menu items can only happen on
	//a single axis because the tray is a strip
	
	SFWidget *_tray;
	BOOL _isOpen, _isOpening, _isClosing;
    id<SFWidgetDelegate> _externalDelegate;
}

-(id)initSlideTray:(NSString*)atlasName;
-(void)closeImmediate;
-(void)close;
-(void)open;
@end
