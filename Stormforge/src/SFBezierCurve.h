//
//  SFBezierCurve.h
//  ZombieArcade
//
//  Created by Adam Iredale on 4/03/10.
//  Copyright 2010 Stormforge Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SFObject.h"
#import "SFBezierPoint.h"
#import "SFDefines.h"

typedef enum
{
	SF_IPO_CURVE_INTERPOLATION_CONSTANT = 0,
	SF_IPO_CURVE_INTERPOLATION_LINEAR,
	SF_IPO_CURVE_INTERPOLATION_BEZIER
    
} SF_IPO_CURVE_INTERPOLATION_TYPE;


typedef enum
{
	SF_IPO_CURVE_EXTRAPOLATION_CONSTANT = 0,
	SF_IPO_CURVE_EXTRAPOLATION_EXTRAPOLATION,
	SF_IPO_CURVE_EXTRAPOLATION_CYCLIC,
	SF_IPO_CURVE_EXTRAPOLATION_CYCLIC_EXTRAPOLATION
    
} SF_IPO_CURVE_EXTRAPOLATION_TYPE;

typedef struct{
    float handleIn;
    float x;
    float y;
    float handleOut;
} SFBezPoint;

@interface SFBezierCurve : SFObject {
    //has an array of points and some other details
    //represents a single axis curve of an ipo
    SFBezPoint *_points;
    int _pointCount;
    unsigned char _interpolation, _extrapolation;
    int _currentPoint;
    float _timeDelta, _tvRatio, _tRatio, _vRatio;
    BOOL _firstRun;
}

-(void)addPoint:(float*)floats;
-(float)renderFloat:(float*)incWhenFinished;
-(void)setInterpolation:(unsigned char)interpolation;
-(void)setExtrapolation:(unsigned char)extrapolation;
-(BOOL)isEmpty;
@end

static inline SFBezPoint BezPointMake(float x, float y, float handleIn, float handleOut){
    SFBezPoint newBez; 
    newBez.x = x; 
    newBez.y = y; 
    newBez.handleIn = handleIn;
    newBez.handleOut = handleOut;
    return newBez;
};

#define BezPointXY(x,y) BezPointMake(x, y, y, y)
