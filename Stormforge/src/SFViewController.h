//
//  SFEAGLViewController.h
//  ZombieArcade
//
//  Created by Adam Iredale on 23/06/10.
//  Copyright 2010 Stormforge Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SFMovieView.h"
#import "EAGLView.h"
#import "SFVec.h"

#define SF_NOTIFY_VIEW_CONTROLLER_EVENT @"SFNotifyViewControllerEvent"

@interface SFViewController : UIViewController {
    EAGLView *glView;
    SFMovieView *movieView;
    SFVec					*_loc;
	SFVec                   *_scl;
	
	SFVec                    *_accel;
	float						_accel_smooth;
	
	GLint						_matViewport[4];
    
	unsigned int				_curr_time;
	unsigned int				_last_sync;
	
	float						_fra;
	float						_fps;
    
	float						_d_time;
	float						_sync_time;
	
	float						_volume;
	float						_fx_volume;
	
	unsigned char				_mode;
    
    u_int64_t _currTime;
    u_int64_t _lastSync;
}

-(IBAction)stopGLAnimation;
-(IBAction)startGLAnimation;

-(void)doSwapBuffersAccounting;
-(void)updateViewPort;
-(u_int64_t)currentTime;
-(u_int64_t)lastSyncTime;
-(SFVec*)loc;
-(SFVec*)scl;
-(float)deltaTime;
-(GLint*)matViewPort;
-(void)playMovieList:(NSArray*)movieList;

@property (nonatomic, retain) IBOutlet EAGLView *glView;
@property (nonatomic, retain) IBOutlet SFMovieView *movieView;

@end
