//
//  SFLoadableGameObject.h
//  ZombieArcade
//
//  Created by Adam Iredale on 4/03/10.
//  Copyright 2010 Stormforge Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SFGameObject.h"
#import "SFTokens.h"
#import "SFStream.h"

@interface SFLoadableGameObject : SFGameObject {
    BOOL _preloadSetupOk;
    SFStream *_stream;
}

-(id)initWithTokens:(SFTokens*)tokens dictionary:(NSDictionary*)dictionary;
-(id)initWithSFStream:(SFStream *)stream dictionary:(NSDictionary *)dictionary;

-(void)resolveDependantItems:(id)useResource;
-(BOOL)preLoadSetup;
-(BOOL)loadInfo:(SFTokens*)tokens;
-(void)bindIpo;

+(NSString*)fileName:(NSString*)name offset:(int)offset;
+(NSString*)fileName:(NSString*)name;

//return the class file extension
+(NSString*)fileExtension;
+(NSString*)fileDirectory;

@end
