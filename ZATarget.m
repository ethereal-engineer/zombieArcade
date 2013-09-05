//
//  ZATarget.m
//  ZombieArcade
//
//  Created by Adam Iredale on 21/10/09.
//  Copyright 2009 Stormforge Software. All rights reserved.
//

#import "ZATarget.h"
#import "SFUtils.h"

@implementation SFTarget (ZATarget)

-(id)customMaterial:(NSString*)matName destVertGroup:(NSString*)destVertGroup{
    id customMat = [self objectInfoForKey:matName useMasterInfo:NO createOk:NO];
    if (!customMat) {
        customMat = [[SFMaterial alloc] initWithName:[[self name] stringByAppendingString:matName] dictionary:nil];
        [self setObjectInfo:customMat forKey:matName];
        [[_vertexGroups objectForKey:destVertGroup] setMaterial:customMat];
        [customMat release];
    }
    return customMat;
}

-(void)setRandomMatImage:(NSString*)matName imageGroup:(NSString*)imageGroup{
    id material = [self customMaterial:matName destVertGroup:matName];
    id texture = [SFUtils getRandomFromArray:[[self rm] getItemGroup:imageGroup itemClass:[SFImage class]]];
    [texture setFlagState:SF_IMAGE_MIPMAP value:YES]; //mipmap the clothes
    [texture prepare];
    [material setTexture:SF_MATERIAL_CHANNEL0 texture:texture];
}

-(void)shuffleClothesTextures{
	[self setRandomMatImage:@"shirt" imageGroup:@"shirt"];
    [self setRandomMatImage:@"pants" imageGroup:@"pants"];
}

-(void)prepareObjectExtension{
    //this is where we shuffle the clothes
    _objectAlliance = oaEnemy;
    [self shuffleClothesTextures];
}

+(NSDictionary*)actionDictionary{
    return [NSDictionary dictionaryWithObjectsAndKeys:@"walk", @"walk",
            @"idle", @"idle", 
            @"attack", @"attack",
            @"turn", @"turnLeft",
            @"turn", @"turnRight",
            nil];
}

@end
