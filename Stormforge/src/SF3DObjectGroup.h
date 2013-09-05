//
//  SF3DObjectGroup.h
//  ZombieArcade
//
//  Created by Adam Iredale on 8/02/10.
//  Copyright 2010 Stormforge Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SF3DObject.h"
#import "SFTransform.h"

@interface SF3DObjectGroup : SF3DObject {
    //created for ragdolls - a group of
    //objects that are rendered as one
    //they can have constraints between them
    //easily
    float _distanceFromCamera;
    SFTransform *_relativeTransform;
    NSMutableDictionary *_subObjects;
    BOOL _cleaning;
}

-(void)addObject:(id)object objectId:(int)objectId;
-(void)cloneSubObjects:(NSDictionary*)subObjectsIn;

@end
