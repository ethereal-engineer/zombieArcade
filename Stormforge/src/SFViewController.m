    //
//  SFViewController.m
//  ZombieArcade
//
//  Created by Adam Iredale on 23/06/10.
//  Copyright 2010 Stormforge Software. All rights reserved.
//

#import "SFViewController.h"
#import "SFGL.h"
#import "SFUtils.h"
#import "SFDebug.h"
#import "SFGameEngine.h"

@implementation SFViewController

@synthesize glView;
@synthesize movieView;

/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        // Custom initialization
    }
    return self;
}
*/

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
}
*/


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
    SFGL::startUp();
    [glView destroyFramebuffer];
    [glView createFramebuffer];
    _loc = new SFVec(3);
    _scl = new SFVec(3);
    _curr_time = [SFUtils getAppTime];
    _accel_smooth = 0.9f;
    [self updateViewPort];
}



// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return UIInterfaceOrientationIsLandscape(interfaceOrientation);
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (void)dealloc {
    delete _loc;
    delete _scl;
    [super dealloc];
}

- (IBAction)startGLAnimation{
    //start gl drawing!
    if (glView) {
        [glView startAnimation];
    }
}

- (IBAction)stopGLAnimation{
    //for some reason we need to stop drawing gl - GREE etc
    if (glView) {
        [glView stopAnimation];
    }
}

-(SFVec*)loc{
    return _loc;
}

-(SFVec*)scl{
    return _scl;
}

-(float)deltaTime{
    return _d_time;
}

-(void)doSwapBuffersAccounting{
    _currTime = [SFUtils getAppTime];	
    
    if( _lastSync )
    {
        if (_sync_time >= 1.0f )
        {
            _sync_time = 0.0f;
            _fps = _fra;
            _fra = 0.0f;
        }
        
        _d_time = SF_CLAMP( ( _currTime - _lastSync ) * 0.001f, 0.0f, 1.0f );
        _sync_time += _d_time;
        
        ++_fra;
    }
    
    _lastSync = _currTime;
}

-(void)getViewPortMatrix{
    //PERF ISSUE:
    //this should be called infrequently as it may cause the 
    //gl hardware to lockstep with the cpu
    [SFUtils assertGlContext];
    glGetIntegerv( GL_VIEWPORT, (GLint*)&_matViewport);
}

-(void)updateViewPort{
    [SFUtils assertGlContext];
    glViewport(0, 0, [glView backingWidth], [glView backingHeight]);
    
    [self getViewPortMatrix];
    
    sfDebug(TRUE, "Viewport Matrix Recalculated:");
    [SFUtils debugIntMatrix:_matViewport width:4 height:1];
    
    _loc->setVec2(Vec2Make(0,0));
    
    _scl->setX((float)( _matViewport[2] - _matViewport[0]));
    _scl->setY((float)( _matViewport[3] - _matViewport[1]));
}

-(u_int64_t)currentTime{
    return _currTime;
}

-(u_int64_t)lastSyncTime{
    return _lastSync;
}

-(GLint*)matViewPort{
    return (GLint*)&_matViewport;
}

-(void)moviesFinished:(id)notification{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:SF_NOTIFY_MOVIES_FINISHED
                                                  object:movieView];
    //now ditch the movie view
    [movieView removeFromSuperview];
    [movieView release];
    movieView = nil;
    //and continue animation on the gl view
    [self startGLAnimation];
    //let anyone who is interested know that the movies are over
    [[NSNotificationCenter defaultCenter] postNotificationName:SF_NOTIFY_VIEW_CONTROLLER_EVENT
                                                        object:self];
}

-(void)playMovieList:(NSArray*)movieList{
    //play the list of movies given using the movie view
    //first stop the animation of the gl view and then switch to movie
    //view - once done, return to animating the gl view
    [self stopGLAnimation];
    movieView = [[SFMovieView alloc] initWithMovieList:movieList];
    [[[SFGameEngine mainViewController] view] insertSubview:movieView aboveSubview:glView];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(moviesFinished:)
                                                 name:SF_NOTIFY_MOVIES_FINISHED
                                               object:movieView];
    [movieView playNextMovie];
}

@end
