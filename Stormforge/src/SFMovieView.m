//
//  SFMovieView.m
//  ZombieArcade
//
//  Created by Adam Iredale on 18/03/10.
//  Copyright 2010 Stormforge Software. All rights reserved.
//

#import "SFMovieView.h"
#import "SFUtils.h"
#import "SFGameEngine.h"
#import "SFOSVersion.h"

@implementation SFMovieView

-(void)rotateView90:(UIView*)aView{
    CGAffineTransform transform = self.transform;
    
    // Rotate the view 90 degrees. 
    transform = CGAffineTransformRotate(transform, (M_PI / 2.0));
    
    UIScreen *screen = [UIScreen mainScreen];
    // Translate the view to the center of the screen
    transform = CGAffineTransformTranslate(transform, 
                                           ((screen.bounds.size.height) - (aView.bounds.size.height))/2, 
                                           0);
    aView.transform = transform;
    
    CGRect newFrame = aView.frame;
    newFrame.origin.x = 190;
    aView.frame = newFrame;
}

-(id)currentMovieInfo:(NSString*)infoKey{
    return [[_movieList objectAtIndex:_movieIndex] objectForKey:infoKey];
}

-(NSURL*)currentMovieURL{
    
    return [NSURL fileURLWithPath:[SFUtils getFilePathFromBundle:[self currentMovieInfo:@"filename"]]];
}

-(void)delayAttachToScreen{
    [self attachToScreen:YES];
    _startTime = [SFUtils getAppTime];
}

-(void)attachToScreen:(BOOL)attach{
    if (attach) {
        [[SFUtils appKeyWindow] addSubview:self];
        [[SFUtils appKeyWindow] bringSubviewToFront:self];
    } else {
        [self removeFromSuperview];
    }
    
}

-(void)movieFinished:(id)notify{
    [[NSNotificationCenter defaultCenter] removeObserver:self 
                                                    name:MPMoviePlayerPlaybackDidFinishNotification 
                                                  object:_mpc]; 
    [self removeFromSuperview];
    //now, this has changed in iOS3.2 so we need to support two different styles of movie player
    if (_mpcIsSubview) {
        [[_mpvc view] removeFromSuperview];
        [_mpvc release];
        _mpvc = nil;
    } else {
        [_mpc release];
    }
    _mpc = nil;
    
    ++_movieIndex;
    if (_movieIndex < [_movieList count]) {
        [self performSelectorOnMainThread:@selector(playNextMovie)
                               withObject:nil
                            waitUntilDone:NO];
    } else {
        [self notifyMoviesFinished];
    }
    
}

-(void)playNextMovie{
    if ([SFOSVersion featureSupported:osfMoviePlayerControllerView]){
        //if the "view" option is supported then we have to attach it to see it
        _mpvc = [[MPMoviePlayerViewController alloc] initWithContentURL:[self currentMovieURL]];
        _mpc = _mpvc.moviePlayer;
        //_mpc = [[MPMoviePlayerController alloc] initWithContentURL:[self currentMovieURL]];
        _mpc.controlStyle = MPMovieControlStyleNone;
        _mpc.fullscreen = YES;
        [self rotateView90:[_mpc view]];
        [[[SFGameEngine mainViewController] view] insertSubview:[_mpvc view] belowSubview:self];
        //[[[SFGameEngine mainViewController] view] bringSubviewToFront:self];
        //[self presentMoviePlayerViewControllerAnimated:mpvc];
       // [[SFUtils appKeyWindow] bringSubviewToFront:[_mpc view]];
       // [self delayAttachToScreen];
        _startTime = [SFUtils getAppTime];
        _mpcIsSubview = YES;
    } else {
        //this will run in full screen regardless
        //depending on the movie index, play the corresponding movie
        //we are using a string literal here because I don't want the deprecated warning
        //I know that it's deprecated - I am building for 3.1 compatibility
        _mpc = [[MPMoviePlayerController alloc] initWithContentURL:[self currentMovieURL]];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(delayAttachToScreen) 
                                                     name:@"MPMoviePlayerContentPreloadDidFinishNotification"
                                                   object:_mpc];
        _mpc.movieControlMode = MPMovieControlModeHidden;
    }

    _mpc.scalingMode = MPMovieScalingModeAspectFill;  //fill the screen
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(movieFinished:) 
                                                 name:MPMoviePlayerPlaybackDidFinishNotification 
                                               object:_mpc];
    [_mpc play];
}

-(void)notifyMoviesFinished{
    if (!_notifiedFinished) {
        _notifiedFinished = YES;
        [[NSNotificationCenter defaultCenter] postNotificationName:SF_NOTIFY_MOVIES_FINISHED
                                                            object:self];
    }
}

+(CGRect)initialFrame{
    return CGRectMake(0, 0, 480, 320);
}

-(id)initWithMovieList:(NSArray*)movieList{
    self = [self initWithFrame:[[self class] initialFrame]];
    if (self != nil) {
        //[self rotateSelfToMatchMovie];
        //in this case of array init, the array holds information as follows:
        //order of play -> movie options (NSDictionary)
        //useful options at the moment are:
        //touchAvailableAfter (NSNumber*) milliseconds after which the user can touch to exit the movie
        //movieName (NSString*)
        _movieList = [movieList retain];
    }
    return self;
}

- (void)dealloc {
    [_movieList release];
    [super dealloc];
}

-(void)stopCurrentMovieAndFinish{
    id movieController = [_mpc retain];
    if (movieController) {
        [movieController stop];
        [movieController release];
    }
    [self notifyMoviesFinished];
}

// Handle any touches to the overlay view
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch* touch = [touches anyObject];
    if (touch.phase == UITouchPhaseBegan){
        //we've been touched... if this movie (current) allows
        //exit on touch then we stop the movie and terminate
        //our playlist
        id touchAfter = [self currentMovieInfo:@"touchAvailableAfter"];
        if ((touchAfter) and ([SFUtils getAppTimeDiff:_startTime] > [touchAfter integerValue])) {
            [self stopCurrentMovieAndFinish];
        }
    }    
}

+(id)viewWithMovieList:(NSArray*)movieList{
    return [[[self alloc] initWithMovieList:movieList] autorelease];
}

@end
