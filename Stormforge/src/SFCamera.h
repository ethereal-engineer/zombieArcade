//
//  SFCamera.h
//  ZombieArcade
//
//  Created by Adam Iredale on 4/03/10.
//  Copyright 2010 Stormforge Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SFGameObject.h"
#import "SFTransform.h"
#import "SFLoadableGameObject.h"
#import "SFIpo.h"

@interface SFCamera : SFLoadableGameObject {
    //camera wrapper
    float       _fov, //field of view
                _cstart, //front clipping plane
                _cend; //back clipping plane
    NSString    *_ipoName; //name of the pre-assigned (blender) ipo
    SFTransform *_transform, *_actorHands; //transform - duh :)
    vec3    _up; //which way is up?
    SFIpo       *_ipo; //assigned ipo
	float       _frustum[ 6 ][ 4 ]; //six clipping planes
	GLfloat     _matModelView[16]; //model-view matrix
	GLfloat     _matProjection[16]; //projection matrix
    BOOL        _didMoveCamera;
    BOOL        _ipoDidPlay;
    BOOL        _newIpo;
    id          _cameraDelegate;
}

-(void)bindIpo;
-(float)fov;
-(float)clipStart;
-(float)clipEnd;
-(NSString*)ipoName;
-(SFTransform*)transform;
-(void)render;
-(float)sphereDistInFrustum:(SFVec*)loc radius:(float)radius;
-(void)updateFrustum;
-(btVector3)getRayTo:(vec2)destination2D;
-(void)setPerspective;
-(float*)matModelView;
-(float*)matProjection;
-(void)setIpoName:(NSString*)ipoName;
-(SFTransform*)handTransform;
-(void)setCameraDelegate:(id<SFCameraDelegate>)delegate;

@end
