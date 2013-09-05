//
//  SFIpo.m
//  ZombieArcade
//
//  Created by Adam Iredale on 4/03/10.
//  Copyright 2010 Stormforge Software. All rights reserved.
//

#import "SFIpo.h"
#import "SFBezierPoint.h"
#import "SFUtils.h"
#import "SFDebug.h"
#import "SFScene.h"

@implementation SFIpo

-(void)addSimplePoints:(float*)from to:(float*)to destination:(char)destination seconds:(float)seconds{
    SFBezPoint fromPoint, toPoint;
    char axes[4] = "xyz";
    
    for (int i = 0; i < 3; ++i) {
        fromPoint = BezPointXY(0, from[i]);
        toPoint = BezPointXY(seconds, to[i]);
        [self addBezierPointFromFloats:(float*)&fromPoint destination:destination axisLetter:axes[i]];
        [self addBezierPointFromFloats:(float*)&toPoint destination:destination axisLetter:axes[i]];
    }
    
}

-(void)interpolateTransforms:(SFTransform*)from to:(SFTransform*)to seconds:(float)seconds{
    //for each axis and each kind of operation, create a bezier point for t=0 and t=seconds
    
    if (!from->loc()->equals(to->loc())) {
        [self addSimplePoints:from->loc()->floatArray()
                           to:to->loc()->floatArray()
                  destination:'l'
                      seconds:seconds];
    }
    if (!from->rot()->equals(to->rot())) {
        [self addSimplePoints:from->rot()->floatArray()
                           to:to->rot()->floatArray()
                  destination:'r'
                      seconds:seconds];
    }
    if (!from->scl()->equals(to->scl())) {
        [self addSimplePoints:from->scl()->floatArray()
                           to:to->scl()->floatArray()
                  destination:'s'
                      seconds:seconds];
    }
}

-(id)initSimpleIpo:(SFTransform*)from to:(SFTransform*)to seconds:(float)seconds{
    //create a simple straight ipo from one transform to another
    self = [self initWithDictionary:nil];
    if (self != nil) {
        [self interpolateTransforms:from to:to seconds:seconds];
    }
    return self;
}

-(id)points{
    return [self objectInfoForKey:@"points" useMasterInfo:NO createOk:YES];
}

-(SFVec*)renderAxisCurves:(id)axisCurveInfo{
    //the axis curve info has x, y, z point arrays
    //and other information - from it we set
    //the current value of a single vector in 3d space
    if (!axisCurveInfo) {
        return nil; //no curve of this kind
    }
    float curvesFinished = 0;
    SFVec *currentVector = new SFVec(3);
    
    SFBezierCurve *curveInfo = [axisCurveInfo objectForKey:@"x"];
    if (curveInfo) {
        currentVector->setX([curveInfo renderFloat:&curvesFinished]);
    } else {
        ++curvesFinished;
    }
    
    curveInfo = [axisCurveInfo objectForKey:@"y"];
    if (curveInfo) {
        currentVector->setY([curveInfo renderFloat:&curvesFinished]);
    } else {
        ++curvesFinished;
    }
    
    curveInfo = [axisCurveInfo objectForKey:@"z"];
    if (curveInfo) {
        currentVector->setZ([curveInfo renderFloat:&curvesFinished]);
    } else {
        ++curvesFinished;
    }
    
    if (curvesFinished == 3) {
        delete currentVector;
        return nil; //we're done
    }
    
    return currentVector;
}

-(void)play:(id<SFIpoDelegate>)delegate{
    _notifyObject = [delegate retain];
    [self reset];
    _isPlaying = YES;
}

-(void)stop{
    _isPlaying = NO;
    [_notifyObject ipoStopped:self];
    [_notifyObject release];
    _notifyObject = nil;
}

-(void)reset{
    NSEnumerator *curveKinds = [[self points] objectEnumerator];
    for (id curveKind in curveKinds) {
        NSEnumerator *axisCurves = [curveKind objectEnumerator];
        for (id axisCurve in axisCurves) {
            [axisCurve reset];
        }
    }
}

-(void)render{
    
    if (!_isPlaying) {
        return;
    }
    
    id points = [self points];
    //render l, r, s
    float curvesFinished = 0;
    
    SFVec *curveVector = [self renderAxisCurves:[points objectForKey:@"l"]];
    if (curveVector) {
        _transform->loc()->setVector(curveVector);
        delete curveVector;
    } else {
        ++curvesFinished;
    }
    
    curveVector = [self renderAxisCurves:[points objectForKey:@"r"]];
    if (curveVector) {
        _transform->rot()->setVector(curveVector);
        if (_clampRotation) {
            //remove unneccesary multiples of 2 pi / 360
            _transform->rot()->clamp360();
        }
        delete curveVector;
    } else {
        ++curvesFinished;
    }
    
    curveVector = [self renderAxisCurves:[points objectForKey:@"s"]];
    if (curveVector) {
        _transform->scl()->setVector(curveVector);
        delete curveVector;
    } else {
        ++curvesFinished;
    }
    
    if (curvesFinished == 3) {
        if (_repeat) {
            [self reset];
        } else {
            [self stop];
        }
    }
    _transform->compileMatrix();
}
                    

-(void)cleanUp{
    delete _transform;
    [super cleanUp];
}

-(void)addBezierPointFromFloats:(float*)floats destination:(char)destination axisLetter:(char)axisLetter{
    //expects l, r, or s for destination and x, y or z for axis letter
    //add a bezier point and create the array/dictionary if it doesn't exist
    id points = [self points];
    id destKey = [NSString stringWithFormat:@"%c", destination];
    id axisKey = [NSString stringWithFormat:@"%c", axisLetter];
    id destDictionary = [points objectForKey:destKey];
    if (!destDictionary) {
        destDictionary = [[NSMutableDictionary alloc] init];
        [points setObject:destDictionary forKey:destKey];
        [destDictionary release];
    }
    _lastUsedCurve = [destDictionary objectForKey:axisKey];
    //if the curve hasn't been made yet, make it
    if (!_lastUsedCurve) {
        _lastUsedCurve = [[SFBezierCurve alloc] initWithDictionary:nil];
        [destDictionary setObject:_lastUsedCurve forKey:axisKey];
        [_lastUsedCurve release];
    }
    [_lastUsedCurve addPoint:floats];
}

-(void)setInitialTransform:(SFTransform *)transform{
    _transform->setFromTransform(transform);
}

-(void)clampRotation{
    //when rotation is clamped we only rotate up to 359 degrees
    //to prevent "wind up"
    _clampRotation = YES;
}

-(BOOL)loadInfo:(SFTokens*)tokens{
    
    char *tokenName = tokens->tokenName();
    
    //handles all the point data here
    if (strlen(tokenName) == 2) {
        [self addBezierPointFromFloats:tokens->valueAsFloats(4)
                           destination:tokenName[0]
                            axisLetter:tokenName[1]];
        return YES;
    }
    
    if (tokens->tokenIs("i")) {
        [_lastUsedCurve setInterpolation:tokens->valueAsFloats(1)[0]];
        return YES;
    }
    
    if (tokens->tokenIs("e")) {
        [_lastUsedCurve setExtrapolation:tokens->valueAsFloats(1)[0]];
        //if we have even ONE cyclic extrapolator we repeat
        //until asked to be stopped
        if ((tokens->valueAsFloats(1)[0] == SF_IPO_CURVE_EXTRAPOLATION_CYCLIC) 
            or (tokens->valueAsFloats(1)[0] == SF_IPO_CURVE_EXTRAPOLATION_CYCLIC_EXTRAPOLATION)) {
            _repeat = YES;
        }
        return YES;
    }
	
	return NO;
    
}

+(NSString*)fileDirectory{
    return @"ipo";
}

-(id)initCopyWithDictionary:(NSDictionary *)dictionary{
    self = [super initCopyWithDictionary:dictionary];
    if (self != nil) {
        _transform = new SFTransform();
    }
    return self;
}

-(SFTransform*)transform{
    return _transform;
}

-(BOOL)isPlaying{
    return _isPlaying;
}

@end
