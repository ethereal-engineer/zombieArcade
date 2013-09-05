//
//  SFColdObject.h
//  ZombieArcade
//
//  Created by Adam Iredale on 28/01/10.
//  Copyright 2010 Stormforge Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SFObject.h"
#import "SFOperation.h"
#import "SFGL.h"

#define DEBUG_SFGAMEOBJECT 0

@interface SFGameObject : SFObject <PPrecachable, SFIpoDelegate> {
	//its an object - but specifically oriented towards the
    //game environment - it has access to all game globals/singletons
    //and other useful game features
    
    //precaching/easy access to local via "my"
    NSMutableDictionary *_sounds;
    NSMutableDictionary *_images;
    NSMutableDictionary *_objects;
    
    id _scene; //if this game object is affiliated with a scene, this will be non-nil
    id _logicClassName; //if this game object needs to be controlled, this will be non-nil
}
-(void)prepareObject;
-(void)prepareObjectExtension; //<-- allows category overrides
-(void)setLogicClassName:(NSString*)logicClassName;
-(void)precacheSounds:(NSMutableArray *)sounds;
-(void)precacheImages:(NSMutableArray *)images;
-(void)precacheObjects:(NSMutableArray *)objects;
-(id)logicClassName;
-(void)registerForNotifications;
-(void)stopNotifyObject:(NSString*)name object:(id)object;
-(void)notifyMe:(NSString*)name selector:(SEL)sel object:(id)obj;
-(void)notifyMe:(NSString*)name selector:(SEL)sel;
-(void)postGeneralNote:(NSString*)name userInfo:(NSDictionary*)userInfo;
-(void)stopNotify:(NSString*)name;
-(void)setScene:(id)scene;
-(id)scene;
-(void)soundPrecachingComplete;
-(void)queueObjectNote:(NSString*)name userInfo:(NSDictionary*)userInfo;
-(id)unlockableObjectId;

-(void)doPrecaching;
-(void)runPrecacheSounds;
-(void)runPrecacheImages;
-(void)runPrecacheObjects;
-(void)allPrecachingComplete;
-(void)imagePrecachingComplete;
-(void)objectPrecachingComplete;
-(void)resetObject;

//access to singletons
-(id<PGameInfo>)gi;
+(id<PGameInfo>)gi;
-(id<PScoreManager>)scom;
+(id<PScoreManager>)scom;
-(id<PSceneManager>)sm;
+(id<PSceneManager>)sm;
-(id)glm;
+(id)glm;
-(id<PResourceManager>)rm;
+(id<PResourceManager>)rm;
-(id<PAtlasManager>)atlm;
+(id<PAtlasManager>)atlm;

@end
