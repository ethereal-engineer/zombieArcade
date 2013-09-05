//
//  SFDictionary.m
//  ZombieArcade
//
//  Created by Adam Iredale on 3/03/10.
//  Copyright 2010 Stormforge Software. All rights reserved.
//

#import "SFDictionary.h"
#import "SFUtils.h"

#define DEBUG_DICTIONARY 0

@implementation NSDictionary (SFDictionaryCat)

-(void)dealloc{
    sfDebug(DEBUG_DICTIONARY, "Deallocating dictionary %s", [[self description] UTF8String]);
    [super dealloc];
}

@end

@implementation NSMutableDictionary (SFMutableDictionaryCat)

-(void)dealloc{
    sfDebug(DEBUG_DICTIONARY, "Deallocating mutable dictionary %s", [[self description] UTF8String]);
    [super dealloc];
}

@end
