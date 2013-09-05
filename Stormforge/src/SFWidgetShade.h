//
//  SFWidgetShade.h
//  ZombieArcade
//
//  Created by Adam Iredale on 12/04/10.
//  Copyright 2010 Stormforge Software. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "SFGameObject.h"
#import "SFTransform.h"
#import "SFGL.h"
#import "SFRect.h"
#import "SFTouchEvent.h"
#import "SFMaterial.h"
#import "SFProtocol.h"

#define DEBUG_SFWIDGETSHADE 0

//callback reasons
typedef enum {
	CR_TOUCH_TAP_DOWN,
	CR_TOUCH_TAP_UP,
	CR_TOUCH_DRAG,
	CR_UPDATE_LABEL,
	CR_MENU_BACK,
	CR_MENU_HELP,
    CR_MENU_DELETE,
	CR_MENU_ITEM_TOUCHED_AUX,
	CR_MENU_AUX,
	CR_DONE,
    CR_WIDGET_PRESSED,
    CR_WIDGET_ACTIVATED,
    CR_WIDGET_DEACTIVATED,
    CR_SCENE_PICK_OBJECT,
    CR_SCENE_PICK_NOTHING,
    CR_SCENE_PICK_UNKNOWN,
    CR_YES,
    CR_NO,
    CR_CANCEL,
    CR_OVERLAYS_FINISHED,
    CR_FADE_COMPLETE,
    CR_UI_POP_MENU,
    CR_UI_POP_OVERLAY,
	CR_ALL
} CALLBACK_REASON;

typedef enum {
    wasNone,
    wasHorizontal,
    wasVertical,
    wasVerticalCentered,
    wasHorizontalCentered,
    wasAll
} SFWidgetArrangeStyle;

typedef struct {
    float left;
    float top;
    float bottom;
    float right;
} SFSimpleRect;

typedef struct {
    char atlasName[SF_MAX_CHAR];
    char helpName[SF_MAX_CHAR];
    vec4 helpOffset;
} SFMenuHelp;

//the superclass of widgets - doesn't do textures, though
//just does area, touches and colour (allowing inexpensive 
//fullscreen backdrops of single colour)
@interface SFWidgetShade : SFGameObject <SFWidgetDelegate> {
@public
    BOOL    _interestedInRollOver;
	SFMaterial *_material;      //material
    GLfloat *_vertex;                   //widget vertex information (4 points, 2 floats each)
    GLfloat *_colourArray;              //background colour info
    SFTouchEvent *_callbackUserInfo;               //call back user info - like point or target info
    id <SFWidgetDelegate>_widgetDelegate;
    NSMutableArray *_callbackReasons;   //an array of callback reasons - all run AFTER widget is finished processing the touch event
    SFTransform *_transform;
    unsigned char _lastTouchKind;   //the last kind of touch we received
    BOOL _activated; //button and activation variables
    BOOL _ignoreFocusNotification, //if we generated the focus notification we don't want to accept it
         _wantsScenePick;          //set to true to have this widget perform a scenepick from the scene
                                   //scene behind it when touched
    CGRect  _touchRect;         //the touch rectangle of the widget
    CGRect  _boundsRect;        //the bounds of this widget (graphically)
    SFSimpleRect    _margins;           //margins for subwidgets - left, top, right, bottom
    NSString *_soundActivate,
             *_soundDeactivate; //activate and deactivate soundnames
    BOOL    _visible;           //currently visible?
    BOOL    _visibleOnShow;     //are we ALLOWED to be visible when asked to be?
    BOOL    _enabled;           //currently enabled (touchable)?
    BOOL    _enableOnShow;      //are we ALLOWED (etc)
    short   _centeredX, 
            _centeredY;          //does this widget origin start at the widget center?
    BOOL    _focused;           //are we focused at the moment?
    CGRect  _dragRect;          //rectangle indicating single-finger touch and/or drag operation coordinates
    
    NSMutableArray *_subWidgets;
    int _subWidgetCount;
    BOOL _subWidgetsArranged;   //after adding or removing items, arrangeSubWidgets should be called
                                //if it is not, before we render we will check this flag and do it then
    BOOL _renderInvisible;      //some widgets (like uis) we want to render fully invisible and only do the subbies
    id  _selectedWidget;        //the currently selected subwidget (if applicable)
    SFTouchEvent *_currentTouchEvent;
    SFWidgetArrangeStyle _subWidgetArrangeStyle; //how to arrange the subbies
    SFMenuHelp *_menuHelp;
    int _menuHelpCount;
}

-(id)initShadedWidget:(vec2)position
             centered:(BOOL)centered 
        visibleOnShow:(BOOL)visibleOnShow
         enableOnShow:(BOOL)enableOnShow;
-(void)setColour:(vec4)colour;
-(void)setDimensions:(CGPoint)dim;
-(GLfloat*)newRectangularVertexArray:(CGRect)rectInfo ccw:(BOOL)ccw;
-(BOOL)processTouchEvent:(SFTouchEvent*)touchEvent localTouchPos:(vec2)localTouchPos;
-(BOOL)isInterestedInTouchPos:(vec2)touchPos touchKind:(unsigned char)touchKind wasInTouchRect:(BOOL)wasInTouchRect;

-(void)preDraw;
-(void)draw;
-(void)postDraw;

-(void)setVisibleOnShow:(BOOL)visibleOnShow;
-(void)setEnableOnShow:(BOOL)enableOnShow;

-(void)loseFocus:(id)notification;

-(CGRect)dragRect;

-(void)setWantsScenePick:(BOOL)wantsPick;
-(BOOL)render;
-(void)setWidgetDelegate:(id<SFWidgetDelegate>)delegate;


-(void)show;
-(void)hide;

-(SFTransform*)transform;

-(id)callbackUserInfo;

-(void)setSubWidgetArrangeStyle:(SFWidgetArrangeStyle)style;
-(void)setVisible:(BOOL)visible;
-(void)setEnabled:(BOOL)enabled;

-(void)setCentered:(BOOL)centered;
-(void)setCenteredX:(BOOL)centered;
-(void)setCenteredY:(BOOL)centered;

-(void)setMargins:(float)horizontal vertical:(float)vertical;
-(void)setMargins:(float)left top:(float)top right:(float)right bottom:(float)bottom;

-(BOOL)visible;
-(BOOL)enabled;

-(CGRect)boundsRect;
-(CGRect)touchRect;

-(SFMaterial*)material;
-(void)setFadeOut:(float)solid fadeOut:(float)fadeOut;
-(void)resetFadeOut;

-(id)addSubWidget:(SFWidgetShade*)widget;
-(void)removeAllSubWidgets;
-(void)removeSubWidget:(SFWidgetShade*)widget;
-(void)arrangeSubWidgets;
-(SFTouchEvent*)touchEvent;

+(char*)translateCallback:(unsigned char)callback;

-(void)setInterestedInRollOver:(BOOL)interested;
-(void)resetTouch;

-(void)addHelp:(NSString*)helpAtlas helpName:(NSString*)helpName helpOffset:(vec4)helpOffset;
-(int)getHelpCount;
-(SFMenuHelp*)getHelp:(int)index;

@end
