//
//  SFWidgetDialog.m
//  ZombieArcade
//
//  Created by Adam Iredale on 6/01/10.
//  Copyright 2010 Stormforge Software. All rights reserved.
//

#import "SFWidgetDialog.h"

#define TITLE_OFFSET 40.0f

@implementation SFWidgetDialog

-(void)createQuestion:(NSString *)question{
	_question = [[SFWidgetLabel alloc] initLabel:@"appleCasual16"
                                             initialCaption:question
                                                   position:Vec2Make(240, 200)
                                                   centered:YES
                                              visibleOnShow:YES
                                          updateViaCallback:NO];
    [_question setJustification:ljCenter];
}

-(void)addButtons{
    _btnYes     = [self addButton:CGPointMake(0, 0) largeButton:NO];
    _btnNo      = [self addButton:CGPointMake(1, 0) largeButton:NO];
    _btnCancel  = [self addButton:CGPointMake(2, 0) largeButton:NO];
}

-(id)initDialog:(NSString*)question{
    self = [super initMenu:@"main"];
    if (self != nil) {
        _subWidgetArrangeStyle = wasHorizontalCentered;
        [self createQuestion:question];
        [self addButtons];
        //[_backButton setVisibleOnShow:NO];
        _hideBackButton = YES;
       // [_helpButton setVisibleOnShow:NO];
    }
    return self;
}

-(void)cleanUp{
    [_question release];
    [super cleanUp];
}

-(BOOL)render{
    BOOL renderedOk = [super render];
    [_question render];
    return renderedOk;
}

////////////////
//widgetDelegate
////////////////

-(void)widgetWasTouched:(id)widget touchKind:(unsigned char)touchKind dragRect:(CGRect)dragRect{
    [super widgetWasTouched:widget touchKind:touchKind dragRect:dragRect];
    switch (touchKind) {
        case CR_WIDGET_PRESSED:
            if (widget == _btnYes) {
                [_widgetDelegate widgetCallback:self reason:CR_YES];
            } else if (widget == _btnNo) {
                [_widgetDelegate widgetCallback:self reason:CR_NO];
            } else if (widget == _btnCancel) {
                [_widgetDelegate widgetCallback:self reason:CR_CANCEL];
            }
            break;
        default:
            break;
    }
}

@end
