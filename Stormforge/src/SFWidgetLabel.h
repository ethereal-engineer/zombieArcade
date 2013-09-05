//
//  SFWidgetLabel.h
//  ZombieArcade
//
//  Created by Adam Iredale on 22/11/09.
//  Copyright 2009 Stormforge Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SFWidget.h"
#import "SFProtocol.h"

typedef enum {
    ljLeft,
    ljRight,
    ljCenter
} SFLabelJustification;

@interface SFWidgetLabel : SFWidget {
	//basically a widget created
	//using the SIO2 font interface
	//to print on the screen
	NSMutableString *_internalCaption;
	BOOL _updateViaCallback;

	unsigned char           _charOffset;
	float                   _size;
	float                   _space, _wideSpace, _thinSpace;
    float                   _lineSpace;
    BOOL                    _isFixedWidth;
    SFLabelJustification    _justification;
    
}

-(id)initLabel:(NSString*)fontName
initialCaption:(NSString*)initialCaption
	  position:(vec2)position
      centered:(BOOL)centered
 visibleOnShow:(BOOL)visibleOnShow
updateViaCallback:(BOOL)updateViaCallback;

-(void)setCaption:(NSString*)caption;
-(void)setJustification:(SFLabelJustification)justification;

@end
