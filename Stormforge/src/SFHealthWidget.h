//
//  SFHealthWidget.h
//  ZombieArcade
//
//  Created by Adam Iredale on 19/01/10.
//  Copyright 2010 Stormforge Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SFWidget.h"

@interface SFHealthWidget : SFWidget {
	//a health bar widget that reduces in width with percentage
	float _flashLowValue;
	float _currentValue, _minValue, _maxValue;
}

-(id)initHealthWidget:(NSString*)atlasName
            atlasItem:(NSString*)atlasItem
			 maxValue:(float)maxValue 
			 minValue:(float)minValue 
			 position:(vec2)position 
			  visible:(BOOL)visible;

-(void)flashAtLessThan:(float)flashValue;
-(void)setHealthValue:(float)value;

@end
