//
//  SFLamp.h
//  ZombieArcade
//
//  Created by Adam Iredale on 17/02/10.
//  Copyright 2010 Stormforge Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SFLoadableGameObject.h"
#import "SFTransform.h"
#import "SFIpo.h"
#import "SFDefines.h"
#import "SFColour.h"

typedef enum
{
	SF_LAMP_NO_DIFFUSE  = ( 1 << 0 ),
	SF_LAMP_NO_SPECULAR = ( 1 << 1 )	
    
} SF_LAMP_FLAGS;


typedef enum
{
	SF_LAMP_LAMP = 0,
	SF_LAMP_SUN,
	SF_LAMP_SPOT,
	SF_LAMP_HEMI,
	SF_LAMP_AREA
    
} SF_LAMP_TYPE;

@interface SFLamp : SFLoadableGameObject {
	
	unsigned int	_index;
	
	unsigned char	_type;
	unsigned char	_vis;
	
	SFTransform *_transform;
    
	SFColour *_colour;
    
	float			_nrg;
	float			_dst;
	float			_fov;
	float			_sblend;
	float			_att1;
	float			_att2;
	
	NSString *_ipoName;
	SFIpo *_ipo;
}

-(void)render:(int)renderAsLampNumber;
-(void)switchOn;
-(void)switchOff;
@end
