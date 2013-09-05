//
//  SFArmory.h
//  ZombieArcade
//
//  Created by Adam Iredale on 11/11/09.
//  Copyright 2009 Stormforge Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SFGameObject.h"
#import "SFTarget.h"
#import "SFProtocol.h"
#import "SFGameEngine.h"

#define SF_NOTIFY_GAME_OBJECT_READY @"SFNotifyGameObjectReady"

@interface SFGameCache : SFGameObject {
	NSMutableDictionary *_cache;
    SFOperationQueue *_cacheQueue;
    BOOL _isLive; //set true once the first item is borrowed (not precached)
}
-(void)setCacheLive;
-(void)borrowGameObject:(NSString*)objectName objectClass:(Class)objectClass forObject:(id)obj;
-(void)returnGameObject:(id)gameObject;
-(void)precacheGameObject:(NSString*)objectName objectClass:(Class)objectClass count:(int)count forObject:(id)obj;
-(void)waitUntilBorrowingIsComplete;

@end
