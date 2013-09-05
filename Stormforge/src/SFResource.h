//
//  SFSIO2Resource.h
//  ZombieArcade
//
//  Created by Adam Iredale on 13/11/09.
//  Copyright 2009 Stormforge Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SFGameObject.h"
#import "unzip.h"
#import "SFDefines.h"
#import "SFStack.h"
#import "SFOperationQueue.h"

#define DEBUG_SFRESOURCE 0

typedef enum {
    ltsNoMore,
    ltsMore
} SFLoadTaskStatus;

@interface SFResource : SFGameObject <PResource> {
    //a library that manages loading items from
    //disk and keeping them in (and removing them from)
    //memory
	NSMutableDictionary *_itemDictionaries;
    NSMutableDictionary *_itemGroups;
    BOOL _fullyLoaded;
    SFStack *_loadTasks;
    int _itemsLoaded;
    BOOL _loadTasksSetupOk;
    SFOperationQueue *_resourceQueue;
}

-(void)addMemoryItem:(id)newItem;
-(void)removeMemoryItem:(id)object;
-(id)getItem:(NSString*)itemName itemClass:(Class)itemClass;
-(NSArray*)getItemGroup:(NSString*)groupPrefix itemClass:(Class)itemClass;
-(id)getItem:(NSString*)itemName itemClass:(Class)itemClass tryLoad:(BOOL)tryLoad;
-(id)getItemFromDisk:(NSString*)filename itemClass:(Class)itemClass dictionary:(NSDictionary*)dictionary;
-(id)getItemFromMemory:(NSString *)itemName itemClass:(Class)itemClass;
-(void)addLoadTask:(SEL)sel object:(id)obj;
-(id)get3DObject:(NSString*)objectName;
-(id)getItemEnumerator:(Class)itemClass;
-(BOOL)loadDelta;
-(BOOL)isReady;
-(void)setupLoadTasks;
-(unzFile)archiveOpen:(unz_global_info*)archiveInfo;
-(void)archiveMoveToFirstFile:(unzFile)archive;
-(void)precacheAll;
@end
