//
//  SFFont.m
//  ZombieArcade
//
//  Created by Adam Iredale on 16/02/10.
//  Copyright 2010 Stormforge Software. All rights reserved.
//

#import "SFFont.h"
#import "SFGL.h"
#import "SFUtils.h"
#import "SFStream.h"

@implementation SFFont



-(id)initWithSFStream:(SFStream *)stream dictionary:(NSDictionary *)dictionary{
    self = [super initWithSFStream:stream dictionary:dictionary];
    if (self != nil) {
        //get the font's config info
        NSDictionary *fontDictionary = [[self gi] getFontDictionary:[self name]];
        _n_char = [[fontDictionary objectForKey:@"charactersPerRow"] intValue];  //number of chars to a line in the image
        _size = _width / _n_char;  //pixels per char (image width div number of chars per row)
        _space = [[fontDictionary objectForKey:@"characterSpacing"] intValue]; //pixels to move by when moving to next character
        _c_offset = [[fontDictionary objectForKey:@"characterOffset"] intValue]; //how many characters from the ascii map were skipped
        _line_space = [[fontDictionary objectForKey:@"lineSpacing"] intValue]; //pixels to move by when moving to next character
        _isFixedWidth = [[fontDictionary objectForKey:@"fixedWidth"] boolValue];
        _wideSpace = [[fontDictionary objectForKey:@"wideSpace"] intValue];
        _thinSpace = [[fontDictionary objectForKey:@"thinSpace"] intValue];
        [self build];
    }
    return self;
}

-(float)lineSpacing{
    return _line_space;
}

-(void)setCharacterCols:(int)characterCols{
    _n_char = characterCols;
}

-(void)setSize:(int)size{
    _size = size;
    _space = size / 2.0f;
}

-(GLuint)vbo{
    return _vbo;
}

-(unsigned char)c_offset{
    return _c_offset;
}

-(unsigned int)boffset{
    return _boffset;
}

-(float)space{
    return _space;
}

-(float)size{
    return _size;
}

-(void)bindFont{
#if SF_USE_GL_VBOS
    if (SFGL::instance()->glBindBuffer(GL_ARRAY_BUFFER, _vbo)){
#endif
        SFGL::instance()->glVertexPointer(2, GL_FLOAT, 0, SF_BUFFER_OFFSET(0, _buf));
        SFGL::instance()->glTexCoordPointer(2, GL_FLOAT, 0, SF_BUFFER_OFFSET(_boffset, _buf));
#if SF_USE_GL_VBOS
        SFGL::instance()->glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
    }    
#endif
}



-(void)cleanUp{
#if SF_USE_GL_VBOS
    SFGL::instance()->glDeleteBuffers(1, &_vbo);
#endif
    [super cleanUp];
}

-(void)build{
    unsigned int i = 0,
    boffset;
	
    float imageWidth = _width;
    float imageHeight = _height;
    
	unsigned short size = (imageWidth/ _n_char) * (imageHeight/ _n_char);
	
	_buf = ( float * ) malloc( size << 6 );
    float ratiox = _size / imageWidth,	
    ratioy	   = _size / imageHeight,
    ratiowx	   = imageWidth / _size,
    ratiohy	   = imageHeight / _size,
    hsize	   = _size * 0.5f,
    
    v_coord[ 8 ] = { -hsize, -hsize,
                      hsize, -hsize,
                      hsize,  hsize,
                     -hsize,  hsize };
    
	boffset = size << 3;
	_boffset = size << 5;
    
	while( i != size )
	{
		float cx = ( float )( i % _n_char ) / ratiowx,
              cy = ( float )( i / _n_char ) / ratiohy,
              t_coord[ 8 ];
        
		t_coord[ 0 ] = cx		  ; t_coord[ 1 ] = 1.0f + ( cy + ratioy );
		t_coord[ 2 ] = cx + ratiox; t_coord[ 3 ] = 1.0f + ( cy + ratioy );
		t_coord[ 4 ] = cx + ratiox; t_coord[ 5 ] = 1.0f + cy;
		t_coord[ 6 ] = cx		  ; t_coord[ 7 ] = 1.0f + cy;
        
		memcpy( &_buf[   i << 3 	           ], &v_coord[ 0 ], 32 );
		memcpy( &_buf[ ( i << 3 ) + boffset ], &t_coord[ 0 ], 32 );
        
		++i;
	}
	
#if SF_USE_GL_VBOS
	glGenBuffers( 1, &_vbo );
	
	SFGL::instance()->glBindBuffer(GL_ARRAY_BUFFER, _vbo);
	
    SFGL::instance()->glBufferData(GL_ARRAY_BUFFER, (size << 6), &_buf[0], GL_STATIC_DRAW);
	free(buf);
	
	SFGL::instance()->glBindBuffer(GL_ARRAY_BUFFER,0);
#endif
}

@end
