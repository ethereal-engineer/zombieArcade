//
//  SFVideoScreen.m
//  ZombieArcade
//
//  Created by Adam Iredale on 5/02/10.
//  Copyright 2010 Stormforge Software. All rights reserved.
//

#import "SFVideoScreen.h"
#import "SFWidgetVideo.h"
#import "SFUtils.h"
#import "SFDebug.h"

@implementation SFVideoScreen

-(void)videoCallback:(SFWidgetVideo*)widget{
    if ([widget callbackReasonIs:CR_DONE]) {
        sfDebug(TRUE, "Video done playing.");
    }
}

-(BOOL)isFinished{
    //return true if the video is over
    return [(SFWidgetVideo*)_internalWidget isFinished];
}

-(void)firstRenderSetup{
    [super firstRenderSetup];
    [_internalWidget play];
}

-(void)setupWidget:(SFWidget **)widget{
    [super setupWidget:widget];
    *widget = [[SFWidgetVideo alloc] initWithVideoName:[self objectInfoForKey:@"videoName"]
                                       callbackObject:self
                                     callbackSelector:@selector(videoCallback:)
                                             useSound:[[self objectInfoForKey:@"useSound"] boolValue]
                                           dictionary:nil];
}

-(id)initWithVideoName:(NSString*)videoName useSound:(BOOL)useSound dictionary:(NSDictionary*)dictionary{
    NSMutableDictionary *addDictionary = [[NSMutableDictionary alloc] init];
    if (dictionary) {
        [addDictionary addEntriesFromDictionary:dictionary];
    }
    [addDictionary setObject:[NSNumber numberWithBool:useSound] forKey:@"useSound"];
    [addDictionary setObject:videoName forKey:@"videoName"];
    self = [self initWithDictionary:addDictionary];
    [addDictionary release];
    return self;
}

@end
