//
//  SFWidgetVideo.h
//  ZombieArcade
//
//  Created by Adam Iredale on 30/12/09.
//  Copyright 2009 Stormforge Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SFWidget.h"
#import "SFVideo.h"

@interface SFWidgetVideo : SFWidget {
	//a full-screen widget that plays video files
	//and corresponding audio files
	//given the fore name of the video
	SFVideo *_video;
	id _sound;
	SFImage *_frame;
    id _opVideoBuffer;
    BOOL _videoFinished;
}

-(id)initWithVideoName:(NSString*)videoName 
        callbackObject:(id)callbackObject 
      callbackSelector:(SEL)callbackSelector
              useSound:(BOOL)useSound
            dictionary:(NSDictionary*)dictionary;

-(BOOL)isFinished;

@end
