//
//  SFLoadingScreen.h
//  ZombieArcade
//
//  Created by Adam Iredale on 4/12/09.
//  Copyright 2009 Stormforge Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SFStandaloneWidget.h"
#import "SFWidget.h"
#import "SFProtocol.h"

@interface SFLoadingScreen : SFStandaloneWidget {
	//loading screen
    SFWidget *_loadingDots;
    NSString *_atlasName;
}

-(id)initLoadingScreen;

@end
