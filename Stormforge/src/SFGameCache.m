//
//  SFArmory.m
//  ZombieArcade
//
//  Created by Adam Iredale on 11/11/09.
//  Copyright 2009 Stormforge Software. All rights reserved.
//

#import "SFGameCache.h"
#import "SFUtils.h"
#import "SFGameInfo.h"
#import "SFResource.h"
#import "SFDebug.h"

@implementation SFGameCache

-(void)emptyCacheBlock{
    //empty the cache
    [_cache removeAllObjects];
}

-(void)cacheReport{
    //prints out a report of the cache standings
    sfDebug(TRUE, "\n\nCache Report: %s\n\n", [[_cache description] UTF8String]);
}

-(void)cleanUp{
    [_cacheQueue cleanUp];
    [_cacheQueue release];
    [self emptyCacheBlock];
    [_cache release];
    [super cleanUp];
}	

-(id)initWithDictionary:(NSDictionary*)dictionary{
	self = [super initWithDictionary:dictionary];
	if (self != nil) {
        _cache = [[NSMutableDictionary alloc] init];
        _cacheQueue = [[SFOperationQueue alloc] initQueue:YES];
#if DEBUG_SFOPERATIONQUEUE
        [_cacheQueue setName:@"gameCacheQ"];
#endif
	}
	return self;
}

-(id)getObjectCache:(NSString*)objectName{
    id objectCache;
    objectCache = [_cache objectForKey:objectName];
    if (!objectCache){
        objectCache = [[NSMutableArray alloc] init];
        [_cache setObject:objectCache forKey:objectName];
    }
    return objectCache;
}

-(void)returnObjectToCacheBlock:(id)object{
    id objectCache = [self getObjectCache:[object cacheKey]];
    [object setLeased:NO cacheKey:nil];
    [objectCache insertObject:object atIndex:0];
    [object release]; // minus refcount...(safe back in the cache)
}

-(void)returnGameObject:(id)gameObject{
    [_cacheQueue addOperation:self selector:@selector(returnObjectToCacheBlock:) object:gameObject];
}

-(id)getCachedObject:(NSString*)objectName{
    id objectCache = [self getObjectCache:objectName];
    id poppedObject = [objectCache lastObject];
        if (poppedObject) {
            [poppedObject retain]; //let it live while outside the cache
            [objectCache removeLastObject];
            sfDebug(TRUE, "%s borrowed from cache.", [[poppedObject description] UTF8String]);
        }
    return poppedObject;
}

-(void)precacheRequestComplete:(NSString*)precacheRequestName{
    sfDebug(TRUE, "Finished precaching %s.", [precacheRequestName UTF8String]);
}

-(id)duplicateGameObject:(NSString*)objectName objectClass:(Class)objectClass{
    id originalObject = [[[self rm] getItem:objectName itemClass:objectClass tryLoad:YES] retain];
    id gameObject = [originalObject copy];
    [originalObject release];
    return gameObject;
}

-(id)internalBorrowGameObject:(id)objectName objectClass:(Class)objectClass{
    //if an object isn't available in the cache, we make a new one
    id gameObject = [self getCachedObject:objectName];
    if (!gameObject) {
        sfAssert(!_isLive, "Growing the gamecache mid-game is not allowed");
        //the cache doesn't have any of the requested object
        //so we have to duplicate a new one
        printf("\n@@@ Cache is out of %s, duplicating... @@@\n", [objectName UTF8String]);
        gameObject = [self duplicateGameObject:objectName objectClass:objectClass];
        [gameObject precache];
    }
    [gameObject setScene:_scene];
    [gameObject setLeased:YES cacheKey:objectName];
    return gameObject;
}

-(void)setCacheLive{
    _isLive = YES;
}

-(void)borrowGameObjectBlock:(NSDictionary*)objectInfo{
    id gameObject = [self internalBorrowGameObject:[objectInfo objectForKey:@"objectName"]
                                       objectClass:[objectInfo objectForKey:@"objectClass"]];
    [[SFGameEngine defaultQueue] addOperation:gameObject
                                     selector:@selector(objectBorrowedOk:)
                                       object:[objectInfo objectForKey:@"forObject"]];
}

-(void)precacheGameObjectBlock:(NSDictionary*)objectInfo{
    //can't do recursive precaching - just simple!
    id objectName = [objectInfo objectForKey:@"objectName"];
    Class objectClass = [objectInfo objectForKey:@"objectClass"];
    int precacheAmount = [[objectInfo objectForKey:@"count"] integerValue];
    sfDebug(TRUE, "Precaching %d x %s...", precacheAmount, [objectName UTF8String]);
    //check them out in bulk
    NSMutableArray *precached = [[NSMutableArray alloc] init];
    for (int i = 0; i < precacheAmount; ++i) {
        id gameObject = [self internalBorrowGameObject:objectName objectClass:objectClass];
        [precached addObject:gameObject];
    }
    //return them immediately after (we have now expanded the cache's size)
    for (id gameObject in precached) {
        [self returnObjectToCacheBlock:gameObject];
    }
    [precached release];
    [[SFGameEngine defaultQueue] addOperation:[objectInfo objectForKey:@"forObject"]
                                     selector:@selector(gameObjectsPrecachedOk)
                                       object:nil];
}

-(void)borrowGameObject:(NSString *)objectName objectClass:(Class)objectClass forObject:(id)obj{
    [_cacheQueue addOperation:self 
                     selector:@selector(borrowGameObjectBlock:)
                       object:[NSDictionary dictionaryWithObjectsAndKeys:objectName, @"objectName",
                               objectClass, @"objectClass",
                               obj, @"forObject", nil]];
}

-(void)precacheGameObject:(NSString*)objectName objectClass:(Class)objectClass count:(int)count forObject:(id)obj{
    [_cacheQueue addOperation:self 
                     selector:@selector(precacheGameObjectBlock:)
                       object:[NSDictionary dictionaryWithObjectsAndKeys:objectName, @"objectName",
                               objectClass, @"objectClass",
                               obj, @"forObject", 
                               [NSNumber numberWithInt:count], @"count", nil]];    
}

-(void)waitUntilBorrowingIsComplete{
    [_cacheQueue waitUntilAllOperationsAreFinished];
}

@end
