//
//  SFHealthWidget.m
//  ZombieArcade
//
//  Created by Adam Iredale on 19/01/10.
//  Copyright 2010 Stormforge Software. All rights reserved.
//

#import "SFHealthWidget.h"
#import "SFConst.h"
#import "SFColour.h"

@implementation SFHealthWidget

#define HEALTH_FLASH_ON 0.5f
#define HEALTH_FLASH_OFF 0.5f

-(void)setHealthValue:(float)value{
	//eventually we could make this so it reduces vertically by option
	if (value < _minValue) {
		value = _maxValue;
	} else if (value > _maxValue) {
		value = _maxValue;
	}
	_currentValue = value;
	_transform->scl()->setX((value / (_maxValue - _minValue)));
	_transform->compileMatrix();
	//deal with low-value flashing
	if ((value) and (_flashLowValue) and (value <= _flashLowValue)){
		[_material flash:COLOUR_80PC_TRANSPARENT
                       flashOn:HEALTH_FLASH_ON 
                      flashOff:HEALTH_FLASH_OFF];
	} else {
		[_material flashOff];
	}
	
}

-(id)initHealthWidget:(NSString*)atlasName
            atlasItem:(NSString*)atlasItem
			 maxValue:(float)maxValue 
			 minValue:(float)minValue 
			 position:(vec2)position 
			  visible:(BOOL)visible{
	
	self = [self initWidget:atlasName
                   atlasItem:atlasItem
					position:position
					centered:NO
			   visibleOnShow:visible
			   enableOnShow:NO];
	if (self != nil) {
        _minValue = minValue;
        _maxValue = maxValue;
		[self setHealthValue:maxValue];
	}
	return self;
}

-(vec4)getDefaultDiffuse{
	float scaledValue = (_currentValue / _maxValue);
	if (scaledValue > 0.9f) {
		return COLOUR_SOLID_GREEN;
	} else if (scaledValue > 0.5f) {
		return COLOUR_SOLID_YELLOW;
	} else if (scaledValue > 0.3f) {
		return COLOUR_SOLID_AMBER;
	} else {
		return COLOUR_SOLID_RED;
	}
}

-(void)flashAtLessThan:(float)flashValue{
	_flashLowValue = flashValue;
}

-(BOOL)render{
    [[self material] setDefaultDiffuse:[self getDefaultDiffuse]];
    return [super render];
}

@end
