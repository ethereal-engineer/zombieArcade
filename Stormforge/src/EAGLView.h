//
//  EAGLView.h
//  
//
//
#import <UIKit/UIKit.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>

#define SF_DEFAULT_FRAME_INTERVAL 2
#define DEBUG_EAGLVIEW 0

/*
This class wraps the CAEAGLLayer from CoreAnimation into a convenient UIView subclass.
The view content is basically an EAGL surface you render your OpenGL scene into.
Note that setting the view non-opaque will only work if the EAGL surface has an alpha channel.
*/

@interface EAGLView : UIView {
	id context;
	/* The pixel dimensions of the backbuffer */
	GLint _backingWidth;
	GLint _backingHeight;
    
    BOOL _animating;
	BOOL _displayLinkSupported;
	NSInteger _animationFrameInterval;
	// Use of the CADisplayLink class is the preferred method for controlling your animation timing.
	// CADisplayLink will link to the main display and fire every vsync when added to a given run-loop.
	// The NSTimer class is used only as fallback when running on a pre 3.1 device where CADisplayLink
	// isn't available.
	id _displayLink;
    NSTimer *_animationTimer;
	
	/* OpenGL names for the renderbuffer and framebuffers used to render to this view */
	GLuint _viewRenderbuffer, _viewFramebuffer;
	
	/* OpenGL name for the depth buffer that is attached to viewFramebuffer, if it exists (0 if it does not exist) */
	GLuint _depthRenderbuffer;
}

-(GLint)backingWidth;
-(GLint)backingHeight;
-(void)swapBuffers;
-(void)destroyFramebuffer;
-(void)createFramebuffer;
-(IBAction)startAnimation;
-(IBAction)stopAnimation;
-(void)setAnimationFrameInterval:(NSInteger)frameInterval;

@property (nonatomic, retain) id context;

@end
