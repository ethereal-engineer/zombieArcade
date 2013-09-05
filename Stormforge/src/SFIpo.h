//
//  SFIpo.h
//  ZombieArcade
//
//  Created by Adam Iredale on 4/03/10.
//  Copyright 2010 Stormforge Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SFLoadableGameObject.h"
#import "SFTransform.h"
#import "SFBezierCurve.h"
#import "SFDefines.h"
#import "SFProtocol.h"

#define DEBUG_SFIPO 0

@interface SFIpo : SFLoadableGameObject {
    BOOL _isPlaying;
    SFBezierCurve *_lastUsedCurve;
    SFTransform *_transform;
    id<SFIpoDelegate> _notifyObject;
    BOOL _repeat, _clampRotation;
}

-(id)initSimpleIpo:(SFTransform*)from to:(SFTransform*)to seconds:(float)seconds;

-(void)addBezierPointFromFloats:(float*)floats destination:(char)destination axisLetter:(char)axisLetter;
-(BOOL)isPlaying;
-(SFTransform*)transform;
-(void)setInitialTransform:(SFTransform*)transform;
-(void)clampRotation;
-(void)render;
-(void)reset;
-(void)play:(id<SFIpoDelegate>)delegate;
-(void)stop;
-(id)points;

@end
