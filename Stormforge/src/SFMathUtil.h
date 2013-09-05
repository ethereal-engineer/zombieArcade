//
//  SFMathUtil.h
//  ZombieArcade
//
//  Created by Adam Iredale on 11/12/09.
//  Copyright 2009 Stormforge Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SFObject.h"
#import "SFDefines.h"

@interface SFMathUtil : SFObject {

}

+(float)getHypotenuse:(float)sideA sideB:(float)sideB;
+(float)getFaceTargetRotationZ:(id)originObject targetObject:(id)targetObject;

@end
