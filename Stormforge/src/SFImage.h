//
//  SFImage.h
//  ZombieArcade
//
//  Created by Adam Iredale on 16/02/10.
//  Copyright 2010 Stormforge Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SFLoadableGameObject.h"
#import "SFProtocol.h"
#import "SFRect.h"

#define DEBUG_SFIMAGE 0

typedef enum
{
	SF_IMAGE_MIPMAP = ( 1 << 0 ),
	SF_IMAGE_CLAMP  = ( 1 << 1 )
	
} SF_IMAGE_FLAG;


typedef enum
{
	SF_IMAGE_BILINEAR = 0,
	SF_IMAGE_TRILINEAR,
	SF_IMAGE_QUADLINEAR
	
} SF_IMAGE_FILTERING_TYPE;


typedef enum
{
	SF_IMAGE_ISOTROPIC = 0,
	SF_IMAGE_ANISOTROPIC_1X,
	SF_IMAGE_ANISOTROPIC_2X
	
} SF_IMAGE_ANISOTROPIC_TYPE;

@interface SFImage : SFLoadableGameObject {
    unsigned int _width;
	unsigned int _height;
	unsigned char _bits;
	unsigned char *_data;
	unsigned int _tid;
    float _filter;  
    BOOL _indirectBufferData;
    SFRect _offset;
}

-(int)width;
-(int)height;
-(GLfloat)filter;
-(GLuint)tid;
-(void)setData:(unsigned char*)pointTo;
-(unsigned char*)data;
-(void)setFilter:(float)filter;
-(void)prepare;
-(void)forcePrepare;
-(SFRect*)offset;
-(void)loadFromStream:(SFStream*)stream;
@end
