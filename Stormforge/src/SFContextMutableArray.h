//
//  SFContextMutableArray.h
//  ZombieArcade
//
//  Created by Adam Iredale on 7/01/10.
//  Copyright 2010 Stormforge Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SFObject.h"

@interface SFContextMutableArray : SFObject {
	//I am pretty sure this is doable in other ways but
	//this is quickest and easiest right now
	NSMutableDictionary *_dict;
	unsigned char _contextId; //allows quick sorting as to what this holds
	NSString *_idString; //for whatever
	NSMutableArray *_sorted;
}

-(id)initWithContext:(unsigned char)contextId idString:(NSString*)idString;
-(int)count;
-(void)setObject:(id)anObject forKey:(id)aKey;
-(id)objectForKey:(id)aKey;
-(void)removeObject:(id)anObject;
-(void)removeAllObjects;
-(NSEnumerator*)objectEnumerator;
-(void)printKeys;
@property (nonatomic, readonly) unsigned char _contextId;
@property (nonatomic, readonly) NSString *_idString;

@end
