//
//  SFStreamObjectFactory.h
//  ZombieArcade
//
//  Created by Adam Iredale on 4/03/10.
//  Copyright 2010 Stormforge Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SFObject.h"
#import "SFStream.h"

#define DEBUG_SFSTREAMOBJECTFACTORY 0

@interface SFStreamObjectFactory : SFObject {
    //pretty simple - takes in a (for now) SFStream
    //and creates our objects from it
}

+(id)newObjectFromStream:(SFStream*)stream dictionary:(NSDictionary*)dictionary;
+(id)newObjectFromStream:(SFStream*)stream dictionary:(NSDictionary*)dictionary classOverride:(Class)classOverride;
@end
