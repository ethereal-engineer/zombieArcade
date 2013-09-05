//
//  SFTouchEvent.m
//  ZombieArcade
//
//  Created by Adam Iredale on 16/12/09.
//  Copyright 2009 Stormforge Software. All rights reserved.
//

#import "SFTouchEvent.h"


@implementation SFTouchEvent

-(void)translateTouch:(NSSet*)touches view:(UIView*)view{
	//touches seems to vanish into thin air so we need to copy
	//the info we need to keep right now
	for (UITouch *touch in touches) {
        ++_touchCount;
        _touchArray = (vec2*)realloc(_touchArray, _touchCount * sizeof(vec2));
        CGPoint aPoint = [touch locationInView:view];
        memcpy(&_touchArray[_touchCount - 1], &aPoint, sizeof(vec2));
	}
}

-(id)initWithTouches:(NSSet *)touches eventType:(unsigned char)eventType view:(UIView*)view{
    self = [self init];
	if (self != nil) {
		_eventType = eventType;
		_tapCount = [[touches anyObject] tapCount];
		[self translateTouch:touches view:view];
	}
	return self;
}

-(vec3)get3DPoint{
    return _3DPoint;
}

-(void)set3DPoint:(vec3)point3d{
    memcpy(&_3DPoint, &point3d, sizeof(vec3));
}

-(void)cleanUp{
    free(_touchArray);
    [super cleanUp];
}

+(id)initWithTouches:(NSSet *)touches eventType:(unsigned char)eventType view:(UIView*)view{
	return [(SFTouchEvent*)[[self class] alloc] initWithTouches:touches eventType:eventType view:view];
}

-(int)getTouchCount{
	return _touchCount;
}

-(vec2)getTouchPosPortrait:(int)touchIndex{
	return _touchArray[touchIndex];
}

-(vec2)getTouchPosLandscape:(int)touchIndex{
    GLfloat tmp;
    vec2 portrait = [self getTouchPosPortrait:touchIndex];
    tmp = portrait.x;
    portrait.x = portrait.y;
    portrait.y = tmp;
	return portrait;
}

-(vec2)getFirstTouchPosPortrait{
	return [self getTouchPosPortrait:0];
}

-(vec2)getFirstTouchPosLandscape{
	return [self getTouchPosLandscape:0];
}

-(unsigned char)touchKind{
	return _eventType;
}

@end
