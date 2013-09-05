//
//  SFOggFile.h
//  ZombieArcade
//
//  Created by Adam Iredale on 24/02/10.
//  Copyright 2010 Stormforge Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SFLoadableGameObject.h"
#import "SFStream.h"
#import "SFOggStream.h"

@interface SFOggFile : SFLoadableGameObject {
    //an ogg file contains 1+ streams
    //and each stream has 1+ pages
    //but they are not stored 
    //neccesarily in straight order
    //this class loads them and
    //irons them out
    
    //our ogg streams, organised by
    //page serial number
    NSMutableDictionary *_oggStreams;
    
    //our data stream (like a file or memory stream)
    SFStream *_inStream;
    
    //our sync state for all the data to do with this
    //"file"
    ogg_sync_state _syncState;
}

-(BOOL)streamRequiresMorePagesForHeader:(id)stream;
-(void)setupDecoders;
-(void)oggStreamsFromStream;

@end
