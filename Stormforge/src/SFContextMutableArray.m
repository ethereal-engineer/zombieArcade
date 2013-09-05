//
//  SFContextMutableArray.m
//  ZombieArcade
//
//  Created by Adam Iredale on 7/01/10.
//  Copyright 2010 Stormforge Software. All rights reserved.
//

#import "SFContextMutableArray.h"
#import "SFUtils.h"
#import "SFDebug.h"

@implementation SFContextMutableArray

@synthesize _contextId;
@synthesize _idString;

-(id)initWithContext:(unsigned char)contextId idString:(NSString*)idString{
	self = [super init];
	if (self != nil) {
		_dict = [[NSMutableDictionary alloc] init];
		_contextId = contextId;
		_idString = [idString copy];
		_sorted = [[NSMutableArray alloc] init];
	}
	return self;
}

-(void)sortUsingSelector:(SEL)sortSelector{
	[_sorted sortUsingSelector:sortSelector];
}

-(NSEnumerator*)objectEnumerator{
	return [_sorted objectEnumerator];
}

-(void)setObject:(id)anObject forKey:(id)aKey{
	id existingObject = [_dict objectForKey:aKey];
	[_dict setObject:anObject forKey:aKey];
	[_sorted addObject:anObject];
	if (existingObject) {
		[_sorted removeObject:existingObject];
	}
}

-(id)objectForKey:(id)aKey{
	return [_dict objectForKey:aKey];
}

-(void)removeObject:(id)anObject{
	[_dict removeObjectsForKeys:[_dict allKeysForObject:anObject]];
	[_sorted removeObject:anObject];
}

-(void)cleanUp{
    NSEnumerator *objects = [_dict objectEnumerator];
    for (id object in objects){
        [object cleanUp];
    }
    [self removeAllObjects];
    [_sorted release];
	[_dict release];
	[_idString release];
    [super cleanUp];
}

-(void)removeAllObjects{
	[_dict removeAllObjects];
	[_sorted removeAllObjects];
}

-(void)printKeys{
	sfDebug(TRUE, "%s (%s) Print Keys:", [self UTF8Name], [_idString UTF8String]);
	sfDebug(TRUE, "=====================");
	for (id aKey in _dict) {
		sfDebug(TRUE, (char*)[[aKey description] UTF8String]);
	}
}

-(int)count{
	return [_dict count];
}

@end
