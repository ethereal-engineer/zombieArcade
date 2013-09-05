//
//  SFTextureAtlas.m
//  ZombieArcade
//
//  Created by Adam Iredale on 13/04/10.
//  Copyright 2010 Stormforge Software. All rights reserved.
//

#import "SFTextureAtlas.h"
#import "SFUtils.h"
#import "SFDebug.h"

@implementation SFTextureAtlas

-(SFImage*)atlasImage{
    return _image;
}

-(void)processAtlas{
    //first load the image (a large atlas, which may already be loaded)
    
    _image = [[[self rm] getItem:[self objectInfoForKey:@"filename"] itemClass:[SFImage class] tryLoad:YES] retain];
    [SFUtils assert:(_image != nil) failText:@"\nAtlas image not found\n"];
    
    //now, for each of the strip references, we create and build strips
    _stripInfo = [[self objectInfoForKey:@"strips"] retain];
    [SFUtils assert:(_stripInfo != nil) failText:@"\nNo strips for atlas\n"];
    
    //the number of strips determines the size of our atlas strip array
    _strips = (SFAtlasStrip**)calloc([_stripInfo count], sizeof(SFAtlasStrip*));
    
    CGPoint atlasDimensions = CGPointMake([_image width], [_image height]);

    for (NSString *stripName in _stripInfo) {
        NSDictionary *strip = [_stripInfo objectForKey:stripName];
        //there's only two things we are interested in at the moment with the strip info,
        //and that's the first cell dimensions and offset (origin) and the number of
        //cells that this strip contains (size) in horizontal and vertical areas
        CGRect firstCell = CGRectFromString([strip objectForKey:@"origin"]);
        CGPoint stripSize = CGPointFromString([strip objectForKey:@"size"]);
        //now we have all the info we need to build our strip
        _strips[_stripCount] = new SFAtlasStrip(atlasDimensions, firstCell, stripSize);
        //and put a name in the names list to allow searching for it
        [_stripNames addObject:stripName];
        ++_stripCount;
    }
}

-(SFAtlasStrip*)getStrip:(NSString *)stripName{
    return _strips[[_stripNames indexOfObject:stripName]];
}

-(NSDictionary*)getStripInfo:(NSString *)stripName{
    return [_stripInfo objectForKey:stripName];
}

-(id)initWithDictionary:(NSDictionary *)dictionary{
    self = [super initWithDictionary:dictionary];
    if (self != nil){
        _stripNames = [[NSMutableArray alloc] init];
        [self processAtlas];
        sfDebug(TRUE, "Texture atlas %s loaded.", [_image UTF8Name]);
    }
    return self;
}

-(void)cleanUp{
    for (int i = 0; i < _stripCount; ++i) {
        delete _strips[i];
    }
    free(_strips);
    sfDebug(TRUE, "Texture atlas %s unloading...", [_image UTF8Name]);
    [[self rm] removeItem:_image];
    [_image release];
    [_stripInfo release];
    [_stripNames release];
    [super cleanUp];
}

@end
