//
//  SFMovieView.h
//  ZombieArcade
//
//  Created by Adam Iredale on 18/03/10.
//  Copyright 2010 Stormforge Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SFDefines.h"
#import <MediaPlayer/MediaPlayer.h>

#define SF_NOTIFY_MOVIES_FINISHED @"SFNotifyMoviesFinished"

@interface SFMovieView : UIView {
    //for playing movies in full screen 
    //with the ability to handle touch
    //and show overlays
    NSArray *_movieList;
    int _movieIndex;
    MPMoviePlayerController *_mpc;
    MPMoviePlayerViewController *_mpvc; //only used in iOS3.2 and above
    BOOL _notifiedFinished;
    u_int64_t _startTime;
    BOOL _mpcIsSubview;
}

+(id)viewWithMovieList:(NSArray*)movieList;
+(CGRect)initialFrame;
-(void)playNextMovie;
-(id)initWithMovieList:(NSArray*)movieList;
-(void)attachToScreen:(BOOL)attach;
-(void)notifyMoviesFinished;

@end
