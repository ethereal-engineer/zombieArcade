//
//  SFCamera.m
//  ZombieArcade
//
//  Created by Adam Iredale on 4/03/10.
//  Copyright 2010 Stormforge Software. All rights reserved.
//

#import "SFCamera.h"
#import "SFGameEngine.h"
#import "SFUtils.h"
#import "SFGL.h"
#import "SFAL.h"

@implementation SFCamera

#define HAND_POSITION_DROP 0.5f
#define HAND_POSITION_FORWARD 1.0f

-(id)initCopyWithDictionary:(NSDictionary *)dictionary{
    self = [super initCopyWithDictionary:dictionary];
    if (self != nil) {
        _up = Vec3Make(0, 0, 1);
        _didMoveCamera = YES;
        _transform = new SFTransform();
        _fov = 45.0f;
        _cstart = 0.1f;
        _cend = 100.0f;
    }
    return self;
}

-(id)initWithDictionary:(NSDictionary *)dictionary{
    self = [super initWithDictionary:dictionary];
    if (self != nil) {

    }
    return self;
}

-(BOOL)loadInfo:(SFTokens*)tokens{
    
    if (tokens->tokenIs("l")) {
        _transform->loc()->setFloats(tokens->valueAsFloats(3), 3);
        return YES;
    }
    
    if (tokens->tokenIs("r")) {
        _transform->rot()->setFloats(tokens->valueAsFloats(3), 3);
        return YES;
    }
    
    if (tokens->tokenIs("d")) {
        _transform->dir()->setFloats(tokens->valueAsFloats(3), 3);
        return YES;
    }
    
    if (tokens->tokenIs("f")) {
        _fov = tokens->valueAsFloats(1)[0];
        return YES;
    }
    
    if (tokens->tokenIs("cs")) {
        _cstart = tokens->valueAsFloats(1)[0];
        return YES;
    }
    
    if (tokens->tokenIs("ce")) {
        _cend = tokens->valueAsFloats(1)[0];
        return YES;
    }
    
    if (tokens->tokenIs("ip")) {
        _ipoName = [[[NSString stringWithUTF8String:tokens->valueAsString()] lastPathComponent] retain];
        return YES;
    }
    
    return NO;
}

-(SFTransform*)handTransform{
    if (!_actorHands){
        _actorHands = new SFTransform();
    }
    //update from camera
    _actorHands->setFromTransform(_transform);
    //offset for hand position
    _actorHands->loc()->addZ(-HAND_POSITION_DROP);
    _actorHands->loc()->addY(HAND_POSITION_FORWARD);
    _actorHands->compileMatrix();
    return _actorHands;
}

-(void)cameraGetProjectionMatrix{
    [SFUtils assertGlContext];
    //PERF ISSUE:
    //this should be called infrequently as it may cause the 
    //gl hardware to lockstep with the cpu
    SFGL::instance()->glGetFloatv(GL_PROJECTION_MATRIX, (GLfloat*)_matProjection);
	//glGetFloatv( GL_PROJECTION_MATRIX, (GLfloat*)_matProjection); 
}


-(void)cameraGetModelviewMatrix{
    [SFUtils assertGlContext];
    //PERF ISSUE:
    //this should be called infrequently as it may cause the 
    //gl hardware to lockstep with the cpu
    SFGL::instance()->glGetFloatv(GL_MODELVIEW_MATRIX, (GLfloat*)_matModelView);
	//glGetFloatv( GL_MODELVIEW_MATRIX, (GLfloat*)_matModelView);
}

-(void)setCameraDelegate:(id<SFCameraDelegate>)delegate{
    _cameraDelegate = [delegate retain];
}

-(void)ipoStopped:(id)ipo{
    //what to do when the ipo stops?
    //inform the delegate that the camera has stopped
    [_cameraDelegate cameraDidMove:self];
}

-(void)loadIpo{
    //try to load the ipo
    if (_ipoName) {
        _ipo = [[_scene getItem:_ipoName itemClass:[SFIpo class]] retain];
        [_ipo play:self];
        [_cameraDelegate cameraWillMove:self];
    } else {
        [_ipo release];
        _ipo = nil;
    }

}

-(void)renderIpo{
    if (_newIpo) {
        [self loadIpo];
        _newIpo = NO;
    }
    if ((_ipo) and ([_ipo isPlaying])) {
        _ipoDidPlay = YES;
        [_ipo render];
        SFVec *ipoLoc = [_ipo transform]->loc();
        SFAng *ipoRot = [_ipo transform]->rot();
        ipoRot->anglesPositive();
        _transform->loc()->setVector(ipoLoc);
        _transform->rot()->setVector(ipoRot);
        SFVec *newDirection = _transform->loc()->copy();
        newDirection->rotate3D(90.0f - ipoRot->x(), ipoRot->z(), -1.0f);
        newDirection->subtract(_transform->loc());
        _transform->dir()->setVector(newDirection);
        delete newDirection;
    } else if (_ipoDidPlay) {
        _didMoveCamera = YES;
        _ipoDidPlay = NO;
    }
}

-(void)calculateMatrix{
    _transform->matrix()[0] = (_transform->dir()->y() * _up.z) - (_transform->dir()->z() * _up.y);
	_transform->matrix()[4] = (_transform->dir()->z() * _up.x) - (_transform->dir()->x() * _up.z);
	_transform->matrix()[8] = (_transform->dir()->x() * _up.y) - (_transform->dir()->y() * _up.x);
	_transform->matrix()[1] = (_transform->matrix()[4] * _transform->dir()->z()) - (_transform->matrix()[8] * _transform->dir()->y());
	_transform->matrix()[5] = (_transform->matrix()[8] * _transform->dir()->x()) - (_transform->matrix()[0] * _transform->dir()->z());
	_transform->matrix()[9] = (_transform->matrix()[0] * _transform->dir()->y()) - (_transform->matrix()[4] * _transform->dir()->x());
	_transform->matrix()[2] = -_transform->dir()->x();
	_transform->matrix()[6] = -_transform->dir()->y();
	_transform->matrix()[10] = -_transform->dir()->z();
	_transform->matrix()[15] = 1.0f;
}

-(void)bindIpo{

}

-(void)render{
    [self renderIpo];
    
    if (_didMoveCamera or _ipoDidPlay) {
        [self calculateMatrix];
    }
    
    _transform->multMatrix();

	glTranslatef(-_transform->loc()->x(),
                 -_transform->loc()->y(),
                 -_transform->loc()->z());
    
    if (_didMoveCamera or _ipoDidPlay) {
        SFAL::instance()->updateListener(_transform);
        [self updateFrustum];
    }
    
    if (_didMoveCamera) {
        [self cameraGetModelviewMatrix];
    }
    
    if (_didMoveCamera) {
        _didMoveCamera = NO;
    }
}

-(void)setPerspective{
    [SFUtils assertGlContext];
	SFGL::instance()->glMatrixMode(GL_PROJECTION);
	glLoadIdentity();
	{
		float m[ 16 ],
        s,
        c,
        d = _cend - _cstart,
        r = _fov * 0.5f * SF_DEG_TO_RAD;
        
		s = sinf( r );
        
		c = cosf( r ) / s;
        
		memset( &m[ 0 ], 0, 64 );
        
		m[ 0  ] = c / ([[SFGameEngine mainViewController] scl]->x() / [[SFGameEngine mainViewController] scl]->y());
		m[ 5  ] = c;
		m[ 10 ] = -( _cend + _cstart ) / d;
		m[ 11 ] = -1.0f;
		m[ 14 ] = -2.0f * _cend * _cstart / d;
		
		glMultMatrixf( &m[ 0 ] );
	}
	SFGL::instance()->glMatrixMode(GL_MODELVIEW);
	[self cameraGetProjectionMatrix];
}

-(float*)matModelView{
    return _matModelView;
}

-(float*)matProjection{
    return _matProjection;
}

+(NSString*)fileDirectory{
    return @"camera";
}

-(void)setIpoName:(NSString*)ipoName{
    if (_ipoName) {
        [_ipoName release];
        _ipoName = nil;
    }
    _ipoName = [ipoName retain];
    _newIpo = YES;
    //next render, this will try to load the ipo
}



-(btVector3)getRayTo:(vec2)destination2D{

    float x, y, z = 0;
    
    //[SFUtils debugFloatMatrix:_matModelView width:4 height:4];
   // [SFUtils debugFloatMatrix:_matProjection width:4 height:4];
    //[SFUtils debugIntMatrix:[[SFGameEngine sfWindow] matViewPort] width:4 height:1];
    
	// Do a 2D to 3D conversion evaluating a point of
	// intersection between the near clipping plane
	// and the far clipping plane.
	sio2UnProject(destination2D.x,
				  destination2D.y,
				  0.0f,
				  _matModelView,
				  _matProjection,
				  [[SFGameEngine mainViewController] matViewPort],
				  &x,
				  &y,
				  &z);
    
    SFVec *nearPoint = new SFVec(Vec3Make(x, y, z));
	
	sio2UnProject(destination2D.x,
				  destination2D.y,
				  1.0f,
				  _matModelView,
				  _matProjection,
				  [[SFGameEngine mainViewController] matViewPort],
				  &x,
				  &y,
				  &z );
    
    SFVec *farPoint = new SFVec(Vec3Make(x, y, z));
	
    SFVec *sumVec = _transform->loc()->copy();
    
    sumVec->add(farPoint);
    sumVec->subtract(nearPoint);
   
    btVector3 resultVector = sumVec->getBtVector3();
    
    delete nearPoint;
    delete farPoint;
    delete sumVec;
    
	return resultVector;
}


-(void)updateFrustum{
    //borrowed
    float c[ 16 ],
    t;
    
    c[ 0 ] = _matModelView[ 0 ] * _matProjection[ 0  ] +
    _matModelView[ 1 ] * _matProjection[ 4  ] + 
    _matModelView[ 2 ] * _matProjection[ 8  ] + 
    _matModelView[ 3 ] * _matProjection[ 12 ];
    
    c[ 1 ] = _matModelView[ 0 ] * _matProjection[ 1  ] +
    _matModelView[ 1 ] * _matProjection[ 5  ] +
    _matModelView[ 2 ] * _matProjection[ 9  ] +
    _matModelView[ 3 ] * _matProjection[ 13 ];
    
    c[ 2 ] = _matModelView[ 0 ] * _matProjection[ 2  ] +
    _matModelView[ 1 ] * _matProjection[ 6  ] +
    _matModelView[ 2 ] * _matProjection[ 10 ] +
    _matModelView[ 3 ] * _matProjection[ 14 ];
    
    c[ 3 ] = _matModelView[ 0 ] * _matProjection[ 3  ] +
    _matModelView[ 1 ] * _matProjection[ 7  ] + 
    _matModelView[ 2 ] * _matProjection[ 11 ] + 
    _matModelView[ 3 ] * _matProjection[ 15 ];
    
    c[ 4 ] = _matModelView[ 4 ] * _matProjection[ 0  ] + 
    _matModelView[ 5 ] * _matProjection[ 4  ] + 
    _matModelView[ 6 ] * _matProjection[ 8  ] +
    _matModelView[ 7 ] * _matProjection[ 12 ];
    
    c[ 5 ] = _matModelView[ 4 ] * _matProjection[ 1  ] + 
    _matModelView[ 5 ] * _matProjection[ 5  ] +
    _matModelView[ 6 ] * _matProjection[ 9  ] +
    _matModelView[ 7 ] * _matProjection[ 13 ];
    
    c[ 6 ] = _matModelView[ 4 ] * _matProjection[ 2  ] +
    _matModelView[ 5 ] * _matProjection[ 6  ] +
    _matModelView[ 6 ] * _matProjection[ 10 ] +
    _matModelView[ 7 ] * _matProjection[ 14 ];
    
    c[ 7 ] = _matModelView[ 4 ] * _matProjection[ 3  ] +
    _matModelView[ 5 ] * _matProjection[ 7  ] +
    _matModelView[ 6 ] * _matProjection[ 11 ] +
    _matModelView[ 7 ] * _matProjection[ 15 ];
    
    c[ 8 ] = _matModelView[ 8  ] * _matProjection[ 0  ] +
    _matModelView[ 9  ] * _matProjection[ 4  ] +
    _matModelView[ 10 ] * _matProjection[ 8  ] + 
    _matModelView[ 11 ] * _matProjection[ 12 ];
    
    c[ 9 ] = _matModelView[ 8  ] * _matProjection[ 1  ] +
    _matModelView[ 9  ] * _matProjection[ 5  ] +
    _matModelView[ 10 ] * _matProjection[ 9  ] +
    _matModelView[ 11 ] * _matProjection[ 13 ];
    
    c[ 10 ] = _matModelView[ 8  ] * _matProjection[ 2  ] +
    _matModelView[ 9  ] * _matProjection[ 6  ] +
    _matModelView[ 10 ] * _matProjection[ 10 ] +
    _matModelView[ 11 ] * _matProjection[ 14 ];
    
    c[ 11 ] = _matModelView[ 8  ] * _matProjection[ 3  ] +
    _matModelView[ 9  ] * _matProjection[ 7  ] +
    _matModelView[ 10 ] * _matProjection[ 11 ] +
    _matModelView[ 11 ] * _matProjection[ 15 ];
    
    c[ 12 ] = _matModelView[ 12 ] * _matProjection[ 0  ] +
    _matModelView[ 13 ] * _matProjection[ 4  ] +
    _matModelView[ 14 ] * _matProjection[ 8  ] +
    _matModelView[ 15 ] * _matProjection[ 12 ];
    
    c[ 13 ] = _matModelView[ 12 ] * _matProjection[ 1  ] +
    _matModelView[ 13 ] * _matProjection[ 5  ] +
    _matModelView[ 14 ] * _matProjection[ 9  ] +
    _matModelView[ 15 ] * _matProjection[ 13 ];
    
    c[ 14 ] = _matModelView[ 12 ] * _matProjection[ 2  ] +
    _matModelView[ 13 ] * _matProjection[ 6  ] +
    _matModelView[ 14 ] * _matProjection[ 10 ] +
    _matModelView[ 15 ] * _matProjection[ 14 ];
    
    c[ 15 ] = _matModelView[ 12 ] * _matProjection[ 3  ] +
    _matModelView[ 13 ] * _matProjection[ 7  ] +
    _matModelView[ 14 ] * _matProjection[ 11 ] +
    _matModelView[ 15 ] * _matProjection[ 15 ];
    
    
    _frustum[ 0 ][ 0 ] = c[ 3  ] - c[ 0  ];
    _frustum[ 0 ][ 1 ] = c[ 7  ] - c[ 4  ];
    _frustum[ 0 ][ 2 ] = c[ 11 ] - c[ 8  ];
    _frustum[ 0 ][ 3 ] = c[ 15 ] - c[ 12 ];
    
    t = 1.0f / sqrtf( _frustum[ 0 ][ 0 ] * _frustum[ 0 ][ 0 ] +
                     _frustum[ 0 ][ 1 ] * _frustum[ 0 ][ 1 ] +
                     _frustum[ 0 ][ 2 ] * _frustum[ 0 ][ 2 ] );
    
    _frustum[ 0 ][ 0 ] *= t;
    _frustum[ 0 ][ 1 ] *= t;
    _frustum[ 0 ][ 2 ] *= t;
    _frustum[ 0 ][ 3 ] *= t;
    
    
    _frustum[ 1 ][ 0 ] = c[ 3  ] + c[ 0  ];
    _frustum[ 1 ][ 1 ] = c[ 7  ] + c[ 4  ];
    _frustum[ 1 ][ 2 ] = c[ 11 ] + c[ 8  ];
    _frustum[ 1 ][ 3 ] = c[ 15 ] + c[ 12 ];
    
    t = 1.0f / sqrtf( _frustum[ 1 ][ 0 ] * _frustum[ 1 ][ 0 ] +
                     _frustum[ 1 ][ 1 ] * _frustum[ 1 ][ 1 ] +
                     _frustum[ 1 ][ 2 ] * _frustum[ 1 ][ 2 ] );
    
    _frustum[ 1 ][ 0 ] *= t;
    _frustum[ 1 ][ 1 ] *= t;
    _frustum[ 1 ][ 2 ] *= t;
    _frustum[ 1 ][ 3 ] *= t;
    
    
    _frustum[ 2 ][ 0 ] = c[ 3  ] + c[ 1  ];
    _frustum[ 2 ][ 1 ] = c[ 7  ] + c[ 5  ];
    _frustum[ 2 ][ 2 ] = c[ 11 ] + c[ 9  ];
    _frustum[ 2 ][ 3 ] = c[ 15 ] + c[ 13 ];
    
    t = 1.0f / sqrtf( _frustum[ 2 ][ 0 ] * _frustum[ 2 ][ 0 ] +
                     _frustum[ 2 ][ 1 ] * _frustum[ 2 ][ 1 ] +
                     _frustum[ 2 ][ 2 ] * _frustum[ 2 ][ 2 ] );
    
    _frustum[ 2 ][ 0 ] *= t;
    _frustum[ 2 ][ 1 ] *= t;
    _frustum[ 2 ][ 2 ] *= t;
    _frustum[ 2 ][ 3 ] *= t;
    
    
    _frustum[ 3 ][ 0 ] = c[ 3  ] - c[ 1  ];
    _frustum[ 3 ][ 1 ] = c[ 7  ] - c[ 5  ];
    _frustum[ 3 ][ 2 ] = c[ 11 ] - c[ 9  ];
    _frustum[ 3 ][ 3 ] = c[ 15 ] - c[ 13 ];
    
    t = 1.0f / sqrtf( _frustum[ 3 ][ 0 ] * _frustum[ 3 ][ 0 ] +
                     _frustum[ 3 ][ 1 ] * _frustum[ 3 ][ 1 ] +
                     _frustum[ 3 ][ 2 ] * _frustum[ 3 ][ 2 ] );
    
    _frustum[ 3 ][ 0 ] *= t;
    _frustum[ 3 ][ 1 ] *= t;
    _frustum[ 3 ][ 2 ] *= t;
    _frustum[ 3 ][ 3 ] *= t;
    
    
    _frustum[ 4 ][ 0 ] = c[ 3  ] - c[ 2  ];
    _frustum[ 4 ][ 1 ] = c[ 7  ] - c[ 6  ];
    _frustum[ 4 ][ 2 ] = c[ 11 ] - c[ 10 ];
    _frustum[ 4 ][ 3 ] = c[ 15 ] - c[ 14 ];
    
    t = 1.0f / sqrtf( _frustum[ 4 ][ 0 ] * _frustum[ 4 ][ 0 ] +
                     _frustum[ 4 ][ 1 ] * _frustum[ 4 ][ 1 ] +
                     _frustum[ 4 ][ 2 ] * _frustum[ 4 ][ 2 ] );
    
    _frustum[ 4 ][ 0 ] *= t;
    _frustum[ 4 ][ 1 ] *= t;
    _frustum[ 4 ][ 2 ] *= t;
    _frustum[ 4 ][ 3 ] *= t;
    
    
#if SIO2_CLIP_PLANE == 6 
    
    _frustum[ 5 ][ 0 ] = c[ 3  ] + c[ 2  ];
    _frustum[ 5 ][ 1 ] = c[ 7  ] + c[ 6  ];
    _frustum[ 5 ][ 2 ] = c[ 11 ] + c[ 10 ];
    _frustum[ 5 ][ 3 ] = c[ 15 ] + c[ 14 ];
    
    
    t = 1.0f / sqrtf( _frustum[ 5 ][ 0 ] * _frustum[ 5 ][ 0 ] +
                     _frustum[ 5 ][ 1 ] * _frustum[ 5 ][ 1 ] +
                     _frustum[ 5 ][ 2 ] * _frustum[ 5 ][ 2 ] );
    
    _frustum[ 5 ][ 0 ] *= t;
    _frustum[ 5 ][ 1 ] *= t;
    _frustum[ 5 ][ 2 ] *= t;
    _frustum[ 5 ][ 3 ] *= t;
#endif
    
}

-(float)sphereDistInFrustum:(SFVec*)loc radius:(float)radius{
	
	float distance = 0.0f;
    
	for (int i = 0; i < 6; ++i) {
		distance =  _frustum[i][0] * loc->x() + 
                    _frustum[i][1] * loc->y() + 
                    _frustum[i][2] * loc->z() + 
                    _frustum[i][3];
		
		if (distance < -radius){ 
            return 0.0f; 
        }
	}
	
	return distance + radius;
}

-(void)cleanUp{
    [_cameraDelegate release];
    delete _transform;
    [super cleanUp];
}

-(float)fov{
    return _fov;
}

-(float)clipStart{
    return _cstart;
}

-(float)clipEnd{
    return _cend;
}

-(NSString*)ipoName{
    return _ipoName;
}

-(SFTransform*)transform{
    return _transform;
}

@end
