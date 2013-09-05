//
//  SFSingleton.h
//  ZombieArcade
//
//  Created by Adam Iredale on 12/11/09.
//  Copyright 2009 Stormforge Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SFObject.h"

@interface SFSingleton : SFObject {
	//singleton class base
}

+ (SFSingleton**)getSingletonPointer;
//points to the singleton pointer allowing easy subclassing
//note that this should only ever be implemented by the
//immediate descendant of the singleton base class

@end
