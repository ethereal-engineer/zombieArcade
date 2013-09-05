//
//  SFBezierCurve.m
//  ZombieArcade
//
//  Created by Adam Iredale on 4/03/10.
//  Copyright 2010 Stormforge Software. All rights reserved.
//

#import "SFBezierCurve.h"
#import "SFGameEngine.h"
#import "SFUtils.h"
#import "SFDebug.h"

@implementation SFBezierCurve

-(void)setInterpolation:(unsigned char)interpolation{
    _interpolation = interpolation;
}

-(void)setExtrapolation:(unsigned char)extrapolation{
    _extrapolation = extrapolation;
}

-(id)initWithDictionary:(NSDictionary *)dictionary{
    self = [super initWithDictionary:dictionary];
    if (self != nil){
        _firstRun = YES;
        _interpolation = SF_IPO_CURVE_INTERPOLATION_LINEAR;
    }
    return self;
}

-(void)addPoint:(float*)floats{
    ++_pointCount;
    _points = (SFBezPoint*)realloc(_points, _pointCount * sizeof(SFBezPoint));
    memcpy(&_points[_pointCount - 1], floats, sizeof(SFBezPoint));
}

-(void)cleanUp{
    free(_points);
    [super cleanUp];
}

//float cubicBezier( float t, float a, float b, float c, float d )
//{
//	float i  = 1.0f - t,
//    t2 = t * t,
//    i2 = i * i;
//	float bezValue = i2 * i * a +  3.0f * t * i2 * b  +  3.0f * t2  * i * c + t2 * t * d;
//	return bezValue;
//}

float cubicBezier(float t, float point0, float handleOut0, float handleIn1, float point1){
    //where t is the time (or x-position on the curve),
    //and the points and handles are as expected on a bezier curve in the order
    //from left to right
    //as in the formula here: http://www.paultondeur.com/wp-content/uploads/2008/03/cubic_bezier_formula.gif
    //
    float bezierValue = powf(t, 3.0f) * (point1 + 3.0f * (handleOut0 - handleIn1) - point0) + 
           3.0f * powf(t, 2.0f) * (point0 - (2 * handleOut0) + handleIn1) + 3.0f * t * (handleOut0 - point0) + point0; 
    //primitive nan protection until I can understand this better...
    if (isnan(bezierValue)) {
        return point0;
    }
    return bezierValue;
}

-(void)updateCurveRatio{
    //the point AFTER
    SFBezPoint currentPoint = _points[_currentPoint];
    SFBezPoint nextPoint = _points[_currentPoint + 1];
    _tRatio = nextPoint.x - currentPoint.x;
    _vRatio = nextPoint.y - currentPoint.y;
    _tvRatio = _vRatio / _tRatio;
}

-(BOOL)isEmpty{
    return _pointCount == 0;
}

-(float)reset{
    //resets the curve current values and returns the first value
    _currentPoint = 0;
	_timeDelta = 0.0f;
	[self updateCurveRatio];
	return _points[0].y;
}

-(float)renderFloat:(float*)incWhenFinished{
    //renders the curve's single float point
    //based on time
    
    float renderValue;
    
    if (_currentPoint < _pointCount - 1) { 
        //the current point is NOT the last point
        
        SFBezPoint currentPoint;
        
        if (_timeDelta >= _tRatio) {
            //it's time to change from this point to the next
            //point
            ++_currentPoint;
            _timeDelta = 0.0f;
            
            currentPoint = _points[_currentPoint];
            renderValue = currentPoint.y;
            if (_currentPoint < _pointCount - 1) {
                //if this next point STILL isn't the last point
                //we update our ratios - otherwise there is no point lol
                [self updateCurveRatio];
            }
        } else {
            //it isn't time to swap points to the next one yet
            //instead, we are somewhere inbetween t=0 (for this point)
            //and the next point - so we calculate what kind of 
            //value we return based on curvature
            
            currentPoint = _points[_currentPoint];
            SFBezPoint nextPoint = _points[_currentPoint + 1];
            switch(_interpolation )
            {
                case SF_IPO_CURVE_INTERPOLATION_LINEAR:
                    renderValue = currentPoint.y + (_tvRatio * _timeDelta);	
                    break;
                case SF_IPO_CURVE_INTERPOLATION_BEZIER:
                    renderValue = cubicBezier( _timeDelta / _tRatio,
                                              currentPoint.y,
                                              currentPoint.handleOut,
                                              nextPoint.handleIn,
                                              nextPoint.y);
                    break;
            }
            _timeDelta += [[SFGameEngine mainViewController] deltaTime];
        }
    } else {
        //the current point IS the last point
        //and we will have already rendered it once
        //from here we can do one of two things - 
        //either stop the ipo or 
        //calculate a value that will allow us to loop seamlessly
       // if (_extrapolation) {
//            //if we have extraps, we will want to do the latter
//            
//            SFBezPoint prevPoint = _points[_currentPoint - 1];
//            
//            switch (_extrapolation){
//                    
//                case SF_IPO_CURVE_EXTRAPOLATION_EXTRAPOLATION:
//                case SF_IPO_CURVE_EXTRAPOLATION_CYCLIC_EXTRAPOLATION:
//                {
//                    _timeDelta += [[SFGameEngine sfWindow] deltaTime];
//                    renderValue = lastPoint->knot()->y() + _tvRatio * _timeDelta;
//                    break;
//                }
//                    
//                case SF_IPO_CURVE_EXTRAPOLATION_CYCLIC:
//                {
//                    renderValue = [self reset];
//                    break;
//                }
//            }
//        } else {
            ++(*incWhenFinished);
       // }
    }
    
    return renderValue;
}

@end
