//
//  SFWidgetUI.m
//  ZombieArcade
//
//  Created by Adam Iredale on 22/12/09.
//  Copyright 2009 Stormforge Software. All rights reserved.
//

#import "SFWidgetUI.h"
#import "SFWidgetMenu.h"
#import "SFWidgetSlideTray.h"
#import "SFGameEngine.h"
#import "SFUtils.h"
#import "SFDebug.h"

#define DEBUG_SCENE_PICK 0

@implementation SFWidgetUI

-(void)customiseUI{
    _backButton = [[SFWidget alloc] initWidget:@"main"
                                     atlasItem:@"cornerHud"
                                      position:Vec2Make(440,0)
                                      centered:NO
                                 visibleOnShow:YES
                                  enableOnShow:YES];
    _topBar = [[SFWidget alloc] initWidget:@"main"
                                 atlasItem:@"hudBar"
                                  position:Vec2Make(0, 300)
                                  centered:NO
                             visibleOnShow:YES
                              enableOnShow:YES];
    _helpButton = [[SFWidget alloc] initWidget:@"main"
                                     atlasItem:@"helpText"
                                      position:Vec2Make(440,2)
                                      centered:NO
                                 visibleOnShow:YES
                                  enableOnShow:YES];
    [_topBar setWidgetDelegate:self];
    [_topBar addSubWidget:_helpButton];
    [_backButton setWidgetDelegate:self];
    [_helpButton setWidgetDelegate:self];
}

-(SFWidget*)topBar{
    return _topBar;
}

-(void)setTopBarOffset:(CGPoint)offset{
    //if we want a different top bar
    [_topBar setImageOffset:offset];
}

-(void)popOverlay{
    //removes the last overlay added
    [_overlays removeLastObject];
}

-(id)initUI:(NSString*)atlasName{
	self = [self initBlankWidget:Vec2Zero
                         centered:NO
                    visibleOnShow:YES
                     enableOnShow:YES];
	if (self != nil) {
        _atlasName = [atlasName retain];
        _atlas = [[[self atlm] loadAtlas:_atlasName] retain];
        [self setDimensions:CGPointMake(480, 320)];
        _menus = [[SFStack alloc] initStack:YES useFifo:NO];
        _overlays = [[NSMutableArray alloc] init];
        _renderInvisible = YES;
        [self customiseUI];
        [self updateTopBar];
	}
	return self;
}

-(void)cleanUp{
    [_menus release];
    [_overlays release];
    [_topBar release];
    [_backButton release];
    [_helpButton release];
    [_logo release];
    [_sndHelp release];
    [_sndPopMenu release];
    [super cleanUp];
}

-(id)addMenu:(SFWidget *)menu{
    [_menus push:menu];
    [menu setWidgetDelegate:self];
    //if this menu has a title, put it on the topBar
    [self updateTopBar];
    return menu;
}

-(id)addOverlay:(SFWidget *)overlay{
    [_overlays addObject:overlay];
    [overlay setWidgetDelegate:self];
    return overlay;
}

-(id)addOverlay:(NSString*)atlasName atlasItem:(NSString*)atlasItem position:(vec2)position{
    SFWidget *overlay = [[SFWidget alloc] initWidget:atlasName
                                           atlasItem:atlasItem
                                            position:position
                                            centered:NO
                                       visibleOnShow:YES
                                        enableOnShow:YES];
    [self addOverlay:overlay];
    [overlay release];
    return overlay;
}

-(void)enableLogo:(BOOL)enable{
    if ((enable) and (!_logo)) {
        _logo = [[SFWidget alloc] initWidget:@"main"
                                   atlasItem:@"logo"
                                    position:Vec2Make(0, 2)
                                    centered:NO
                               visibleOnShow:YES
                                enableOnShow:NO];
        [self addOverlay:_logo];
    } else if ((!enable) and (_logo)) {
        [_overlays removeObject:_logo];
        [_logo release];
        _logo = nil;
    }
}

-(void)updateTopBar{
    SFWidgetMenu *menu = [_menus peek];
    [_topBar removeSubWidget:_title];
    _title = nil;
    if (menu) {
        if ([menu getHelpCount] > 0) {
            [_helpButton show];
        } else {
            [_helpButton hide];
        }   
        //if the menu has a title, create the
        //topbar title widget
        if (![menu title]) {
            return;
        }
        _title = [[SFWidgetLabel alloc] initLabel:@"appleCasual16" 
                                   initialCaption:[menu title]
                                         position:Vec2Make(8,2)
                                         centered:NO
                                    visibleOnShow:YES
                                updateViaCallback:NO];
        [_topBar addSubWidget:_title];
        [_title release];
    } else {
        //set the help visibility to true if we
        //use it in the main ui (hardcoded atm)
        if (_menuHelpCount) {
            [_helpButton show];
        } else {
            [_helpButton hide];
        }        
    }

}

-(void)popMenu{
    //remove the top menu
    [_menus pop];
    if (_sndPopMenu) {
        [_sndPopMenu playAsAmbient:NO];
    }
    [self updateTopBar];
}

-(BOOL)render{
	//ui render order:
    //if no menus then subwidgets, top menu (if any), overlays
    //if menus then top menu, overlays
    SFWidgetMenu *menu = [_menus peek];
    if (menu) {
        //we have a menu - render it
        [menu render];
        //overlay the back button
        if (![menu hideBackButton]) {
            [_backButton render];
        }
    } else {
        //no menus - render the subs
        [super render];
    }
    //then the top bar (if any)
    if (_topBar) {
        [_topBar render];
    }
    //now render the any overlays
    for (SFWidget *widget in _overlays) {
        [widget render];
    }
    return YES;
}

-(BOOL)processTouchEvent:(SFTouchEvent *)touchEvent localTouchPos:(vec2)localTouchPos{
	//touch event order:
    //if overlay then overlay only (but pass it on if not processed)
    //else if menu then menu only (but pass as above)
    //else topbar (if any) and subwidgets in reverse order (inverse of draw)
    
    SFWidget *widget;
    
    for (widget in [_overlays reverseObjectEnumerator]) {
        if ([widget processTouchEvent:touchEvent localTouchPos:localTouchPos]) {
            return YES;
        }
    }
    
    SFWidgetMenu *menu = [_menus peek];
    if (menu != nil){
        if ([menu hideBackButton]){
            return [menu processTouchEvent:touchEvent localTouchPos:localTouchPos];
        } else if ([_backButton processTouchEvent:touchEvent localTouchPos:localTouchPos] or
                   [menu processTouchEvent:touchEvent localTouchPos:localTouchPos]) {
            return YES;
        }
    }
    
    if ((_topBar) and ([_topBar processTouchEvent:touchEvent localTouchPos:localTouchPos])) {
        return YES;
    }
    
    return [super processTouchEvent:touchEvent localTouchPos:localTouchPos];
}

-(void)sceneWasPicked:(SF3DObject*)pickObject pickVector:(vec3)pickVector{
    if (pickObject) {
        sfDebug(DEBUG_SCENE_PICK, "Scene Picked %s at %.2f, %.2f %.2f", 
                [pickObject UTF8Description], 
                pickVector.x,
                pickVector.y, 
                pickVector.z);
    } else {
        sfDebug(DEBUG_SCENE_PICK, "Scene Pick Missed");
    }
    //when we get notice that a scene pick has occurred, we
    //take action by checking if the top menu wants the scene pick.
    //if it does, we call back with the corresponding reason and 
    //information otherwise we use ourselves in it's place
    SFWidget *topMenu = [_menus peek];
    if (topMenu) {
        [topMenu widgetGotScenePick:topMenu pickObject:pickObject pickVector:pickVector];
    } else {
        [self widgetGotScenePick:self pickObject:pickObject pickVector:pickVector];
    }
    
}

-(BOOL)invokeHelp{
    //if we have an active menu then 
    //we invoke the help for it
    
    //first play the help sound
    if (_sndHelp) {
        [_sndHelp playAsAmbient:NO];
    }
    
    SFMenuHelp *menuHelp = nil;
    SFWidget *activeMenu = [_menus peek];
    if (activeMenu) {
        menuHelp = [activeMenu getHelp:_currentHelpIndex];
    } else {
        menuHelp = [self getHelp:_currentHelpIndex];
    }

    if (!menuHelp) {
        _currentHelpIndex = 0;
        return NO;
    } else {
        ++_currentHelpIndex;
    }

    
    //display the help
    
    NSString *helpAtlas = [NSString stringWithUTF8String:menuHelp->atlasName];
    NSString *helpName = [NSString stringWithUTF8String:menuHelp->helpName];
    vec4 helpOffset = menuHelp->helpOffset;
    
    _help = [self addOverlay:helpAtlas atlasItem:helpName position:Vec2Zero];
    //don't keep this in memory!
    [[self atlm] unloadAtlas:helpAtlas];  
    [_help startImageSequence:CGPointMake(helpOffset.x, helpOffset.y)
                    endOffset:CGPointMake(helpOffset.z, helpOffset.w) loop:NO];
    return YES;
}

-(void)addHelp:(NSString *)helpAtlas helpName:(NSString *)helpName helpOffset:(vec4)helpOffset{
    [super addHelp:helpAtlas helpName:helpName helpOffset:helpOffset];
    [self updateTopBar];
}

-(void)setPopMenuSound:(NSString*)sound{
    _sndPopMenu = [[SFSound quickPlayFetch:sound] retain];
}

-(void)setHelpSound:(NSString*)sound{
    _sndHelp = [[SFSound quickPlayFetch:sound] retain];
}

//////////////////
//SFWidgetDelegate
//////////////////

-(void)widgetWasTouched:(id)widget touchKind:(unsigned char)touchKind dragRect:(CGRect)dragRect{
    [super widgetWasTouched:widget touchKind:touchKind dragRect:dragRect];
    switch (touchKind) {
        case CR_WIDGET_PRESSED:
            if (widget == _backButton) {
                SFWidgetMenu *lastMenu = [[_menus peek] retain];
                [self popMenu];
                if ([_menus isEmpty] or [lastMenu usesBackPassthrough]) {
                    [_widgetDelegate widgetCallback:self reason:CR_MENU_BACK];
                }
                [lastMenu release];
            } else if (widget == _helpButton) {
                //display the help for the active menu or ourselves
                [self invokeHelp];
            } else if (widget == _help) {
                if (![_help nextImage]){
                    [self popOverlay];
                    //try to invoke the next help
                    [self invokeHelp];
                }
            }
            break;
        default:
            break;
    }
}

@end
