//
//  SFFont.h
//  ZombieArcade
//
//  Created by Adam Iredale on 16/02/10.
//  Copyright 2010 Stormforge Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SFObject.h"
#import "SFMaterial.h"
#import "SFImage.h"

@interface SFFont : SFImage {
    
    unsigned int	_vbo;
    float          *_buf;
	unsigned int	_boffset;
    
	unsigned char	_n_char;
	unsigned char	_c_offset;
	
	float			_size;
	float			_space, _wideSpace, _thinSpace;
    float           _line_space;
    BOOL            _isFixedWidth;
}

@end
