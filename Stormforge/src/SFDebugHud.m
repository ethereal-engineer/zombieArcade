//
//  SFDebugHud.m
//  ZombieArcade
//
//  Created by Adam Iredale on 11/02/10.
//  Copyright 2010 Stormforge Software. All rights reserved.
//

#import "SFDebugHud.h"

static float gHudOffset = DEFAULT_DEBUG_HUD_OFFSET / 2.0f;

@implementation SFDebugHud

-(void)setupKVO:(BOOL)observe{
    id kvoObject = [self objectInfoForKey:@"kvoObject"];
    id observeKeys = [self objectInfoForKey:@"observeKeys"];
    id options = [self objectInfoForKey:@"options"];
    
    for (id observeKey in observeKeys) {
        if (observe) {
            [kvoObject addObserver:self
                        forKeyPath:observeKey
                           options:[options unsignedIntegerValue]
                           context:NULL];
        } else {
            [kvoObject removeObserver:self forKeyPath:observeKey];
        }
    }
}

-(float)getOriginalYPos{
    return [[self objectInfoForKey:@"originalYPos"] floatValue];
}

//-(BOOL)renderFlatObject{
//    //set caption and adjust position to keep text on screen
//    id description;
//   // @synchronized(_observedValues){
//        description = [_observedValues description];
//   // }
//    id dLines = [description componentsSeparatedByString:@"\n"];
//    //delete the first and last lines (which are brackets)
//    [dLines removeObjectAtIndex:0];
//    [dLines removeLastObject];
//    id dStringFinal;
//    if ([dLines count] == 0) {
//        dStringFinal = @"{}";
//    } else {
//        dStringFinal = [[dLines componentsJoinedByString:@"\n"] stringByReplacingOccurrencesOfString:@"  " withString:@""];
//    }
//
//    [self setCaption:dStringFinal];
//    // [self setPosition:(vec2){[self getPosition].x, (([dLines count] - 1) * DEFAULT_DEBUG_HUD_OFFSET) + [self getOriginalYPos]}];
//    return [super renderFlatObject];
//}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    //values have been updated - update the label
  //  @synchronized(_observedValues){
        [_observedValues setObject:[change objectForKey:NSKeyValueChangeNewKey] forKey:keyPath];
  //  }
}

-(void)cleanUp{
    [self setupKVO:NO];
    [_observedValues release];
    [super cleanUp];
}

+(float)getNewHudOffset{
    float newOffset;
   // @synchronized([SFDebugHud class]){
        float offset = gHudOffset;
        gHudOffset += DEFAULT_DEBUG_HUD_OFFSET;
        newOffset = offset;
   // }
    return newOffset;
}
     
-(id)initWithKVO:(id)kvoObject observeKeys:(NSArray*)observeKeys options:(NSKeyValueObservingOptions)options{
    
   // float originalYPos = [SFDebugHud getNewHudOffset];
    
 //   self = [self initLabel:@"debugHud"
//                  fontName:DEFAULT_DEBUG_HUD_FONT
//            initialCaption:@"<debugHud>"
//                  position:Vec2Make(DEFAULT_DEBUG_HUD_OFFSET / 2.0f, originalYPos)
//             visibleOnShow:YES
//            callbackObject:nil
//          callbackSelector:nil
//         updateViaCallback:NO
//                dictionary:[NSDictionary dictionaryWithObjectsAndKeys:kvoObject, @"kvoObject", 
//                            observeKeys, @"observeKeys", 
//                            [NSNumber numberWithUnsignedInt:options], @"options",
//                            [NSNumber numberWithInt:originalYPos], @"originalYPos",
//                            nil]];
    if (self != nil) {
        _observedValues = [[NSMutableDictionary alloc] initWithCapacity:[[self objectInfoForKey:@"observeKeys"] count]];
        [self setupKVO:YES];
    }
    return self;
}

+(id)debugHudWithKVO:(id)kvoObject observeKeys:(NSArray*)observeKeys options:(NSKeyValueObservingOptions)options{
    return [[[self alloc] initWithKVO:kvoObject observeKeys:observeKeys options:options] autorelease];
}

@end
