//
//  SFCreditsMenu.h
//  ZombieArcade
//
//  Created by Adam Iredale on 26/02/10.
//  Copyright 2010 Stormforge Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SFWidgetMenu.h"
#import "SFWidgetLabel.h"

@interface SFCreditsMenu : SFWidgetMenu {
    //pretty simple - a screen to display credits
    SFWidgetLabel *_credit;
    unsigned int _creditRendersRemaining;
    int _creditIndex;
    int _creditCount;
}

-(void)startRollingCredits;

@end
