//
//  SFLoadingScreen.m
//  ZombieArcade
//
//  Created by Adam Iredale on 4/12/09.
//  Copyright 2009 Stormforge Software. All rights reserved.
//

#import "SFLoadingScreen.h"
#import "SFUtils.h"

#define DEFAULT_LOADING_FONT @"scoreFont32x32.tga"

@implementation SFLoadingScreen

-(void)setupWidget:(SFWidget **)widget{
    [super setupWidget:widget];
    *widget = [[SFWidget alloc] initWidget:@"loading"
                                 atlasItem:@"background"
                                  position:Vec2Zero 
                                  centered:NO
                             visibleOnShow:YES
                              enableOnShow:NO];
}

-(void)cleanUp{
    [_loadingDots cleanUp];
    [_loadingDots release];
    [super cleanUp];
}

-(id)initLoadingScreen{
	self = [self initWithDictionary:nil];
	if (self != nil) {
        _loadingDots = [[SFWidget alloc] initWidget:@"loading"
                                          atlasItem:@"loadingDots"
                                           position:Vec2Make(321,138)
                                           centered:NO
                                      visibleOnShow:YES
                                       enableOnShow:NO];
        [_loadingDots show];
	}
	return self;
}

-(BOOL)renderContent{
    static int dotCount = 0;
    //cycle dots each render
    [_loadingDots setImageOffset:CGPointMake(dotCount, 0)];
    BOOL renderedOk = [super renderContent];
    renderedOk = [_loadingDots render] or renderedOk;
    dotCount = (dotCount + 1) % 4;
    return renderedOk;
}

@end
