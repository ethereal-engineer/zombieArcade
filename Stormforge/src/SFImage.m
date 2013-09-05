//
//  SFImage.m
//  ZombieArcade
//
//  Created by Adam Iredale on 16/02/10.
//  Copyright 2010 Stormforge Software. All rights reserved.
//

#import "SFImage.h"
#import "SFGL.h"
#import "SFUtils.h"
#import "SFGameEngine.h"
#import "SFGLManager.h"
#import "SFDebug.h"

@implementation SFImage

+(NSString*)fileExtension{
    //override this for class file extensions
    return @"tga";
}

+(NSString*)fileDirectory{
    return @"image";
}

-(void)setDefaults{
    //set the default alvl, filters etc
    _filter = SF_IMAGE_ISOTROPIC;
    //load any image offset from game info (for images that don't take up the full space
    //due to power of two rules
    _offset.setCGRect([[self gi] getImageOffset:[self name]]);
}

-(SFRect*)offset{
    return &_offset;
}

-(void)cleanUp{
    //ensure a context then free our texture buffer
    if (![EAGLContext currentContext]) {
        [EAGLContext setCurrentContext:[SFGameEngine glContext]];
    }
    SFGL::instance()->glDeleteTextures(1, &_tid);
    [super cleanUp];
}

-(void)setDimensions:(int)width height:(int)height depth:(int)depth{
    _width  = width;
    _height = height;
    _bits   = depth;
}

-(unsigned char*)data{
    return _data;
}

-(void)setData:(unsigned char *)pointTo{
    _indirectBufferData = YES;
    _data = pointTo;
}

-(void)allocTexBuffer{
    //based on our dimensions, allocate our data buffer for texture data
    _data = ( unsigned char * )malloc(_width * _height * _bits);
}

-(void)freeTexBuffer{
    if (_indirectBufferData) {
        return;
    }

    if (_data) {
        free(_data);
        _data = nil;
    }
}

-(id)initWithSFStream:(SFStream*)stream dictionary:(NSDictionary *)dictionary{
    self = [super initWithSFStream:stream dictionary:dictionary];
    if (self != nil) {
        [self loadFromStream:_stream];
        [self setDefaults];
        delete _stream; //we're done with it and absorb it
        _stream = NULL;
    }
    return self;
}

-(int)width{
    return _width;
}

-(int)height{
    return _height;
}

-(GLuint)tid{
    return _tid;
}

-(void)setFilter:(float)filter{
    _filter = filter;
}

-(void)genId{
    [SFUtils assertGlContext];
        int iformat,
        format;
        
        switch(_bits)
        {
            case 0:
            { return; }
                
            case 1:
            {
                iformat = GL_LUMINANCE;
                format	= GL_LUMINANCE;
                
                break;
            }
                
            case 2:
            {
                iformat = GL_LUMINANCE_ALPHA;
                format	= GL_LUMINANCE_ALPHA;
                
                break;
            }
                
            case 3:
            {
                iformat = GL_RGB;
                format	= GL_RGB;
                
                break;
            }
                
            case 4:
            {
                iformat = GL_RGBA;
                format	= GL_BGRA;
                
                break;
            }
        }
        
        
        if( !_tid )
        {
            
            glGenTextures( 1, &_tid );
            
            sfDebug(DEBUG_SFIMAGE, "%s got TID: %u", [[self description] UTF8String], _tid);
            
            SFGL::instance()->glBindTexture(GL_TEXTURE_2D, _tid);
            
            
            if ([self flagState:SF_IMAGE_CLAMP]){
                glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE );
                glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE );
            }
            
            
            if ( [SFGameEngine afilter] != SF_IMAGE_ISOTROPIC )
            {
                glTexParameterf( GL_TEXTURE_2D,
                                GL_TEXTURE_MAX_ANISOTROPY_EXT,
                                ( float )[SFGameEngine afilter]);
            }
            
            
            if (![self flagState:SF_IMAGE_MIPMAP]){
                glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR );
                glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR );	
            }
            else
            {
                if( [SFGameEngine tfilter] == SF_IMAGE_BILINEAR )
                {
                    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST );
                    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_NEAREST );
                }
                
                else if( [SFGameEngine tfilter] == SF_IMAGE_TRILINEAR )
                {
                    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR );
                    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_NEAREST );
                }
                
                else if( [SFGameEngine tfilter] == SF_IMAGE_QUADLINEAR )
                {
                    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR );
                    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR );
                }
                
                glTexParameteri( GL_TEXTURE_2D,
                                GL_GENERATE_MIPMAP,
                                GL_TRUE );
            }
            
            SFGL::instance()->glTexImage2D(GL_TEXTURE_2D, 0, iformat, _width,
                                           _height, 0, format, GL_UNSIGNED_BYTE, _data);
        }
        else
        {
            SFGL::instance()->glBindTexture(GL_TEXTURE_2D, _tid);
            
            SFGL::instance()->glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, _width, _height,
                                              format, GL_UNSIGNED_BYTE, _data);
        }
    [self freeTexBuffer];
}

-(float)filter{
    return _filter;
}

-(void)forcePrepare{
    [self genId];
}

-(void)prepare{
    if (!_tid) {
        [self forcePrepare];
    }
}

-(void)flipImage{
    unsigned int i    = 0,
    size = _width  *
    _height *
    _bits,
    
    rows = _width * _bits;
    
	unsigned char *buf = ( unsigned char * ) malloc( size );
    
	while( i != _height )
	{
		memcpy( buf + ( i * rows ),
               _data + ( ( (_height - i ) - 1 ) * rows ),
               rows );
		++i;
	}
	
	memcpy( &_data[ 0 ],
           &buf[ 0 ], size );
    
	free( buf );
	buf = NULL;
}

-(void)loadFromStream:(SFStream*)stream{
    unsigned char *header;
    unsigned int size;
    
    //read the type
    header = (unsigned char*)stream->readPtr(18);
    
	_width  = header[12] + header[13] * 256;
	_height = header[14] + header[15] * 256;
    _bits   = header[16] >> 3;
	
	size = _width * _height * _bits;
	
	_data = (unsigned char *) malloc(size);
    
    
	if (header[2] == 10 || header[2] == 11){
		unsigned int i,
        px_count = _width * _height,
        px_index = 0,
        by_index = 0;
		
		unsigned char chunk = 0;
        unsigned char *bgra;
        
		do
		{
			stream->read(&chunk, 1);
			if (chunk < 128) { 
				chunk++;
				
				i = 0;
				while( i != chunk )
				{
                    stream->read(&_data[by_index], _bits);
					by_index += _bits;
					
					++i;
				}
			} else {
				chunk -= 127;
				
                bgra = stream->readPtr(_bits);
                
				i = 0;
				while( i != chunk )
				{
                    memcpy( &_data[ by_index ], &bgra[0], _bits);
					by_index += _bits;
					++i;
				}				
			}
			px_index += chunk;
		} while( px_index < px_count );
	} else {
        stream->read(&_data[0], size);
    }
	
	
	if( _bits == 3 )
	{
		unsigned int i = 0;
		
		while( i != size )
		{
			unsigned char tmp = _data[ i ];
			
			_data[ i     ] = _data[ i + 2 ];
			_data[ i + 2 ] = tmp;
			
			i += 3;
		}
	}
	
	if( !header[ 17 ] || header[ 17 ] == 8 )
	{ 
        [self flipImage]; 
    }
}

@end
