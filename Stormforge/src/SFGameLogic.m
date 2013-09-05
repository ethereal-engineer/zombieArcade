//
//  SFGameLogic.m
//  ZombieArcade
//
//  Created by Adam Iredale on 2/02/10.
//  Copyright 2010 Stormforge Software. All rights reserved.
//

#import "SFGameLogic.h"
#import "SFUtils.h"

@implementation SFGameLogic

-(id)initWithDrone:(id)drone dictionary:(NSDictionary*)dictionary{
	self = [self initWithDictionary:dictionary];
	if (self != nil) {
        _drone = [drone retain];
        [self setMasterObject:_drone];
	}
	return self;
}

-(void)cleanUp{
    [super cleanUp];
    [_drone release];
    _drone = nil;
}

-(id)getDrone{
	return _drone;
}

-(id)scene{
    //override the base on this one
    //so we can request it later...
    if (!_scene) {
        [self setScene:[_drone scene]];
    }
    return [super scene];
}

+(id)logicObjectWithDrone:(id)drone dictionary:(NSDictionary*)dictionary{
	//the drone is the object that will be controlled by this class
	//it must be an SFObject at least - we are going to use it's
	//dictionary to create our object
	
	//it is expected that the drone's dictionary contains 
	//logicClass - so we know what to create
	
	Class droneLogicClass = [SFUtils getNamedClassFromBundle:[drone logicClassName]];

    //if there is no logic class name then we are in trouble!
    [SFUtils assert:droneLogicClass != nil failText:@"NO DRONE CLASS FOR LOGIC"];
    
	return [[droneLogicClass alloc] initWithDrone:drone dictionary:dictionary];
}

@end
