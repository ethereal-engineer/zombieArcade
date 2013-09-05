//
//  SFSplash.h
//  ZombieArcade
//
//  Created by Adam Iredale on 27/11/09.
//  Copyright 2009 Stormforge Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SFGameObject.h"
#import "SFWidget.h"

@interface SFStandaloneWidget : SFGameObject {
    //has at least one widget to render
    SFWidget *_internalWidget;
    BOOL _firstRender;
}

-(BOOL)render;
-(BOOL)renderContent;
-(void)setupWidget:(SFWidget**)widget;

@end
