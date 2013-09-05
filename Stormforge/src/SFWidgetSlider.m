//
//  SFWidgetSlider.m
//  ZombieArcade
//
//  Created by Adam Iredale on 4/01/10.
//  Copyright 2010 Stormforge Software. All rights reserved.
//

#import "SFWidgetSlider.h"
#import "SFUtils.h"
#import "SFDebug.h"

#define LEFTRIGHTPADDING 40.0f

@implementation SFWidgetSlider

-(void)setWidgetDelegate:(id<SFWidgetDelegate>)delegate{
    //we will keep the external delegate up to date, but first we handle things
    //our way internally
    _externalDelegate = [delegate retain];
}

-(void)cleanUp{
    [_externalDelegate release];
    [super cleanUp];
}

-(id)initSlider:(NSString*)atlasName{
    self = [self initWidget:atlasName
                  atlasItem:@"slideBar"
                   position:Vec2Zero
                   centered:YES
              visibleOnShow:YES
               enableOnShow:YES];
    if (self != nil) {
        //set introspective
        [super setWidgetDelegate:self];
        _carot = [[SFWidget alloc] initWidget:atlasName
                                    atlasItem:@"slideCarot"
                                     position:Vec2Zero
                                     centered:YES
                                visibleOnShow:YES
                                 enableOnShow:NO];
        [self addSubWidget:_carot];
        [_carot release];
    }
    return self;
}

-(void)setCurrentValue:(float)value{
    _value = value;
    //adjust the carot position from the value
    //note that all values are between 0.0f and 1.0f so we
    //just position the carot based on a fraction of this
    //proportional to the bounds rectangle
    [_carot transform]->loc()->setX(SF_CLAMP(_boundsRect.size.width * (value / 1.0f), 
                                             0.0f, 
                                             _touchRect.size.width - LEFTRIGHTPADDING));
    [_carot transform]->compileMatrix();
}

-(float)currentValue{
    return _value;
}

//////////////////
//SFWidgetDelegate
//////////////////

-(void)widgetWasTouched:(id)widget touchKind:(unsigned char)touchKind dragRect:(CGRect)dragRect{
    [super widgetWasTouched:widget touchKind:touchKind dragRect:dragRect];
    
    CGPoint touchPos;
    
    if (widget == self) {
        switch (touchKind) {
            case CR_TOUCH_TAP_DOWN:
                touchPos = dragRect.origin;
                break;
            case CR_TOUCH_DRAG:
            case CR_TOUCH_TAP_UP:
                touchPos = CGPointMake(dragRect.origin.x + dragRect.size.width,
                                       dragRect.origin.y + dragRect.size.height);
                break;
        }
        switch (touchKind) {
            case CR_TOUCH_TAP_DOWN:
            case CR_TOUCH_DRAG:
            case CR_TOUCH_TAP_UP:
                [_carot transform]->loc()->setX(SF_CLAMP(touchPos.x, 0.0f, _touchRect.size.width - LEFTRIGHTPADDING));
                [_carot transform]->compileMatrix();
                //inverse operation of earlier (above), now we take the position we have calculated and work out
                //what it's proportional value is
                _value = ([_carot transform]->loc()->x() / (_touchRect.size.width - LEFTRIGHTPADDING));
                break;
        }
        switch (touchKind) {
            case CR_TOUCH_TAP_UP:
                //the finger has been lifted and so.... relay the new setting
                [_externalDelegate widgetCallback:self reason:CR_MENU_AUX];
                break;
        }
    }
}

@end
