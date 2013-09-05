//
//  SFObject.m
//  ZombieArcade
//
//  Created by Adam Iredale on 11/11/09.
//  Copyright 2009 Stormforge Software. All rights reserved.
//

#import "SFObject.h"
#import "SFDefines.h"
#import "SFUtils.h"
#import "SFGameEngine.h" //might want to subclass to gameobject
#import "SFSound.h"
#import "SFDebug.h"

#define DEBUG_RETAIN_RELEASE 0

#if DEBUG_SFOBJECT
static const Class gInitDeallocClass = [SFUtils getNamedClassFromBundle:@"SF3DObject"];
#endif

static u_int64_t gSFObjectClassUniqueId = 0;

@implementation SFObject

-(id)name{
	if (_internalName) {
        return [NSString stringWithUTF8String:_internalName];
    } else {
        return [[NSNumber numberWithUnsignedInteger:_uniqueId] stringValue];
    }
}

-(void)setName:(id)name{
    [self setUTF8Name:(char*)[name UTF8String]];
}

-(id)objectInfo{
    //created only when used
    if (!_objectInfo) {
        _objectInfo = [[NSMutableDictionary alloc] init];
    }
    return _objectInfo;
}

-(void)saveToFile:(NSString*)fileName{
	//override
}

-(void)loadFromFile:(NSString*)fileName{
	//override
}

-(void)doSaveToFile{
	[self saveToFile:[self name]];
}

-(BOOL)isClean{
    return _isClean;
}

-(void)cleanUp{
	//this is to be a well known routine that is called to free all scarce resources
	//(to do what "dealloc" should do if it were called predictably)
	
	//remove all callbacks
    //for any calls to notifyme - will auto-trigger this
    if (_stopNotifyOnClean) {
        [[NSNotificationCenter defaultCenter] removeObserver:self];
    }
    
	//process autosave
	if (_autoSave) {
		[self doSaveToFile];
        //disable
		[self setAutoSave:NO];
	}
    if (_objectInfo) {
        [_objectInfo removeAllObjects];
        [_objectInfo release];
    }
    
    //release our master object if we have one
    [_masterObject release];
    [self setName:nil];
    _isClean = YES;
}

-(NSComparisonResult)nameCompare:(id)anOther{
	SFObject *otherObj = (SFObject*)anOther;
	return [[self name] compare:[otherObj name]];
}

-(u_int64_t)uniqueId{
    return _uniqueId;
}

-(void)doLoadFromFile{
	[self loadFromFile:[self name]];
}

-(void)saveNotified:(NSNotification*)saveNotice{
	[self doSaveToFile];
}

-(void)setAutoSave:(BOOL)useAutoSave{
	if (useAutoSave){
		//register for save notification
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(saveNotified:) 
													 name:SF_NOTIFY_SAVE_DATA 
												   object:nil];
		_autoSave = YES;
        [self doLoadFromFile];
	} else {
		//unregister for save notification
		[[NSNotificationCenter defaultCenter] removeObserver:self 
														name:SF_NOTIFY_SAVE_DATA 
													  object:nil];
		_autoSave = NO;
	}
	
}

+(u_int64_t)getUniqueId{
    @synchronized(self){
        ++gSFObjectClassUniqueId;
    }
	return gSFObjectClassUniqueId;
}

-(void)objectDidInit{
    //hook
}

-(id)init{
	self = [super init];
	if (self != nil) {
        _uniqueId = [SFObject getUniqueId];
#if DEBUG_SFOBJECT
		[self reportInitDealloc:YES];
#endif
        [self objectDidInit];
	}
	return self;
}

-(id)valueForUndefinedKey:(NSString *)key{
	return [self objectInfoForKey:key];
}

-(void)setValue:(id)value forUndefinedKey:(NSString *)key{
	//if there are no other places to set the value, it goes
	//in the object info dictionary
	[self setObjectInfo:value forKey:key];
}

-(char*)UTF8Name{
    return _internalName;
}

-(id)initCopyWithDictionary:(NSDictionary*)dictionary{
    self = [self init];
	if (self != nil) {
        _internalName = nil;
		if (dictionary) {
			[[self objectInfo] addEntriesFromDictionary:dictionary];
		}
	}
	return self;
}

-(id)initWithDictionary:(NSDictionary*)dictionary{
	self = [self initCopyWithDictionary:dictionary];
	if (self != nil) {

	}
	return self;
}

#if DEBUG_SFOBJECT
-(void)reportInitDealloc:(BOOL)isInit{
	if ([[self class] isSubclassOfClass:gInitDeallocClass]) {
		if (isInit) {
			sfDebug(TRUE, "INIT <%s:0x%x>", [[[self class] description] UTF8String], self);
		} else {
			sfDebug(TRUE, "DEALLOC %s", [self UTF8Description]);
		}

	}
}

-(void)reportRetain{
    if ([[self class] isSubclassOfClass:gInitDeallocClass]) {
        sfDebug(TRUE, "RETAIN %d %s", [self retainCount], [self UTF8Description]);
	}
}

-(void)reportRelease{
    if ([[self class] isSubclassOfClass:gInitDeallocClass]) {
        sfDebug(TRUE, "RELEASE %d %s", [self retainCount], [self UTF8Description]);
	}
}
#endif

-(void)setUTF8Name:(char*)name{
    
    int newNameLength = 0;
    if (name) {
        newNameLength = strlen(name);
    }
	
    if (newNameLength == 0) {
        if (_internalName) {
            free(_internalName);
            _internalName = nil;
        }
        return;
    }
    
    //note - if the last char of the name is '/' - this will cause a problem
    //but I'm not checking for it...
    
    //remember we only want the last path component 
    //so backtrace this until we either reach 0 or a '/'
    char *namePtr = &name[newNameLength - 1];
    newNameLength = 1;
    while (namePtr != &name[0]) {
        if (*namePtr == '/') {
            ++namePtr;
            --newNameLength;
            break;
        }
        --namePtr;
        ++newNameLength;
    }
    //have we killed the name??
    if (!newNameLength) {
        return;
    }
    
    _internalName = (char*)realloc(_internalName, (newNameLength + 1) * sizeof(char));
    memcpy(_internalName, namePtr, newNameLength);
    _internalName[newNameLength] = 0;
}

-(void)objectDidFree{
    //hook
}

-(void)dealloc{
    [self objectDidFree];
#if DEBUG_SFOBJECT
	[self reportInitDealloc:NO];
#endif
    //if we haven't been cleaned, we clean up
    if (!_isClean) {
        [self cleanUp];
    }
	[super dealloc];
}

-(id)getObjectInfoForCopy{
	return [self objectInfo];
}

-(void)setMasterObject:(id)masterObject{
    _masterObject = [masterObject retain];
}

-(id)masterObject{
    return _masterObject;
}

-(id)getBaseName{
	return [[self masterObject] name];
}

-(id)objectInfoForKey:(id)key useMasterInfo:(BOOL)useMasterInfo createOk:(BOOL)createOk{
	id objectInfo = [[self objectInfo] objectForKey:key];
	if (!objectInfo){
		if ((useMasterInfo) and (_masterObject!=nil)) {
			objectInfo = [_masterObject objectInfoForKey:key useMasterInfo:NO createOk:NO];
		}
        if (objectInfo) {
            return objectInfo;
        }
        if ((!objectInfo) and createOk) {
            //still doesn't exist in the master - create one if allowed
            objectInfo = [[NSMutableDictionary alloc] init];
            [self setObjectInfo:objectInfo forKey:key];
            [objectInfo release];
        }
	}
	return objectInfo;
}

-(void)removeObjectInfoForKey:(id)key{
    //will only remove our own - not master info
    [[self objectInfo] removeObjectForKey:key];
    //if we are empty, set ourselves to nil
    if (![_objectInfo count]) {
        //double check that it didn't change while we waited
        [_objectInfo release];
        _objectInfo = nil;
    }
}

-(id)objectInfoForKey:(id)key useMasterInfo:(BOOL)useMasterInfo{
	return [self objectInfoForKey:key useMasterInfo:useMasterInfo createOk:NO];
}

-(id)objectInfoForKey:(id)key{
	//try the original location and if
	//it's not there, try the "master" 
	//location (if this is a copy)
	return [self objectInfoForKey:key useMasterInfo:YES];
}

-(void)setObjectInfo:(id)objectInfo forKey:(id)forKey{
	//sets our info (the copy info should always be read only)
	[[self objectInfo] setObject:objectInfo forKey:forKey];
}

-(char*)UTF8Description{
    return (char*)[[self description] UTF8String];
}

-(BOOL)flagState:(u_int64_t)flag{
    //valid flags are 2^0 - 2^63
    //not checked here...
    return (_flagMask & flag) != 0;
}
-(void)setFlagState:(u_int64_t)flag value:(BOOL)value{
    //sets a flag bit
    if (value) {
        _flagMask = _flagMask | flag;
    } else {
        _flagMask = _flagMask & ~flag;
    }
}

-(void)resetFlagState:(u_int64_t)flagMask{
    _flagMask = flagMask;
}

-(u_int64_t)flagMask{
    return _flagMask;
}

-(void)postCopySetup:(id)aCopy{
    [aCopy setMasterObject:self];   
}

-(id)copyWithZone:(NSZone*)zone includeNewProperties:(NSDictionary*)includeNewProperties{
	//alternate copy method allowing an array of property keys to be 
	//duplicated from master to copy
    id aCopy = [[[self class] allocWithZone:zone] initCopyWithDictionary:includeNewProperties];
    [self postCopySetup:aCopy];
	return aCopy;
}

-(id)copyWithZone:(NSZone*)zone{
	//all copied sfobjects have a copyinfo part in their objectinfo,
	//allowing propagation of cloned attributes if required
	return [self copyWithZone:zone includeNewProperties:nil];
}

#if SF_DEBUG
-(NSString*)description{
    //if we are debugging, override the default description with something more useful
    NSString *debugDesc = [NSString stringWithFormat:@"<%s:%s:0x%x>", _internalName, [[[self class] description] UTF8String], self];
    return debugDesc;
}
#endif

#if DEBUG_RETAIN_RELEASE
-(id)retain{
    [self reportRetain];
    return [super retain];
}

-(void)release{
    [self reportRelease];
    [super release];
}

#endif

@end
