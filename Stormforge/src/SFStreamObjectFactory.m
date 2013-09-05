//
//  SFStreamObjectFactory.m
//  ZombieArcade
//
//  Created by Adam Iredale on 4/03/10.
//  Copyright 2010 Stormforge Software. All rights reserved.
//

#import "SFStreamObjectFactory.h"
#import "SFUtils.h"
#import "SFTokens.h"
#import "SFDebug.h"
#import "SFLoadableGameObject.h"

#define DEBUG_ALL_TOKENS 0

@implementation SFStreamObjectFactory

static const NSDictionary *SF_SF_MAP = [[NSDictionary alloc] initWithObjectsAndKeys:@"SF3DObject", @"object",
                                             @"SFMaterial", @"material", 
                                             @"SFLamp", @"lamp", 
                                             @"SFCamera", @"camera",
                                             @"SFImage", @"image",
                                             @"SFIpo", @"ipo", 
                                             @"SFAction", @"action",
                                             @"SFVideo", @"video", 
                                             @"SFSound", @"sound", nil];
static const NSDictionary *SF_EXT_MAP = [[NSDictionary alloc] initWithObjectsAndKeys:@"SFImage", @"tga",
                                         @"SFVideo", @"ogv", 
                                         @"SFSound", @"ogg", nil];

+(NSMutableDictionary*)SFStreamToTokenDictionary:(SFStream*)stream{
    
    NSMutableDictionary *tokens = [[[NSMutableDictionary alloc] init] autorelease];
    NSMutableArray *manyTokens = [[NSMutableArray alloc] init];
    [tokens setObject:manyTokens forKey:@"tokens"];
    [manyTokens release];
	
    char singleChar;
    BOOL readingToken = NO;
    
    char tokenRoot[SF_MAX_CHAR];
    char tokenName[SF_MAX_CHAR];
    char tokenValue[SF_MAX_CHAR];
    unsigned int tokenRootPos = 0;
    unsigned int tokenNamePos = 0;
    unsigned int tokenValuePos = 0;
    
    //stream will already be in an open state
    
    BOOL continueToRead;
    size_t readBytes;
    
    while (stream->bytesRemaining() > 0) {
        if (stream->read((unsigned char*)&singleChar, sizeof(char)) > 0){
            switch (singleChar) {
                case 13: //cr
                case 10: //lf
                case '\t':  //tab
                case ' ': //space
                    continue; //move on
                    break;
                case '(': //left bracket
                    
                    //close and reset our token name string
                    tokenName[tokenNamePos] = 0;
                    tokenNamePos = 0;
                    
                    //read everything until we hit a right bracket
                    continueToRead = YES;
                    readBytes = 0;
                    while (continueToRead) {
                        readBytes = stream->read((unsigned char*)&singleChar, sizeof(char));
                        if (!readBytes) {
                            sfThrow("Unexpected end of stream!!!");
                        }
                        switch (singleChar) {
                            case ')': 
                                continueToRead = NO;
                                break;
                            case '\t': 
                            case ' ': 
                                //skip leading space/tabs
                                if (tokenValuePos == 0) {
                                    continue;
                                }
                                break;
                            case '"':
                                //skip ALL quotes
                                continue;
                                break;
                            default:
                                break;
                        }
                        if (!continueToRead) {
                            break;
                        }
                        tokenValue[tokenValuePos] = singleChar;
                        ++tokenValuePos;
                    };             
                    
                    //the value is finished - close and reset it
                    tokenValue[tokenValuePos] = 0;
                    tokenValuePos = 0;
                    
                    //if we've never set the root before, set it now
                    if (!readingToken) {
                        //close and reset our root string
                        tokenRoot[tokenRootPos] = 0;
                        tokenRootPos = 0;
                        [tokens setObject:[NSString stringWithUTF8String:tokenRoot] forKey:@"root"];
                    }
                    
                    //tidy any trailing garbage
                    //then add a token to the array
                    
                    [manyTokens addObject:[NSArray arrayWithObjects:[NSString stringWithUTF8String:tokenName],
                                                                     [[NSString stringWithUTF8String:tokenValue] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]], 
                                                                     nil]];
                                        
                    break;
                
                case '{': //open curly bracket
                    readingToken = YES;
                    break;
                case '}': //close curly bracket
                    readingToken = NO;
                    break;
                default:
                    //everything else - read it into either the root 
                    //or name depending on what we are reading at the moment
                    if (readingToken) {
                        tokenName[tokenNamePos] = singleChar;
                        ++tokenNamePos;
                    } else {
                        tokenRoot[tokenRootPos] = singleChar;
                        ++tokenRootPos;
                    }
                    break;
            }
        }
    }
    return tokens;
}

+(id)newObjectFromStream:(SFStream*)stream dictionary:(NSDictionary*)dictionary{
    return [self newObjectFromStream:stream dictionary:dictionary classOverride:nil];
}

+(id)newObjectFromStream:(SFStream*)stream dictionary:(NSDictionary*)dictionary classOverride:(Class)classOverride{
    //this routine identifies the stream and what we need to do with it
    //then creates and returns the right object

    //first we need to id the stream - get the fname to pass on
    NSString *fileName = [NSString stringWithUTF8String:stream->fileName()];

    //check if it's a data file by extension
    NSString *className = [SF_EXT_MAP objectForKey:[fileName pathExtension]];
    
    id newObject = nil;
    
    Class newClass = classOverride;
    
    if (className) {
        //this IS a simple stream format - not a parsable text stream
        //init via the stream only
        if (!newClass) {
            newClass = [SFUtils getNamedClassFromBundle:className];
        }
        newObject = [(SFLoadableGameObject*)[newClass alloc] initWithSFStream:stream dictionary:dictionary];
        //the class will either keep or terminate the stream
    } else {
        //it's a file without extension or other text file - we need to run
        //a parse on it
        SFTokens *tokens = new SFTokens();
        tokens->parseStream(stream);
        //and we don't need the stream no more
        delete stream;
#if DEBUG_ALL_TOKENS
        tokens->print();
#endif
        if (!newClass) {
            //the class name will be revealed by mapping the "root" key
            className = [SF_SF_MAP objectForKey:[NSString stringWithUTF8String:tokens->rootName()]];
            newClass = [SFUtils getNamedClassFromBundle:className];
        }
        //now we create and return the object
        newObject = [(SFLoadableGameObject*)[newClass alloc] initWithTokens:tokens dictionary:dictionary];
        delete tokens;
    }
    
    //failsafe
    if (!newObject) {
        sfThrow("Unable to create SF object of class %s from stream", [className UTF8String]);
    }
    
    sfDebug(DEBUG_SFSTREAMOBJECTFACTORY, "SOF: New %s: %s", [[newClass description] UTF8String], [newObject UTF8Description]);
    
    return newObject;
}

@end
