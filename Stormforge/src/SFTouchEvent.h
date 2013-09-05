//
//  SFTouchEvent.h
//  ZombieArcade
//
//  Created by Adam Iredale on 16/12/09.
//  Copyright 2009 Stormforge Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SFVec.h"
#import "SFObject.h"

typedef enum {
	TOUCH_EVENT_MOVED,
	TOUCH_EVENT_BEGAN,
	TOUCH_EVENT_ENDED
} TOUCH_EVENT_TYPE;

@interface SFTouchEvent : SFObject {
	//to correctly allow asynchronous touch
	//event handling we need an object
	//to carry the touch data at the time
	//that it happened
	unsigned char _eventType;
	vec2 *_touchArray;
    unsigned int _touchCount;
	unsigned int _tapCount;
    vec3 _3DPoint;
}

-(vec2)getTouchPosPortrait:(int)touchIndex;
-(vec2)getTouchPosLandscape:(int)touchIndex;
-(vec2)getFirstTouchPosPortrait;
-(vec2)getFirstTouchPosLandscape;
-(unsigned char)touchKind;

-(void)set3DPoint:(vec3)point3d;
-(vec3)get3DPoint;

-(id)initWithTouches:(NSSet*)touches eventType:(unsigned char)eventType view:(UIView*)view;
+(id)initWithTouches:(NSSet*)touches eventType:(unsigned char)eventType view:(UIView*)view;

@end
