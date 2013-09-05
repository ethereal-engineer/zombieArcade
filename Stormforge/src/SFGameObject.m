//
//  SFGameObject.m
//  ZombieArcade
//
//  Created by Adam Iredale on 28/01/10.
//  Copyright 2010 Stormforge Software. All rights reserved.
//

#import "SFGameObject.h"
#import "SFUtils.h"
#import "SFGameEngine.h"
#import "SFResourceManager.h"
#import "SFGameInfo.h"
#import "SFSceneManager.h"
#import "SFGLManager.h"
#import "SFSound.h"
#import "SFAtlasManager.h"

@implementation SFGameObject

-(id)logicClassName{
    return _logicClassName;
}

-(void)setLogicClassName:(NSString*)logicClassName{
    _logicClassName = [logicClassName retain];
}

-(void)sendNote:(NSString*)name specifyObject:(id)obj useQueue:(BOOL)useQueue userInfo:(NSDictionary*)userInfo{
    id specificObject = nil;
    if (obj) {
        specificObject = obj;
    }
    NSNotification *note = [NSNotification notificationWithName:name
                                                                   object:specificObject
                                                                 userInfo:userInfo];
    [[NSNotificationCenter defaultCenter] postNotification:note];
}

-(void)queueObjectNote:(NSString*)name userInfo:(NSDictionary*)userInfo{
    [self sendNote:name
       specifyObject:self
          useQueue:YES
          userInfo:userInfo];
}

-(void)queueGeneralNote:(NSString*)name userInfo:(NSDictionary*)userInfo{
    [self sendNote:name
       specifyObject:nil
          useQueue:YES
          userInfo:userInfo];
}

-(void)postOtherObjectNote:(id)otherObject name:(NSString*)name userInfo:(NSDictionary*)userInfo{
    [self sendNote:name
     specifyObject:otherObject
          useQueue:NO
          userInfo:userInfo];
}

-(void)postObjectNote:(NSString*)name userInfo:(NSDictionary*)userInfo{
    [self postOtherObjectNote:self name:name userInfo:userInfo];
}

-(void)postGeneralNote:(NSString*)name userInfo:(NSDictionary*)userInfo{
    [self sendNote:name
       specifyObject:nil
          useQueue:NO
          userInfo:userInfo];
}

-(void)stopNotifyObject:(NSString*)name object:(id)object{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:name
                                                  object:object];
}

-(void)stopNotify:(NSString*)name{
    [self stopNotifyObject:name object:nil];
}

-(void)notifyMe:(NSString*)name selector:(SEL)sel object:(id)obj{
    _stopNotifyOnClean = YES;
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:sel
                                                 name:name
                                               object:obj];
}

-(void)notifyMe:(NSString*)name selector:(SEL)sel{
    [self notifyMe:name selector:sel object:nil];    
}

-(void)registerForNotifications{
    //to register for a notification or a few (in bulk),
    //call any of the registration functions here
    //there are "notifyMe" shortcut functions for that
    //purpose

    //if we are unlockable, register for our unlock notification
    id unlockId = [self unlockableObjectId];
    if (!unlockId) {
        return;
    }
    [self notifyMe:SF_NOTIFY_ACHIEVEMENT_UNLOCKED
          selector:@selector(objectBecameUnlocked:) object:unlockId];
}

-(id)initWithDictionary:(NSDictionary *)dictionary{
	self = [super initWithDictionary:dictionary];
	if (self != nil) {
        //the standard cleanup feature will
        //unregister any of these
        [self registerForNotifications];
	}
	return self;
}

-(void)precache{
    //chain-linkable - this conforms to the
    //PPrecachable protocol
    [self doPrecaching];
}

-(void)preparePrecaching{
    //create the precache/resource dictionaries
    //to make local access quick and easy
    _images = [[NSMutableDictionary alloc] init];
    _sounds = [[NSMutableDictionary alloc] init];
    _objects = [[NSMutableDictionary alloc] init];
}

-(id)unlockableObjectId{
    //returns the object's unlockable item id
    //by default, this is the unique id
    return [self objectInfoForKey:@"uniqueId"];
}

-(void)cleanUp{
    if (_scene) {
        [_scene release];
        _scene = nil;
    }
    [_logicClassName release];
    [super cleanUp];
}

-(void)doPrecaching{
    //we start all precaching from here
    [self preparePrecaching];
    [self runPrecacheSounds];
    [self runPrecacheImages];
    [self runPrecacheObjects];
    [self allPrecachingComplete];
}

-(void)allPrecachingComplete{
    //all precaching is complete, clean up
    [_images release];
    [_sounds release];
    [_objects release];
}

-(void)runPrecacheImages{
    //we create a mutable array and it will come back
    //full of image names for us to setup
    id imageArray = [[NSMutableArray alloc] init];
    [self precacheImages:imageArray];
    for (id image in imageArray) {
#if DEBUG_SFGAMEOBJECT
        sfDebug(TRUE, "Precaching %s...", [[image description] UTF8String]);
#endif
        //fetch the image from the res
        id newImage = [[self rm] getItem:image
                 itemClass:[SFImage class]
                     tryLoad:YES];
        //if it's ok, add it to the images dictionary
        if (newImage) {
            [newImage prepare];
            [_images setObject:newImage forKey:image];
#if DEBUG_SFGAMEOBJECT
            sfDebug(TRUE, "%s added to image dictionary", [[image description] UTF8String]);
#endif
        }
    }
    [imageArray release];
    [self imagePrecachingComplete];
}

-(void)precacheImages:(NSMutableArray*)images{
    //add image names (filenames) to load
}

-(void)imagePrecachingComplete{
    //images are precached
}

-(void)runPrecacheObjects{
    //we create a mutable array and it will come back
    //full of objects for us to setup
    id objectArray = [[NSMutableArray alloc] init];
    [self precacheObjects:objectArray];
    for (id object in objectArray) {
#if DEBUG_SFGAMEOBJECT
        sfDebug(TRUE, "Precaching %s...", [[object description] UTF8String]);
#endif
        //simple - run "precache" on all these objects
        [object precache];
        //add it to the objects dictionary
        [_objects setObject:object forKey:[object name]];
#if DEBUG_SFGAMEOBJECT
        sfDebug(TRUE, "%s added to object dictionary", [[object description] UTF8String]);
#endif
    }
    [objectArray release];
    [self objectPrecachingComplete];
}

-(void)objectPrecachingComplete{
    //when this happens, object precaching is done
}

-(void)precacheObjects:(NSMutableArray*)objects{
    //have anything you want precached at startup?
    //add it to the array!
}

-(void)runPrecacheSounds{
    //we create a mutable array and it will come back
    //full of sound names for us to setup
    id soundArray = [[NSMutableArray alloc] init];
    [self precacheSounds:soundArray];
    for (id sound in soundArray) {
#if DEBUG_SFGAMEOBJECT
        sfDebug(TRUE, "Precaching %s...", [[sound description] UTF8String]);
#endif
        //load the sound into memory by fetching it from
        //our resource manager
        id newSound = [SFSound quickPlayFetch:sound];
        //if it's ok, add it to the sound dictionary
        if (newSound) {
            [_sounds setObject:newSound forKey:sound];
#if DEBUG_SFGAMEOBJECT
            sfDebug(TRUE, "%s added to sound dictionary", [[sound description] UTF8String]);
#endif   
        }     
    }
    [soundArray release];
    [self soundPrecachingComplete];
}

-(void)soundPrecachingComplete{
    //sound precaching is done - override this method to
    //launch whatever happens next
}

-(void)precacheSounds:(NSMutableArray*)precacheMe{
    //what it says - put all sound names that need to be precached in this
    //array
}

-(void)postCopySetup:(id)aCopy{
    [super postCopySetup:aCopy];
    [aCopy setScene:_scene];
}

-(void)prepareObjectExtension{
    //don't override this - used for category extension
}

-(void)resetObjectExtension{
    //don't override this - used for category extension
}

-(void)prepareObject{
    //called to reset an object's state so it can be re-used
    [self prepareObjectExtension];
}

-(void)ipoStopped:(id)ipo{
    //what we do when an ipo stops...
}

-(void)resetObject{
    [self resetObjectExtension];
}

-(id<PGameInfo>)gi{
    return [[self class] gi];
}

+(id<PGameInfo>)gi{
    return (id)[SFGameInfo alloc];
}

-(id<PScoreManager>)scom{
    return [[self class] scom];
}

+(id<PScoreManager>)scom{
    return [SFScoreManager alloc];
}

-(id<PSceneManager>)sm{
    return [[self class] sm];
}

+(id<PSceneManager>)sm{
    return [SFSceneManager alloc];
}

-(id<PResourceManager>)rm{
    return [[self class] rm];
}

+(id<PResourceManager>)rm{
    return (id)[SFResourceManager alloc];
}

+(id)glm{
    return [SFGLManager alloc];
}

-(id)glm{
    return [[self class] glm];
}

-(id<PAtlasManager>)atlm{
    return [SFAtlasManager alloc];
}

+(id<PAtlasManager>)atlm{
    return [[self class] atlm];
}

-(id)scene{
    [SFUtils assert:(_scene != nil) failText:@"nil scene!"];
    return _scene;
}

-(void)setScene:(id)scene{
    if (_scene) {
        [_scene release];
    }
    _scene = [scene retain];
}

@end
