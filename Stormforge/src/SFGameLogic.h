//
//  SFGameLogic.h
//  ZombieArcade
//
//  Created by Adam Iredale on 2/02/10.
//  Copyright 2010 Stormforge Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SFGameObject.h"

@interface SFGameLogic : SFGameObject {
    id _drone; //that which is controlled
}
-(id)getDrone;
-(id)initWithDrone:(id)drone dictionary:(NSDictionary*)dictionary;
+(id)logicObjectWithDrone:(id)drone dictionary:(NSDictionary*)dictionary;

@end
