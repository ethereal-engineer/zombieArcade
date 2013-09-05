//
//  SFLamp.m
//  ZombieArcade
//
//  Created by Adam Iredale on 17/02/10.
//  Copyright 2010 Stormforge Software. All rights reserved.
//

#import "SFLamp.h"
#import "SFUtils.h"
#import "SFGameEngine.h"

#define DEBUG_SHOW_LAMP 0

@implementation SFLamp

-(BOOL)loadInfo:(SFTokens*)tokens{

    if (tokens->tokenIs("t")) {
        _type = tokens->valueAsFloats(1)[0];
        return YES;
    }
    if (tokens->tokenIs("l")) {
        _transform->loc()->setFloats(tokens->valueAsFloats(3), 3);
        return YES;
    }
    if (tokens->tokenIs("d")) {
        _transform->dir()->setFloats(tokens->valueAsFloats(3), 3);
        return YES;
    }
    if (tokens->tokenIs("c")) {
        _colour->setFloats(tokens->valueAsFloats(3), 3);
        return YES;
    }
    if (tokens->tokenIs("n")) {
        _nrg = tokens->valueAsFloats(1)[0];
        return YES;
    }
    if (tokens->tokenIs("ds")) {
        _dst = tokens->valueAsFloats(1)[0];
        return YES;
    }
    if (tokens->tokenIs("f")) {
        _fov = tokens->valueAsFloats(1)[0];
        return YES;
    }
    if (tokens->tokenIs("sb")) {
        _sblend = tokens->valueAsFloats(1)[0];
        return YES;
    }
    if (tokens->tokenIs("at1")) {
        _att1 = tokens->valueAsFloats(1)[0];
        return YES;
    }
    if (tokens->tokenIs("at2")) {
        _att2 = tokens->valueAsFloats(1)[0];
        return YES;
    }
    if (tokens->tokenIs("ip")) {
        _ipoName = [[[NSString stringWithUTF8String:tokens->valueAsString()] lastPathComponent] retain];
        return YES;
    }

    return NO;
}

-(id)initCopyWithDictionary:(NSDictionary *)dictionary{
    self = [super initCopyWithDictionary:dictionary];
    if (self != nil) {
        _transform = new SFTransform();
        _colour = new SFColour(COLOUR_SOLID_WHITE);
        _vis = 1;
    }
    return self;
}

-(id)initWithDictionary:(NSDictionary *)dictionary{
    self = [super initWithDictionary:dictionary];
    if (self != nil) {
#if DEBUG_SHOW_LAMP
        [self notifyMe:SF_NOTIFY_DRAW_DEBUG_NOW selector:@selector(debugDrawLamp:)];
#endif
    }
    return self;
}

-(void)cleanUp{
    delete _transform;
    delete _colour;
    [super cleanUp];
}

-(void)renderIpo{
    if (_ipo && [_ipo isPlaying] )
	{
		//SFVec v;
//		
//		memcpy( _SIO2lamp->_SIO2transform->loc,
//               _SIO2lamp->_SIO2ipo->_SIO2transform->loc, 12 );
//        
//		sio2Rotate3D( _SIO2lamp->_SIO2transform->loc,
//                     90.0f - _SIO2lamp->_SIO2ipo->_SIO2transform->rot->x,
//                     _SIO2lamp->_SIO2ipo->_SIO2transform->rot->z,
//                     -1.0f,
//                     &v );
//        
//		sio2SFVecDiff( &v,
//                     ( SFVec *)_SIO2lamp->_SIO2transform->loc,
//                     ( SFVec *)_SIO2lamp->_SIO2transform->dir );
	}
}

+(NSString*)fileDirectory{
    return @"lamp";
}

-(void)debugDrawLamp:(id)notify{
    //draw a yellow box around the lamp's location
//    float x, y, z;
//    
//    sio2Project([[_transform loc] getX],
//                [[_transform loc] getY],
//                [[_transform loc] getZ],
//                [[_scene selectedCamera] matModelView],
//                [[_scene selectedCamera] matProjection],
//                [[SFGameEngine sfWindow] matViewPort], &x, &y, &z);
//    SFGL::instance()->glPushMatrix();
//    SFGL::instance()->enter2d(0.0f, 1000.0f);
//    [SFUtils drawGlBox:[SFRect rectWithPosition:[SFVec vectorWithVec2:(vec2){x,y}] 
//                                          width:30 
//                                         height:30 
//                                       centered:YES] 
//                colour:DIFFUSE_COLOUR_SOLID_YELLOW];
//    SFGL::instance()->leave2d();
//    SFGL::instance()->glPopMatrix();
}

-(void)switchOn{
    _vis = 1;
}

-(void)switchOff{
    _vis = 0;
}

-(void)render:(int)renderAsLampNumber{

	_index = GL_LIGHT0 + renderAsLampNumber;
    
	[self renderIpo];
    
	if( !_vis )
	{ return; }
    
    SFGL::instance()->glEnable(_index);
	
	if (_type == SF_LAMP_SUN){
        SFGL::instance()->glLightfv(_index, GL_POSITION, _transform->dir()->floatArray());
    } else {

		_transform->loc()->setW(1.0f); //set uni-directional
		SFGL::instance()->glLightfv(_index, GL_POSITION, _transform->loc()->floatArray());
		
		if (_type == SF_LAMP_SPOT){
			SFGL::instance()->glLightfv(_index, GL_SPOT_DIRECTION, _transform->dir()->floatArray());
            SFGL::instance()->glLightf(_index, GL_SPOT_CUTOFF, _fov * 0.5f);
            SFGL::instance()->glLightf(_index, GL_SPOT_EXPONENT, 128.0f * _sblend);
		} else { 
            SFGL::instance()->glLightf(_index, GL_SPOT_CUTOFF, 180.0f);
        }
	}
    
    SFGL::instance()->glLightf(_index, GL_CONSTANT_ATTENUATION, 1.0f);
    SFGL::instance()->glLightf(_index, GL_LINEAR_ATTENUATION, _att1 / _dst);
    SFGL::instance()->glLightf(_index, GL_QUADRATIC_ATTENUATION, _att2 / ( _dst * _dst ));
    
    SFVec *scaledColour = _colour->copy();
    scaledColour->scale(_nrg);
    scaledColour->setW(1.0f);
	
    static GLfloat diffuseColourBlack[4] = {0.0f, 0.0f, 0.0f, 1.0f};
    
	if ([self flagState: SF_LAMP_NO_DIFFUSE]){
        SFGL::instance()->glLightfv(_index, GL_DIFFUSE, diffuseColourBlack); 
    } else {
        SFGL::instance()->glLightfv(_index, GL_DIFFUSE, scaledColour->floatArray());
    }
	
    
	if ([self flagState: SF_LAMP_NO_SPECULAR]){
        SFGL::instance()->glLightfv(_index, GL_SPECULAR, diffuseColourBlack); 
    } else { 
        SFGL::instance()->glLightfv(_index, GL_SPECULAR, scaledColour->floatArray());
    }
    
    delete scaledColour;
}

@end
