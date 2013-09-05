//
//  SFLoadableGameObject.m
//  ZombieArcade
//
//  Created by Adam Iredale on 4/03/10.
//  Copyright 2010 Stormforge Software. All rights reserved.
//

#import "SFLoadableGameObject.h"
#import "SFUtils.h"

#define DEBUG_TOKENS 0
#define DISPLAY_LOAD_SUMMARY 0

@implementation SFLoadableGameObject

-(BOOL)loadInfo:(SFTokens*)tokens{
    //children
    return NO;
}

-(BOOL)doLoadInfo:(SFTokens*)tokens{

#if DEBUG_TOKENS
    sfDebug(TRUE, "Loading Token: %s Value: %s", tokens->tokenName(), tokens->valueAsString());
#endif
    
    if (tokens->tokenIsNull()) {
        //null token string sets the name
        [self setUTF8Name:tokens->valueAsString()];
        return YES;
    }
    
    if (tokens->tokenIs("fl")) {
        //common flags
        u_int64_t flags = round(tokens->valueAsFloats(1)[0]);
        [self resetFlagState:flags];
        return YES;
    }
    
    return [self loadInfo:tokens];
}

-(id)getParseInfo{
    return [self objectInfoForKey:@"parseInfo"];
}

-(void)bindIpo{
    //if we have an ipo allocated to us from blender, get it and
    //link it up now (unused)
}

-(void)loadFromTokens:(SFTokens*)tokens{
    if (!tokens) {
        return;
    }
    tokens->reset(); //start at the start
    while (tokens->nextToken()) {
        [self doLoadInfo:tokens]; 
    }
}

+(NSString*)fileName:(NSString*)name{
    return [self fileName:name offset:-1];
}

+(NSString*)fileName:(NSString*)name offset:(int)offset{
    //returns the full file path for this object's file,
    //and if a positive or zero offset is added,
    //it also will generate the full file name with 
    //numbered offsets e.g. targa1.tga targa2.tga etc
    
    //strip out any directory info and any extension
    
    NSString *returnString = [name lastPathComponent];
    if ([self fileExtension]) {
        returnString = [returnString stringByDeletingPathExtension];
    }
    
    //prepend the directory info
    returnString = [[[self class] fileDirectory] stringByAppendingPathComponent:returnString];
    
    //if we have offset data, add that on
    if (offset >= 0) {
        returnString = [returnString stringByAppendingFormat:@"%d", offset];
    }
    
    //finally, add the extension and we're good to go
    //if there is one, that is
    if ([self fileExtension]) {
        returnString = [returnString stringByAppendingPathExtension:[self fileExtension]];
    }
    
    return returnString;
}

+(NSString*)fileDirectory{
    //override this for class file directories
    return @"";
}

+(NSString*)fileExtension{
    //override this for class file extensions
    return nil;
}

-(BOOL)preLoadSetup{
    //called before load to allow children to init datastructures that will be filled
    return YES;
}

-(void)resolveDependantItems:(id)useResource{
    //when an item is loaded on-demand, this is used to load all dependant items like materials
}

-(id)initWithTokens:(SFTokens *)tokens dictionary:(NSDictionary *)dictionary{
    self = [self initWithDictionary:dictionary];
    if (self != nil) {
        [self loadFromTokens:tokens];
    }
    return self;
}

-(id)initWithSFStream:(SFStream *)stream dictionary:(NSDictionary *)dictionary{
    self = [super initWithDictionary:dictionary];
    if (self != nil) {
        [self setUTF8Name:stream->fileName()];
        _stream = stream;
    }
    return self;
}

-(void)cleanUp{
    if (_stream) {
        delete _stream;
        _stream = NULL; 
    }
    [super cleanUp];
}

-(id)initCopyWithDictionary:(NSDictionary *)dictionary{
    self = [super initCopyWithDictionary:dictionary];
    if (self != nil) {
        _preloadSetupOk = [self preLoadSetup];
    }
    return self;
}

@end
