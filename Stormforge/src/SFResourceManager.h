//
//  SFSIO2ResourceManager.h
//  ZombieArcade
//
//  Created by Adam Iredale on 7/12/09.
//  Copyright 2009 Stormforge Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import	"SFGameSingleton.h"

#define DEBUG_SFRESOURCEMANAGER 0

@interface SFResourceManager : SFGameSingleton {
	//we need a central place for the multiple resources to be referenced, regardless of what they are used for
	//so that we can restrict simultaneous destructive access over threads
	NSMutableDictionary *_resources;
	NSMutableDictionary *_itemGroups;
    NSMutableDictionary *_blackList;
}
-(id)getResourceWithDictionary:(NSDictionary*)resourceInfo;
-(NSArray*)getItemGroup:(NSString*)groupPrefix;
-(id)loadItemGroup:(NSString*)itemPrefix itemClass:(Class)itemClass;
-(NSArray*)getResourcesForClass:(Class)itemClass;
-(void)removeItem:(NSObject*)item;
-(void)flushResources;

@end
