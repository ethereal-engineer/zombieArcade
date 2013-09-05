//
//  SFTextureAtlas.h
//  ZombieArcade
//
//  Created by Adam Iredale on 13/04/10.
//  Copyright 2010 Stormforge Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SFGameObject.h"
#import "SFAtlasStrip.h"
#import "SFImage.h"

@interface SFTextureAtlas : SFGameObject {
    //allows us to fully index a texture atlas
    //before using it, storing the UV-coordinate
    //strips, ready for rendering
    SFImage *_image;
    NSDictionary *_stripInfo;
    NSMutableArray *_stripNames;
    SFAtlasStrip **_strips;
    int _stripCount;
}

-(NSDictionary*)getStripInfo:(NSString*)stripName;
-(SFAtlasStrip*)getStrip:(NSString*)stripName;
-(SFImage*)atlasImage;

@end
