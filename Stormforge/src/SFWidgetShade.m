//
//  SFWidgetShade.m
//  ZombieArcade
//
//  Created by Adam Iredale on 12/04/10.
//  Copyright 2010 Stormforge Software. All rights reserved.
//

#import "SFWidgetShade.h"
#import "SFUtils.h"
#import "SFSound.h"
#import "SFMaterial.h"
#import "SFDebug.h"

@implementation SFWidgetShade

-(void)widgetWillShow:(id)widget{
    if (_widgetDelegate == self) {
        return;
    }
    [_widgetDelegate widgetWillShow:widget];
}

-(void)widgetDidShow:(id)widget{
    if (_widgetDelegate == self) {
        return;
    }
    [_widgetDelegate widgetDidShow:widget];
}

-(void)widgetWillHide:(id)widget{
    if (_widgetDelegate == self) {
        return;
    }
    [_widgetDelegate widgetWillHide:widget];
}

-(void)widgetDidHide:(id)widget{
    if (_widgetDelegate == self) {
        return;
    }
    [_widgetDelegate widgetDidHide:widget];
}

-(void)widgetCallback:(id)widget reason:(unsigned char)reason{
    if (_widgetDelegate == self) {
        return;
    }
    [_widgetDelegate widgetCallback:widget reason:reason];
}

-(void)widgetGotScenePick:(id)widget pickObject:(id)pickObject pickVector:(vec3)pickVector{
    if (_widgetDelegate == self) {
        return;
    }
    [_widgetDelegate widgetGotScenePick:widget pickObject:pickObject pickVector:pickVector];
}

-(void)widgetWasTouched:(id)widget touchKind:(unsigned char)touchKind dragRect:(CGRect)dragRect{
    if (_widgetDelegate == self) {
        return;
    }
    [_widgetDelegate widgetWasTouched:widget touchKind:touchKind dragRect:dragRect];
}

-(CGRect)touchRect{
    return _touchRect;
}

-(CGRect)dragRect{
    return _dragRect;
}

-(void)resetTouch{
    //reset touch to it's initial state
    _lastTouchKind = TOUCH_EVENT_ENDED;
}

-(void)addHelp:(NSString*)helpAtlas helpName:(NSString*)helpName helpOffset:(vec4)helpOffset{
    _menuHelp = (SFMenuHelp*)realloc(_menuHelp, (_menuHelpCount + 1) * sizeof(SFMenuHelp));
    strcpy(_menuHelp[_menuHelpCount].atlasName, [helpAtlas UTF8String]);
    strcpy(_menuHelp[_menuHelpCount].helpName, [helpName UTF8String]);
    memcpy(&_menuHelp[_menuHelpCount].helpOffset, &helpOffset, sizeof(vec4));
    ++_menuHelpCount;
}

-(SFMenuHelp*)getHelp:(int)index{
    if (index < _menuHelpCount) {
        return &_menuHelp[index];
    }
    return nil;
}

-(int)getHelpCount{
    return _menuHelpCount;
}

-(void)addCallbackReason:(unsigned char)reason{
    [_callbackReasons addObject:[NSNumber numberWithUnsignedChar:reason]];
}

-(void)fadeOutComplete:(id)notify{
    [self stopNotify:[notify name]];
    [self hide];
    [_widgetDelegate widgetCallback:self reason:CR_FADE_COMPLETE]; //the fade is done
}

-(void)setFadeOut:(float)solid fadeOut:(float)fadeOut{
    [self resetFadeOut];
    [self notifyMe:SF_NOTIFY_MATERIAL_FINISHED_FADE selector:@selector(fadeOutComplete:) object:[self material]];
    [_material setFadeOut:solid fadeOut:fadeOut];
}

-(void)resetFadeOut{
    [_material resetFadeOut];
    [self show];
}

-(void)setEnabled:(BOOL)enabled{
    _enabled = enabled;
}

-(BOOL)focused{
    return _focused;
}

-(void)setFocus{
    if (_focused) {
        return;
    }
	_focused = YES;
    _ignoreFocusNotification = YES;
    [[NSNotificationCenter defaultCenter] postNotificationName:SF_NOTIFY_WIDGET_BECAME_FOCUSED
                                                        object:nil];
}

-(void)loseFocus:(id)notification{
    if (!_focused) {
        return;
    }
    if (_ignoreFocusNotification) {
        _ignoreFocusNotification = NO;
        return;
    }
	_focused = NO;
}

-(void)setInterestedInRollOver:(BOOL)interested{
    _interestedInRollOver = interested;
}

-(BOOL)isInterestedInTouchPos:(vec2)touchPos touchKind:(unsigned char)touchKind wasInTouchRect:(BOOL)wasInTouchRect{
	//if we are not enabled, we don't care
	if (!_enabled) {
		return NO;
	}
    
	//typically we are interested in any first touches (tap down) that are in
    //our touch rectangle and any other touches that follow if the
    //last touch was a first touch
    
    if (_interestedInRollOver) {
        //rollover-interested widgets behave differently than normal widgets
        //they are interested in only events in their own touch rectangle
        return wasInTouchRect;
    } else {
        //normal widgets are interested in first touches in their touch rect
        //and any others that follow
        if ((_lastTouchKind != TOUCH_EVENT_ENDED) or 
            ((touchKind == TOUCH_EVENT_BEGAN) and wasInTouchRect)) {
            return YES;
        }
    }
    return NO;
}

-(GLfloat*)newRectangularVertexArray:(CGRect)rectInfo ccw:(BOOL)ccw{
    GLfloat *va = (GLfloat*)malloc(8 * sizeof(GLfloat));
    int incrementor = 2;
    int index = 0;
    if (!ccw) {
        incrementor = -2;
        index = 6;
    }
    va[index] = rectInfo.origin.x;
    va[index+1] = rectInfo.origin.y;
    index += incrementor;
    va[index] = rectInfo.origin.x + rectInfo.size.width;
    va[index+1] = rectInfo.origin.y;
    index += incrementor;
    va[index] = rectInfo.origin.x + rectInfo.size.width;
    va[index+1] = rectInfo.origin.y + rectInfo.size.height;
    index += incrementor;
    va[index] = rectInfo.origin.x;
    va[index+1] = rectInfo.origin.y + rectInfo.size.height;
    return va;
}

-(SFMaterial*)material{
	return _material;
}

-(id)initShadedWidget:(vec2)position
             centered:(BOOL)centered 
        visibleOnShow:(BOOL)visibleOnShow
         enableOnShow:(BOOL)enableOnShow{
    self = [self initWithDictionary:nil];
    if (self != nil) {
        _transform = new SFTransform();
        _transform->loc()->setVec2(position);
        _transform->compileMatrix();
        _enableOnShow = enableOnShow;
        _visibleOnShow = visibleOnShow;
        _callbackReasons = [[NSMutableArray alloc] init];
        _lastTouchKind = TOUCH_EVENT_ENDED;
		[self setCentered:centered];
        _material = [[SFMaterial alloc] initWithName:[[self name] stringByAppendingString:@"_material"] dictionary:nil];
        [_material setBlend:SF_MATERIAL_COLOR];
        [self show];
    }
    return self;
}

-(SFTouchEvent*)callbackUserInfo{
    return _callbackUserInfo;
}

-(void)setCenteredX:(BOOL)centered{
    if (centered) {
        _centeredX = 1;
    } else {
        _centeredX = 0;
    }
}

-(void)setCenteredY:(BOOL)centered{
    if (centered) {
        _centeredY = 1;
    } else {
        _centeredY = 0;
    }
}


-(void)setCentered:(BOOL)centered{
	[self setCenteredX:centered];
    [self setCenteredY:centered];
}


-(void)setColour:(vec4)colour{
    _colourArray = (GLfloat*)realloc(_colourArray, (sizeof(GLfloat) * 16));
    memcpy(&_colourArray[0], &colour, sizeof(vec4));
    memcpy(&_colourArray[4], &colour, sizeof(vec4));
    memcpy(&_colourArray[8], &colour, sizeof(vec4));
    memcpy(&_colourArray[12], &colour, sizeof(vec4));
}



-(void)cleanUp{
    if (_vertex) {
        free(_vertex);
        _vertex = nil;
    }
    if (_colourArray) {
        free(_colourArray);
        _colourArray = nil;
    }
    [_callbackReasons release];
    [_material release];
    [_widgetDelegate release];
    delete _transform;
    if (_menuHelp) {
        delete _menuHelp;
    }
    [super cleanUp];
}

-(void)setWidgetDelegate:(id<SFWidgetDelegate>)delegate{
	[_widgetDelegate release];
    _widgetDelegate = [delegate retain];
}

-(SFTransform*)transform{
	return _transform;
}

-(void)setVisibleOnShow:(BOOL)visibleOnShow{
	_visibleOnShow = visibleOnShow;
}

-(void)setEnableOnShow:(BOOL)enableOnShow{
	_enableOnShow = enableOnShow;
}

-(BOOL)visibleOnShow{
	return _visibleOnShow;
}

-(BOOL)enableOnShow{
	return _enableOnShow;
}

-(void)setVisible:(BOOL)visible{
    if (_visible == visible) {
        return;
    }
    if (visible) {
        [_widgetDelegate widgetWillShow:self];
    } else {
        [_widgetDelegate widgetWillHide:self];
    }
	_visible = visible;
    if (visible) {
        [_widgetDelegate widgetDidShow:self];
    } else {
        [_widgetDelegate widgetDidHide:self];
    }
}

-(BOOL)enabled{
	return _enabled;
}

-(BOOL)visible{
	return _visible;
}

-(void)show{
	if (_visibleOnShow) {
		[self setVisible:YES];
	}
	if (_enableOnShow) {
		[self setEnabled:YES];
	}
}

-(void)hide{
	[self setEnabled:NO];
	[self setVisible:NO];
}

-(CGRect)boundsRect{
    //returns the bounds rect except that it's at the
    //transform position
    GLfloat x = _transform->loc()->x(),
    y = _transform->loc()->y();
    
    x -= (_centeredX * _boundsRect.size.width / 2.0f);
    y -= (_centeredY * _boundsRect.size.height / 2.0f);
    
    return CGRectMake(x,
                      y,
                      _boundsRect.size.width,
                      _boundsRect.size.height);
}

-(void)setDimensions:(CGPoint)dim{
    _boundsRect.size.width = dim.x;
    _boundsRect.size.height = dim.y;
    //at this stage we can copy the bounds rect dims for the touch rect
    _touchRect.size.width = dim.x;
    _touchRect.size.height = dim.y;
    if (_vertex) {
        free(_vertex);
    }
    _vertex = [self newRectangularVertexArray:CGRectMake(0, 0, _boundsRect.size.width, _boundsRect.size.height) ccw:YES];
}

-(void)preDraw{
    //after we have pushed the matrix but before we draw
    [_material render];
    if (_colourArray) {
        SFGL::instance()->glEnableClientState(GL_COLOR_ARRAY);
        glColorPointer(4, GL_FLOAT, 0, (const GLfloat*)_colourArray);
    }
}

-(void)postDraw{
    //before we pop the matrix, after the draw
    if (_colourArray) {
        SFGL::instance()->glDisableClientState(GL_COLOR_ARRAY);
    } 
}

-(void)draw{
    SFGL::instance()->glDrawArrays(GL_TRIANGLE_FAN, 0, 4);
#if DEBUG_SFWIDGETSHADE
    //also draw a red box around the edge of the widget
    SFGL::instance()->materialReset();
    SFGL::instance()->glDisable(GL_BLEND);
    SFGL::instance()->setBlendMode(SF_MATERIAL_SCREEN);
    glLineWidth(3.0f);
    SFGL::instance()->glColor4f(COLOUR_SOLID_RED);
    SFGL::instance()->glDrawArrays(GL_LINE_LOOP, 0, 4);
    //also draw a blue box around the edge of the touch area
    glLineWidth(1.0f);
    GLfloat *touchArea = (GLfloat[]){_touchRect.origin.x, _touchRect.origin.y, 
        _touchRect.origin.x + _touchRect.size.width, _touchRect.origin.y,
        _touchRect.origin.x + _touchRect.size.width, _touchRect.origin.y + _touchRect.size.height,
        _touchRect.origin.x, _touchRect.origin.y + _touchRect.size.height};
    SFGL::instance()->glVertexPointer(2, GL_FLOAT, 0, (const GLfloat*)touchArea);
    SFGL::instance()->glColor4f(COLOUR_SOLID_BLUE);
    SFGL::instance()->glDrawArrays(GL_LINE_LOOP, 0, 4);
    [_material render];
#endif
}

-(BOOL)render{
    [SFUtils assertGlContext];
    if (!_visible){
        return NO;
    }
    
    SFGL::instance()->glPushMatrix();
    {
        if (!_renderInvisible) {
            //_transform->applyTransform();
            _transform->multMatrix();
            
            SFGL::instance()->glVertexPointer(2, GL_FLOAT, 0, (const GLfloat*)_vertex);
            
            //move by half width and height if needed
            SFGL::instance()->glTranslatef(-_centeredX * _boundsRect.size.width / 2.0f,
                                           -_centeredY * _boundsRect.size.height / 2.0f, 
                                           0.0f);
            
            [self preDraw];
            
            [self draw];
            
            [self postDraw];
        }
        //and process any subs using our current offset on screen as a base
        if (_subWidgetCount) {
            //arrange if not already done
            if (!_subWidgetsArranged) {
                [self arrangeSubWidgets];
            }
            for (int i = 0; i < _subWidgetCount; ++i) {
                SFWidgetShade *widget = [[_subWidgets objectAtIndex:i] retain];
                [widget render];
                [widget release];
            }
        }
        SFGL::instance()->glPopMatrix();	
    }
    
    
    return YES;
}

-(BOOL)activated{
    return _activated;
}

-(void)activate:(BOOL)doActivate{
    _activated = doActivate;
    if (_activated) {
        [SFSound quickPlayAmbient:_soundActivate];
        [self addCallbackReason:CR_WIDGET_ACTIVATED];
    } else {
        [SFSound quickPlayAmbient:_soundDeactivate];
        [self addCallbackReason:CR_WIDGET_DEACTIVATED];
    }
    
}

-(void)setWantsScenePick:(BOOL)wantsPick{
    //if this is set true, the widget will
    //collect scene-pick data when offered it
    _wantsScenePick = wantsPick;
}

-(void)widgetTapDown{
	[self addCallbackReason:CR_TOUCH_TAP_DOWN];
    //works just like a momentary toggle
    if (!_activated) {
        [self activate:YES];
    }
}
-(void)widgetTapUp:(BOOL)wasInTouchRect{
	[self addCallbackReason:CR_TOUCH_TAP_UP];
    //a tap up anywhere means deactivation for now
    if (_activated) {
        [self activate:NO];
    }
    //if the up occurred in our touch rect then
    //we can consider ourselves pressed (down then up)
    if (wasInTouchRect) {
        [self addCallbackReason:CR_WIDGET_PRESSED];
    }
}

-(void)widgetTouchMove:(BOOL)wasInTouchRect{
	[self addCallbackReason:CR_TOUCH_DRAG];
    //if the drag was out of our touch rect then
    //consider ourselves deactivated and vice versa
    if (wasInTouchRect) {
        if (!_activated) {
            [self activate:YES];
        }
    } else {
        if (_activated) {
            [self activate:NO];
        }
    }

}

-(SFTouchEvent*)touchEvent{
    //returns the current touch event
    return _currentTouchEvent;
}

-(void)widgetWasActivated:(SFTouchEvent*)touchEvent{
    //children
}

-(void)runCallbacks:(SFTouchEvent*)touchEvent{
    _currentTouchEvent = [touchEvent retain];
    for (id reason in _callbackReasons) {
        unsigned char callbackReason = [reason unsignedCharValue];
        switch (callbackReason) {
            case CR_TOUCH_TAP_DOWN:
            case CR_TOUCH_TAP_UP:
            case CR_TOUCH_DRAG:
            case CR_WIDGET_PRESSED:
            case CR_WIDGET_ACTIVATED:
            case CR_WIDGET_DEACTIVATED:
                [_widgetDelegate widgetWasTouched:self touchKind:callbackReason dragRect:(CGRect)_dragRect];
                break;
            default:
                [_widgetDelegate widgetCallback:self reason:callbackReason];
                break;
        }
    }
    [_callbackReasons removeAllObjects];
    [_currentTouchEvent release];
    _currentTouchEvent = nil;
}

-(void)registerForNotifications{
    [super registerForNotifications];
    //when a widget gains focus we need to lose it
    [self notifyMe:SF_NOTIFY_WIDGET_BECAME_FOCUSED
          selector:@selector(loseFocus:)];
}

-(BOOL)processTouchEvent:(SFTouchEvent*)touchEvent localTouchPos:(vec2)localTouchPos{
    
    //localise it by offsetting our loc transform
    localTouchPos.x -= _transform->loc()->x();
    localTouchPos.y -= _transform->loc()->y();
    
    if (_centeredX) {
        localTouchPos.x += _boundsRect.size.width / 2.0f;
    }
    
    if (_centeredY) {
        localTouchPos.y += _boundsRect.size.height / 2.0f;
    }
    
    //if the last touch event we received was a touch down
    //or drag
    //then yes, we are interested in this event, provided
    //it's not a touch down
    
    
    //if we have sub widgets, always evaluate them first,
    //as they are drawn on top of us
    //and process any subs
    
    if (_subWidgetCount) {
        for (int i = _subWidgetCount - 1; i >= 0; --i) {
            SFWidgetShade *widget = [[_subWidgets objectAtIndex:i] retain];
            if ([widget processTouchEvent:touchEvent localTouchPos:localTouchPos]) {
                return YES;
            }
            [widget release];
        }
    }
    
    BOOL wasInTouchRect = CGRectContainsPoint(_touchRect, CGPointMake(localTouchPos.x, localTouchPos.y));
    
    if (![self isInterestedInTouchPos:localTouchPos touchKind:[touchEvent touchKind] wasInTouchRect:wasInTouchRect]) {
        [self loseFocus:nil];
        return false;
    }
    
	//ok, so we're interested.
    sfDebug(TRUE, "%s is interested in touch at %.2f %.2f", [self UTF8Description], localTouchPos.x, localTouchPos.y);
    //show that we are focused
	[self setFocus];
    
    //set where we were touched
    //and handle the event
    
	switch ([touchEvent touchKind]) {
		case TOUCH_EVENT_BEGAN:
            memcpy(&_dragRect.origin, &localTouchPos, sizeof(vec2));
			[self widgetTapDown];
			break;
		case TOUCH_EVENT_ENDED:
            _dragRect.size.width = localTouchPos.x - _dragRect.origin.x;
            _dragRect.size.height = localTouchPos.y - _dragRect.origin.y;
            [self widgetTapUp:wasInTouchRect];
			break;
		case TOUCH_EVENT_MOVED:
            _dragRect.size.width = localTouchPos.x - _dragRect.origin.x;
            _dragRect.size.height = localTouchPos.y - _dragRect.origin.y;
			[self widgetTouchMove:wasInTouchRect];
			break;
		default:
			break;
	}
    
    //leave all our callbacks until last
    //our callbacks might release us - ensure we
    //finish them all
    [self retain];
    [self runCallbacks:touchEvent]; //could do this faster if we used a bitmask... later
    
    //so that we know what state we are in
    _lastTouchKind = [touchEvent touchKind];
    
    [self release];
	return true; //we have handled this - noone else should bother
}

-(id)addSubWidget:(SFWidgetShade*)widget{
    if (!_subWidgets) {
        _subWidgets = [[NSMutableArray alloc] init];
    }
    [_subWidgets addObject:widget];
    [widget setWidgetDelegate:self];
    ++_subWidgetCount;
    _subWidgetsArranged = NO;
    return widget;
}

-(void)removeAllSubWidgets{
    _subWidgetCount = 0;
    [_subWidgets removeAllObjects];
}

-(void)removeSubWidget:(SFWidgetShade*)widget{
    if ([_subWidgets containsObject:widget]) {
        --_subWidgetCount;
        [_subWidgets removeObject:widget];
        //[widget hide];
        _subWidgetsArranged = NO;
    }
}

-(void)arrangeSubWidgetsHorizontal:(BOOL)centered{
    //lay 'em
	int i = 0; //multiplier counter
    int centerOffset = 0;
    if (centered) {
        centerOffset = (_boundsRect.size.height - (_margins.top + _margins.bottom)) / 2.0f;
    }
	int eachWidth = (_boundsRect.size.width - (_margins.right + _margins.left)) / ([_subWidgets count] + 1); //how much room each icon takes up laterally
	NSEnumerator *enumerator = [_subWidgets objectEnumerator];
	for (SFWidgetShade *widget in enumerator){
		[widget setCenteredX:YES];
        [widget setCenteredY:centered];
        [widget transform]->loc()->setX(_margins.left + (eachWidth * (i + 1.0f)));
        [widget transform]->loc()->setY(_margins.bottom + centerOffset);
        [widget transform]->compileMatrix();
		++i;
	}
}

-(void)setMargins:(float)left top:(float)top right:(float)right bottom:(float)bottom{
    //allows finer tuning of margins
    _margins.left = left;
    _margins.bottom = bottom;
    _margins.right = right;
    _margins.top = top;
}


-(void)setMargins:(float)horizontal vertical:(float)vertical{
    //assumes center placement and identical margins
    [self setMargins:horizontal top:vertical right:horizontal bottom:vertical];
}

-(void)arrangeSubWidgetsVertical:(BOOL)centered{
    //stack 'em
    int i = 0; //multiplier counter
    int centerOffset = 0;
    if (centered) {
        centerOffset = (_boundsRect.size.width - (_margins.left + _margins.right))/ 2.0f;
    }
    int eachHeight = (_boundsRect.size.height - (_margins.bottom + _margins.top)) / ([_subWidgets count] + 1);
	//bottom up stacking
    for (SFWidgetShade *widget in [_subWidgets reverseObjectEnumerator]){
        [widget setCenteredX:centered];
        [widget setCenteredY:YES];
		[widget transform]->loc()->setX(_margins.left + centerOffset);
        [widget transform]->loc()->setY(_margins.bottom + (eachHeight * (i + 1.0f)));
		[widget transform]->compileMatrix();
        ++i;
	}
}

-(void)arrangeSubWidgets{
    switch (_subWidgetArrangeStyle) {
        case wasHorizontal:
            [self arrangeSubWidgetsHorizontal:NO];
            break;
        case wasVertical:
            [self arrangeSubWidgetsVertical:NO];
            break;
        case wasVerticalCentered:
            [self arrangeSubWidgetsVertical:YES];
            break;
        case wasHorizontalCentered:
            [self arrangeSubWidgetsHorizontal:YES];
            break;
        default:
            break;
    }
    _subWidgetsArranged = YES;
}

-(void)setSubWidgetArrangeStyle:(SFWidgetArrangeStyle)style{
    _subWidgetArrangeStyle = style;
}

+(char*)translateCallback:(unsigned char)callback{
    switch (callback) {
        case CR_TOUCH_TAP_DOWN:
            return "CR_TOUCH_TAP_DOWN";
            break;
        case CR_TOUCH_TAP_UP:
            return "CR_TOUCH_TAP_UP";
            break;
        case CR_TOUCH_DRAG:
            return "CR_TOUCH_DRAG";
            break;
        case CR_UPDATE_LABEL:
            return "CR_UPDATE_LABEL";
            break;
        case CR_MENU_BACK:
            return "CR_MENU_BACK";
            break;
        case CR_MENU_HELP:
            return "CR_MENU_HELP";
            break;
        case CR_MENU_ITEM_TOUCHED_AUX:
            return "CR_MENU_ITEM_TOUCHED_AUX";
            break;
        case CR_MENU_AUX:
            return "CR_MENU_AUX";
            break;
        case CR_DONE:
            return "CR_DONE";
            break;
        case CR_WIDGET_PRESSED:
            return "CR_WIDGET_PRESSED";
            break;
        case CR_WIDGET_ACTIVATED:
            return "CR_WIDGET_ACTIVATED";
            break;
        case CR_WIDGET_DEACTIVATED:
            return "CR_WIDGET_DEACTIVATED";
            break;
        case CR_SCENE_PICK_OBJECT:
            return "CR_SCENE_PICK_OBJECT";
            break;
        case CR_YES:
            return "CR_YES";
            break;
        case CR_NO:
            return "CR_NO";
            break;
        case CR_CANCEL:
            return "CR_CANCEL";
            break;
        case CR_OVERLAYS_FINISHED:
            return "CR_OVERLAYS_FINISHED";
            break;
        case CR_FADE_COMPLETE:
            return "CR_FADE_COMPLETE";
            break;
        case CR_UI_POP_MENU:
            return "CR_UI_POP_MENU";
            break;
        case CR_UI_POP_OVERLAY:
            return "CR_UI_POP_OVERLAY";
            break;
        default:
            return "<UNKNOWN>";
            break;
    }
}

@end
