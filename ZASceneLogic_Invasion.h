//
//  ZASceneLogic_Invasion.h
//  ZombieArcade
//
//  Created by Adam Iredale on 30/12/09.
//  Copyright 2009 Stormforge Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZASceneLogic_Base.h"
#import "SFHealthWidget.h"
#import "SFWidget.h"
#import "SFWidgetLabel.h"
#import "SFWidgetDialog.h"
#import "SFAchievementNotification.h"

@interface ZASceneLogic_Invasion : ZASceneLogic_Base {
	//invasion derivative of game logic
	//basic notion:
	//* camera at zombie level
	//* attack sensor activated
	SFHealthWidget *_healthBar;
	SFWidget *_gameOver;
	BOOL _gameIsOver;
	int64_t _gameOverTime;
	NSArray *_gradePhrases;
	SFWidgetLabel *_gradeLabel, *_perfectCount, *_score;
    SFWidgetDialog *_dialog;
    float _lastKnownGrade;
}

@end
