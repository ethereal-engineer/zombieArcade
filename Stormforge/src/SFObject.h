//
//  SFObject.h
//  ZombieArcade
//
//  Created by Adam Iredale on 11/11/09.
//  Copyright 2009 Stormforge Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SFProtocol.h"
#import "SFOperation.h"

#define DEBUG_SFOBJECT 0

@interface SFObject : NSObject <PObject, NSCopying> {
	//as much as possible, all objects in use will 
	//derive from this superclass - it allows us a
	//great deal of control
@private
    id _masterObject;
    char *_internalName;
    u_int64_t _uniqueId;
	NSMutableDictionary *_objectInfo;
    BOOL _autoSave; //true if we use autosave
    BOOL _isClean; //set true when cleanup is triggered
@public
    u_int64_t _flagMask; //the bitwise flag (for bit flags)
    BOOL _stopNotifyOnClean;
}

-(id)initCopyWithDictionary:(NSDictionary*)dictionary; //designated!
-(id)initWithDictionary:(NSDictionary *)dictionary;
-(void)cleanUp;

-(u_int64_t)uniqueId;
-(void)setMasterObject:(id)masterObject;
-(id)masterObject;

//bit flags (64)
-(BOOL)flagState:(u_int64_t)flag;
-(void)setFlagState:(u_int64_t)flag value:(BOOL)value;
-(void)resetFlagState:(u_int64_t)flagMask;
-(u_int64_t)flagMask;

-(id)getBaseName;
-(void)removeObjectInfoForKey:(id)key;
-(id)objectInfoForKey:(id)key useMasterInfo:(BOOL)useMasterInfo;
-(id)objectInfoForKey:(id)key useMasterInfo:(BOOL)useMasterInfo createOk:(BOOL)createOk;
-(void)saveToFile:(NSString*)fileName;
-(void)loadFromFile:(NSString *)fileName;
-(id)name;
-(void)setName:(id)name;
-(void)setUTF8Name:(char*)name;
-(void)doLoadFromFile;
-(char*)UTF8Name;
-(char*)UTF8Description;

-(void)doSaveToFile;

-(NSComparisonResult)nameCompare:(id)anOther;

-(id)objectInfoForKey:(id)key;
-(void)setObjectInfo:(id)objectInfo forKey:(id)forKey;
-(id)objectInfo;

-(void)postCopySetup:(id)aCopy;
-(void)setAutoSave:(BOOL)useAutoSave;

#if DEBUG_SFOBJECT
-(void)reportInitDealloc:(BOOL)isInit;
#endif

//class routines

+(u_int64_t)getUniqueId;

@end
