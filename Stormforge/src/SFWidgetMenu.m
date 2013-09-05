//
//  SFWidgetMenu.m
//  ZombieArcade
//
//  Created by Adam Iredale on 10/12/09.
//  Copyright 2009 Stormforge Software. All rights reserved.
//

#import "SFWidgetMenu.h"
#import "SFWidgetLabel.h"
#import "SFDefines.h"

@implementation SFWidgetMenu

@synthesize _hideBackButton;

-(void)setClearBackground{
    //we don't want a semi-transparent background - we want full transparency
    _renderInvisible = YES;
}

-(NSString*)title{
    return _title;
}

-(void)addLines{
    //add snazzy menu lines for effect
    //for now, just two-pixel wide lines
    _menuLines[0] = CGPointMake(0, 298);
    _menuLines[1] = CGPointMake(480, 298);
    _menuLines[2] = CGPointMake(0, 40);
    _menuLines[3] = CGPointMake(440, 40);
    _menuLineCount = 2;
}

-(id)initMenu:(NSString*)atlasName{
	self = [self initBlankWidget:Vec2Zero
                        centered:NO
                   visibleOnShow:YES
                    enableOnShow:YES];
	if (self != nil) {
        _atlasName = [atlasName retain];
        [self setDimensions:CGPointMake(480.0f, 300.0f)];
        _subWidgetArrangeStyle = wasVerticalCentered;
        //enable ourselves so we block "ghostly" pass through input
        [self setColour:Vec4Make(0.53f, 0.53f, 0.53f, 0.498f)]; //set a background colour
        _renderInvisible = NO; //by default
        [self addLines];
        //setup a margin so the buttons are dispersed evenly
        [self setMargins:0 top:0 right:0 bottom:40];
	}
	return self;
}

-(void)cleanUp{
    [_atlasName release];
	[_title release];
    [super cleanUp];
}

-(void)setTitle:(NSString*)title{
    [_title release];
    _title = [title retain];
}

-(BOOL)hideBackButton{
    return _hideBackButton;
}

-(void)setHideBackButton:(BOOL)hide{
    _hideBackButton = hide;
}

-(void)setBackPassthrough{
    //we want "back" requests to pass through us as well as the ui widget
    _useBackPassthrough = YES;
}

-(BOOL)usesBackPassthrough{
    return _useBackPassthrough;
}

-(BOOL)render{
	//renders self and sub components
    BOOL renderedOk = [super render];
    if ((_menuLineCount) and (!_renderInvisible)) {
        //dodgy - later fix this PLEASE!
        if (_hideBackButton) {
            _menuLines[3] = CGPointMake(480, 40);
        }
        SFGL::instance()->glPushMatrix();
        SFGL::instance()->materialReset();
        SFGL::instance()->glEnableClientState(GL_VERTEX_ARRAY);
        SFGL::instance()->glVertexPointer(2, GL_FLOAT, 0, (const GLfloat*)&_menuLines[0]);
        SFGL::instance()->glDisable(GL_BLEND);
        SFGL::instance()->setBlendMode(SF_MATERIAL_OVERLAY);
        SFGL::instance()->glColor4f(COLOUR_SOLID_WHITE);
        glLineWidth(2);
        SFGL::instance()->glDrawArrays(GL_LINES, 0, 4);
        glLineWidth(0);
        SFGL::instance()->glPopMatrix();
    }
    return renderedOk;
}

-(id)addButton:(CGPoint)overlayIndex largeButton:(BOOL)largeButton{
    NSString *atlasItem;
    if (largeButton) {
        atlasItem = @"btnLarge";
    } else {
        atlasItem = @"btnSmall";
    }
    SFWidget *button = [[SFWidget alloc] initWidget:@"main"
                                          atlasItem:atlasItem
                                           position:Vec2Zero
                                           centered:YES
                                      visibleOnShow:YES
                                       enableOnShow:YES];
    [button setOverlayOffset:overlayIndex];
    [self addSubWidget:button];
    [button release];
    return button;
}

//////////////////
//SFWidgetDelegate
//////////////////

@end
