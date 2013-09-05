//
//  SFAchievementNotification.h
//  ZombieArcade
//
//  Created by Adam Iredale on 3/05/10.
//  Copyright 2010 Stormforge Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SFWidget.h"
#import "SFWidgetLabel.h"

@interface SFAchievementNotification : SFWidget {
    //instead of popups during the game - this allows us
    //to display something that doesn't interfere with
    //gameplay
    SFWidget        *_icon;
    SFWidgetLabel   *_text, *_title;
}

-(id)initNotification;
-(void)setAchievement:(NSString*)resourceId;
-(void)setHighScore;
@end
