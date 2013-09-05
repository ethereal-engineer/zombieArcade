//
//  SFMultiWidget.h
//  ZombieArcade
//
//  Created by Adam Iredale on 3/12/09.
//  Copyright 2009 Stormforge Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SFWidgetMenu.h"
#import "SFWidgetLabel.h"
#import "SFProtocol.h"

@interface SFListingWidget : SFWidgetMenu {
	//the listing widget holds multiple
	//"listings" - which are an image file
	//and a text description - these are
	//laid out left to right
	
	//the images have to be a certain size
	//and the text should be previewed to
	//fit properly
	
	//previous and next cycle through the
	//listings
	NSMutableArray *_listingItems;
	int _listingIndex;
	SFWidgetLabel *_listingHeader, *_listingDescription;
	NSString *_currentText, *_currentTitle, *_blankCaption;
	SFWidget *_prevControl, *_nextControl, *_listingImage, *_btnDelete;
	id _currentItem;
    BOOL _showListingNumbers,
         _showDeleteButton;
}

-(id)initListingWidget:(NSString*)atlasName iconItem:(NSString*)iconItem blankCaption:(NSString*)blankCaption;
-(void)addListingItem:(id)listingItem;
-(id)getSelectedItem;
-(void)deleteSelectedItem;
-(void)first;
-(void)prev;
-(void)last;
-(void)next;
-(void)showListingNumbers:(BOOL)show;
-(void)showDeleteButton:(BOOL)show;

@end
