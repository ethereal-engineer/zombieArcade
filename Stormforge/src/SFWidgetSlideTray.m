//
//  SFWidgetSlideTray.m
//  ZombieArcade
//
//  Created by Adam Iredale on 18/12/09.
//  Copyright 2009 Stormforge Software. All rights reserved.
//

#import "SFWidgetSlideTray.h"
#import "SFUtils.h"
#import "SFGameEngine.h"
#import "SFScene.h"
#import "SFDebug.h"

#define DEFAULT_SLIDE_INOUT_TIME 0.3f

@implementation SFWidgetSlideTray

-(id)initSlideTray:(NSString*)atlasName{

    self = [self initWidget:atlasName
                  atlasItem:@"hud"
                   position:Vec2Zero
                   centered:NO
              visibleOnShow:YES
               enableOnShow:YES];
	if (self != nil){
        //set introspective
        [super setWidgetDelegate:self];
        _tray = [[SFWidget alloc] initWidget:atlasName
                                   atlasItem:@"tray"
                                    position:Vec2Zero
                                    centered:NO
                               visibleOnShow:true 
                               enableOnShow:false];
        [_tray setSubWidgetArrangeStyle:wasHorizontal];
        [_tray setMargins:_boundsRect.size.width top:0 right:0 bottom:0];
        [_tray setWidgetDelegate:self];
        [self closeImmediate];
	}
	return self;
}

-(void)setWidgetDelegate:(id<SFWidgetDelegate>)delegate{
    //we will keep the external delegate up to date, but first we handle things
    //our way internally
    _externalDelegate = [delegate retain];
}

-(void)cleanUp{
    [_tray release];
    [super cleanUp];
}

-(BOOL)moveTrayTo:(vec2)destination stepSize:(float)stepSize{
    if (!stepSize) {
        //no steps - move directly
        [_tray transform]->loc()->setVec2(destination);
        [_tray transform]->compileMatrix();
    }
	if ([_tray transform]->loc()->x() == destination.x) {
		return NO; //we're done
	} else {
		float distX = destination.x - [_tray transform]->loc()->x();
		float stepX = MIN(ABS(distX), ABS(stepSize));
		if (distX < 0) {
			stepX *= -1;
		}
		[_tray transform]->loc()->setX([_tray transform]->loc()->x() + stepX);
        [_tray transform]->compileMatrix();
	}
	return YES; //more steps remaining
}

-(float)getMoveStepSize{
	return ([_tray boundsRect].size.width / [[[self sm] currentScene] timeToRenderPasses:DEFAULT_SLIDE_INOUT_TIME]);
}

-(void)closeImmediate{
	[_tray setEnabled:NO];
    [_tray hide];
	[self moveTrayTo:Vec2Make([_tray boundsRect].size.width * -1,0) stepSize:0.0f];
	_isOpen = false;
    _isClosing = false;
    _isOpening = false;
}

-(void)open{
	//animated slide to open
	[_tray show];
	_isOpening = YES;
}

-(id)addSubWidget:(SFWidgetShade*)widget{
    //add to the tray instead of us
    //set the widget as interested in rollover
    [widget setInterestedInRollOver:YES];
    return [_tray addSubWidget:widget];
}

-(void)removeAllSubWidgets{
    [_tray removeAllSubWidgets];
}

-(void)removeSubWidget:(SFWidgetShade *)widget{
    [_tray removeSubWidget:widget];
}

-(void)advanceAnimation{
	//when we are opening or closing we need to move the tray
	//and all menu items around
	if (_isOpening) {
		_isOpening = [self moveTrayTo:Vec2Make(_transform->loc()->x(), _transform->loc()->y()) stepSize:[self getMoveStepSize]];
		if (!_isOpening) {
            _isOpen = YES;
			[_tray setEnabled:YES];
		}
	} else if (_isClosing) {
        if (_isOpen) {
            _isOpen = NO;
			[_tray setEnabled:NO];
        }
		_isClosing = [self moveTrayTo:Vec2Make([_tray boundsRect].size.width * -1,0) stepSize:[self getMoveStepSize]];
        if (!_isClosing) {
            [_tray hide];
        }
	}
}

-(BOOL)render{
	[self advanceAnimation];
    BOOL renderedOk = NO;
    renderedOk = [_tray render];
	renderedOk = [super render] or renderedOk;
    return renderedOk;
}

-(BOOL)processTouchEvent:(SFTouchEvent *)touchEvent localTouchPos:(vec2)localTouchPos{
    //we don't process events while we are transitioning
    if (_isOpening or _isClosing) {
        return NO;
    }

    //further processing...
    if (_isOpen) {
        if ([_tray processTouchEvent:touchEvent localTouchPos:localTouchPos]){
            return YES;
        }
        //the tray didn't process it - we should close and return NO
        [self close];
        return NO;
    } else {
        //is it an event for the corner hud?
        if ([super processTouchEvent:touchEvent localTouchPos:localTouchPos]) {
            return YES;
        }
    }

    return NO;
}

-(void)close{
	//animated slide to close
	_isClosing = YES;
    [self resetTouch];
    [_tray resetTouch];
}

-(void)handleDragOpen{
	//the closed icon has been dragged - let's see if it's dragged in the right direction...
	sfDebug(TRUE, "slide dragged");
	[self open];
}

-(void)handleTapOnceFunction{
	//only works in the closed position
    // _callbackReason = CR_MENU_AUX;
    // [_altCallbackObject performSelector:_altCallbackSelector withObject:self];
}


-(void)trayEvent:(SFWidget*)widget{
    sfDebug(TRUE, "Tray event!");
}

//////////////////
//SFWidgetDelegate
//////////////////

-(void)widgetWasTouched:(id)widget touchKind:(unsigned char)touchKind dragRect:(CGRect)dragRect{
    [super widgetWasTouched:widget touchKind:touchKind dragRect:dragRect];
    switch (touchKind) {
        case CR_TOUCH_DRAG:
            //if the widget is the corner hud and we have dragged and we are NOT open then
            //we should open
            if (!_isOpen) {
                if (widget == self) {
                    //if the drag direction is to the right
                    if (dragRect.size.width > 0) {
                        [self open];
                    }
                } 
            }
            break;
        default:
            break;
    }
}

@end
