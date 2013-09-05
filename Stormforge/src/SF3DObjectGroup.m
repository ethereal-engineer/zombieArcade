//
//  SF3DObjectGroup.m
//  ZombieArcade
//
//  Created by Adam Iredale on 8/02/10.
//  Copyright 2010 Stormforge Software. All rights reserved.
//

#import "SF3DObjectGroup.h"

@implementation SF3DObjectGroup

-(void)addObject:(id)object objectId:(int)objectId{
    //objectId isn't used here but it will be later
    [_subObjects setObject:object forKey:[NSNumber numberWithInt:objectId]];
    //force this object always to be drawn when we are
    [object forceImmediateExistance];
}

-(void)show{
    [super show];
    NSEnumerator *subObjects = [_subObjects objectEnumerator];
    for (id object in subObjects) {
        [object show];
    }
}

-(void)setCollisionFlags:(unsigned int)collisionFlags{
    NSEnumerator *subObjects = [_subObjects objectEnumerator];
    for (id object in subObjects) {
        [object setCollisionFlags:collisionFlags];
    }
}

-(void)hide{
    NSEnumerator *subObjects = [_subObjects objectEnumerator];
    for (id object in subObjects) {
        [object hide];
    }
    [super hide];
}

-(void)cloneSubObjects:(NSDictionary*)subObjectsIn{
    //if this is a copy, clone the subobjects
    //otherwise just wait for them to be added
    for (NSNumber *objectId in subObjectsIn) {
        SF3DObject *object = [subObjectsIn objectForKey:objectId];
        id newObject = [object copy];
        [self addObject:newObject objectId:[objectId intValue]];
        [newObject release];
    }
}

-(void)setFirstSpawnTransform:(SFTransform*)transform{
    [super setFirstSpawnTransform:transform];
    //update our internal (relative to all of the subparts) transform
    _relativeTransform->setFromTransform(transform);
    //we want to setup the locations of all of our sub parts based on this transform
    NSEnumerator *enumerator = [_subObjects objectEnumerator];
	for (SF3DObject *part in enumerator) {
		SFTransform *partTransform = [part transform];
        //I think the rotation would be bind the original location transform then rotate then bind
        partTransform->loc()->add(_relativeTransform->loc()); //add the relative transform location as an offset
        [part setFirstSpawnTransform:partTransform];
	}
}

-(id)initCopyWithDictionary:(NSDictionary *)dictionary{
    self = [super initCopyWithDictionary:dictionary];
    if (self != nil) {
        _relativeTransform = new SFTransform();
        _distanceFromCamera = 1.0f;
        _subObjects = [[NSMutableDictionary alloc] init];
    }
    return self;
}

-(id)initWithDictionary:(NSDictionary *)dictionary{
    self = [super initWithDictionary:dictionary];
    if (self != nil) {
        
    }
    return self;
}

-(float)getCameraDistance{
    return _distanceFromCamera;  //for now
}

-(void)updateDistanceFromCamera:(SFCamera*)camera{
    _distanceFromCamera = [camera sphereDistInFrustum:_relativeTransform->loc() radius:1.0f];
    NSEnumerator *subObjects = [_subObjects objectEnumerator];
    for (id object in subObjects) {
        [object updateDistanceFromCamera:camera];
    }
}

-(BOOL)render:(unsigned int)renderPass matrixTransform:(unsigned char)matrixTransform useMaterial:(BOOL)useMaterial{
    [super render:renderPass matrixTransform:matrixTransform useMaterial:useMaterial];
    //don't bother processing sub objects if we don't exist in the world
    if (_worldState != wsExists) {
         return NO;
    }
    NSEnumerator *objects = [_subObjects objectEnumerator];
    for (id object in objects) {
        [object render:renderPass matrixTransform:matrixTransform useMaterial:useMaterial];
    }
    return YES;    
}

-(void)cleanUp{
    _cleaning = YES;
    [_subObjects removeAllObjects];
    [_subObjects release];
    delete _relativeTransform;
    [super cleanUp];
}

-(void)postCopySetup:(id)aCopy{
    [super postCopySetup:aCopy];
    [aCopy cloneSubObjects:_subObjects];
}

@end
