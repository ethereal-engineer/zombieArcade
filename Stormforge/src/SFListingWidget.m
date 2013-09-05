//
//  SFMultiWidget.m
//  ZombieArcade
//
//  Created by Adam Iredale on 3/12/09.
//  Copyright 2009 Stormforge Software. All rights reserved.
//

#import "SFListingWidget.h"
#import "SFGameEngine.h"
#import "SFSound.h"
#import "SFUtils.h"

#define LISTING_HEADER_LBL @"_header"
#define LISTING_DESC_LBL @"_description"

#define TEXT_Y_GAP 16

#define DEFAULT_LISTING_PREV_IMAGE @"3dArrowLeft.tga"
#define DEFAULT_LISTING_NEXT_IMAGE @"3dArrowRight.tga"
#define DEFAULT_NAV_CTL_TOUCH_AREA [SFRect rectWithPosition:SF_VECTOR_ZERO width:32 height:64 centered:NO]

#define DEFAULT_LISTING_FONT @"scoreFont16x16.tga"

#define HEADER_POSITION_WITH_ITEMS Vec2Make(152, 245)
#define HEADER_POSITION_WITH_NO_ITEMS Vec2Make(240, 170)

@implementation SFListingWidget

-(BOOL)listingIsEnabled:(NSDictionary*)listing{
    return [[SFGameEngine getLocalPlayer] achievementIsUnlocked:[listing objectForKey:@"unlockableObjectId"]];
}

-(void)updateListing{
    if (_listingIndex == -1) {
        return;
    }
	NSDictionary *li = [_listingItems objectAtIndex:_listingIndex];

    [_listingImage setImageOffset:CGPointFromString([li objectForKey:@"icon"])];
    
    if ([self listingIsEnabled:li]){
        //enabled by default but if this is disabled, render it so
        [[_listingImage material] setDrawDisabled:NO];
        [_listingImage setEnabled:YES];
        NSString *titleCaption = [li objectForKey:@"title"];
        if (_showListingNumbers) {
            titleCaption = [titleCaption stringByAppendingFormat:@" (%u/%u)", (_listingIndex + 1), [_listingItems count]];
        }
        [_listingHeader setCaption:titleCaption];
    } else {
        [[_listingImage material] setDrawDisabled:YES];
        [_listingImage setEnabled:NO];
        [_listingHeader setCaption:[[li objectForKey:@"title"] stringByAppendingString:@" [LOCKED]"]];
    }
         
	[_listingDescription setCaption:[li objectForKey:@"description"]]; 
	_currentItem = li;
    [SFSound quickPlayAmbient:@"camera2.ogg"];
}

-(BOOL)hasNext{
	return (_listingIndex < ((int)[_listingItems count] - 1));
}

-(id)getSelectedItem{
    return _currentItem;
}

-(BOOL)hasPrev{
	return (_listingIndex > 0);
}

-(void)next{
	if ([self hasNext]) {
		++_listingIndex;
		[self updateListing];
	} else {
		[self first];
	}
}

-(void)first{
	_listingIndex = -1;
	if ([_listingItems count] > 0) {
		[self next];
	}
}

-(void)last{
	_listingIndex = [_listingItems count];
	if ([_listingItems count] > 0) {
		[self prev];
	} else {
        _listingIndex = -1;
    }

}

-(void)prev{
	if ([self hasPrev]) {
		--_listingIndex;
		[self updateListing];
	} else {
		[self last];
	}

}

-(void)deleteSelectedItem{
    //removes the selected item from the listings area and
    //steps to the prior widget - if none, then reverts to the
    //blank screen version
    [_listingItems removeObjectAtIndex:_listingIndex];
    [self prev];
    if (_listingIndex == -1) {
        //no more!
        //move the header to it's temporary positional use as the "no items" label
        [_listingHeader transform]->loc()->setVec2(HEADER_POSITION_WITH_NO_ITEMS);
        [_listingHeader transform]->compileMatrix();
        [_listingHeader setCentered:YES];
        [_listingHeader setJustification:ljCenter];
        [_listingHeader setCaption:_blankCaption];
        //hide the delete button
        if (_btnDelete) {
            [_btnDelete hide];
        }
    }
}

-(void)setupSubComponents:(NSString*)atlasName iconItem:(NSString*)iconItem{
    _listingImage = [[SFWidget alloc] initWidget:atlasName
                                       atlasItem:iconItem
                                        position:Vec2Make(8, 121)
										centered:NO
								   visibleOnShow:YES
								   enableOnShow:YES];
	
	_listingHeader = [[SFWidgetLabel alloc] initLabel:@"appleCasual16"
								   initialCaption:_blankCaption
										 position:HEADER_POSITION_WITH_NO_ITEMS
                                             centered:YES
									visibleOnShow:YES
								updateViaCallback:NO];
    [_listingHeader setJustification:ljCenter];
	
	_listingDescription = [[SFWidgetLabel alloc] initLabel:@"appleCasual16"
										initialCaption:@" "
											  position:Vec2Make(152, 220)
                                                  centered:NO
										 visibleOnShow:YES
									 updateViaCallback:NO];
	
	_prevControl = [[SFWidget alloc] initWidget:@"main"
                                      atlasItem:@"arrows"
									   position:Vec2Make(8, 50)
									   centered:NO
								  visibleOnShow:YES
								  enableOnShow:YES];
	
	_nextControl = [[SFWidget alloc] initWidget:@"main"
                                      atlasItem:@"arrows"
									   position:Vec2Make(440, 50)
									   centered:NO
								  visibleOnShow:YES
                                   enableOnShow:YES];
    [_nextControl setImageOffset:CGPointMake(1, 0)];
	_listingItems = [[NSMutableArray alloc] init];
	_listingIndex = -1;
    
    //setup delegate
    [_listingImage setWidgetDelegate:self];
    [_listingHeader setWidgetDelegate:self];
    [_listingDescription setWidgetDelegate:self];
    [_prevControl setWidgetDelegate:self];
    [_nextControl setWidgetDelegate:self];
}

-(id)initListingWidget:(NSString*)atlasName iconItem:(NSString*)iconItem blankCaption:(NSString*)blankCaption{
	self = [super initMenu:atlasName];
	if (self != nil) {
        _subWidgetArrangeStyle = wasNone;
        _blankCaption = [blankCaption retain];
		[self setupSubComponents:atlasName iconItem:iconItem];
	}
	return self;    
}

-(void)cleanUp{
    [_blankCaption release];
    [_prevControl release];
	[_nextControl release];
	[_listingHeader release];
	[_listingDescription release];
	[_listingItems release];
    [super cleanUp];
}

-(void)addListingItem:(id)listingItem{
    if ([_listingItems count] == 0) {
        //move the header from it's temporary positional use as the "no items" label
        [_listingHeader transform]->loc()->setVec2(HEADER_POSITION_WITH_ITEMS);
        [_listingHeader transform]->compileMatrix();
        [_listingHeader setCentered:NO];
        [_listingHeader setJustification:ljLeft];
        //show the delete button (if applicable)
        if (_btnDelete) {
            [_btnDelete show];
        }
    }    
    [_listingItems addObject:listingItem];
    [self first];
}

-(BOOL)processTouchEvent:(SFTouchEvent *)touchEvent localTouchPos:(vec2)localTouchPos{
	//pass touch events to our items
	BOOL processed = [_listingImage processTouchEvent:touchEvent localTouchPos:localTouchPos];
	if (!processed) {
		processed = [_prevControl processTouchEvent:touchEvent localTouchPos:localTouchPos];
	}
	if (!processed) {
		processed = [_nextControl processTouchEvent:touchEvent localTouchPos:localTouchPos];
	}
	if (!processed) {
        processed = [super processTouchEvent:touchEvent localTouchPos:localTouchPos];
    }
    return processed;
}

-(void)showListingNumbers:(BOOL)show{
    _showListingNumbers = show;
}

-(void)showDeleteButton:(BOOL)show{
    _showDeleteButton = show;
    if ((show) and (!_btnDelete)) {
        //create the delete button only when needed
        _btnDelete = [self addButton:CGPointMake(5, 0) largeButton:YES];
        [_btnDelete transform]->loc()->setVec2(Vec2Make(240, 90));
        [_btnDelete transform]->compileMatrix();
        [_btnDelete hide];
    }
}

-(BOOL)render{
    if (![self visible]){
        return NO;
    }
	BOOL renderedOk = [super render];
    renderedOk = [_listingHeader render] or renderedOk;
    if (_listingIndex < 0) {
        return renderedOk;
    }
    renderedOk = [_listingImage render] or renderedOk;
    renderedOk = [_listingDescription render] or renderedOk;
    renderedOk = [_prevControl render] or renderedOk;
    renderedOk = [_nextControl render] or renderedOk;
    return renderedOk;
}

//////////////////
//SFWidgetDelegate
//////////////////

-(void)widgetWasTouched:(id)widget touchKind:(unsigned char)touchKind dragRect:(CGRect)dragRect{
    [super widgetWasTouched:widget touchKind:touchKind dragRect:dragRect];
    switch (touchKind) {
        case CR_WIDGET_PRESSED:
            if (widget == _nextControl) {
                [self next];
            } else if (widget == _prevControl) {
                [self prev];
            } else if (widget == _listingImage) {
                [_widgetDelegate widgetCallback:self reason:CR_MENU_ITEM_TOUCHED_AUX];
            } else if (widget == _btnDelete) {
                [_widgetDelegate widgetCallback:self reason:CR_MENU_DELETE];
            }
            break;
        default:
            break;
    }
}

@end
