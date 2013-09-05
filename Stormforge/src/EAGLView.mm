//
//  EAGLView.mm
//  template
//
//  Created by SIO2 Interactive on 8/22/08.
//  Copyright SIO2 Interactive 2008. All rights reserved.
//



#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/EAGLDrawable.h>

#import "EAGLView.h"
#import "SFSceneManager.h"
#import "SFTouchEvent.h"
#import "main.h"
#include "SFGL.h"
#import "SFDebug.h"
#import "SFGameEngine.h"

@implementation EAGLView

@synthesize context;

// this must be implemented
+ (Class)layerClass {
	return [CAEAGLLayer class];
}


-(void)startAnimation{
	if (!_animating)
	{
		if (_displayLinkSupported)
		{
			// CADisplayLink is API new to iPhone SDK 3.1. Compiling against earlier versions will result in a warning, but can be dismissed
			// if the system version runtime check for CADisplayLink exists in -initWithCoder:. The runtime check ensures this code will
			// not be called in system versions earlier than 3.1.
			
			_displayLink = [NSClassFromString(@"CADisplayLink") displayLinkWithTarget:self selector:@selector(drawView:)];
			[_displayLink setFrameInterval:_animationFrameInterval];
			[_displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
		}
		else
			_animationTimer = [NSTimer scheduledTimerWithTimeInterval:(NSTimeInterval)((1.0 / 60.0) * _animationFrameInterval) target:self selector:@selector(drawView:) userInfo:nil repeats:TRUE];
		
		_animating = TRUE;
	}
}

-(void)stopAnimation{
	if (_animating){
		if (_displayLinkSupported)
		{
			[_displayLink invalidate];
			_displayLink = nil;
		}
		else
		{
			[_animationTimer invalidate];
			_animationTimer = nil;
		}
		
		_animating = FALSE;
	}
}


-(void)drawView:(id)sender
{
   // [renderer render];
    [SFGameEngine render];
}

- (void) layoutSubviews{
    [self drawView:nil];
}

-(NSInteger)animationFrameInterval{
	return _animationFrameInterval;
}

-(void)setAnimationFrameInterval:(NSInteger)frameInterval{
	// Frame interval defines how many display frames must pass between each time the
	// display link fires. The display link will only fire 30 times a second when the
	// frame internal is two on a display that refreshes 60 times a second. The default
	// frame interval setting of one will fire 60 times a second when the display refreshes
	// at 60 times a second. A frame interval setting of less than one results in undefined
	// behavior.
	if (frameInterval >= 1)
	{
		_animationFrameInterval = frameInterval;
		
		if (_animating)
		{
			[self stopAnimation];
			[self startAnimation];
		}
	}
}

//The GL view is stored in the nib file. When it's unarchived it's sent -initWithCoder:
- (id)initWithCoder:(NSCoder*)coder{
	
	if ((self = [super initWithCoder:coder])) {
		// Get the layer
		CAEAGLLayer *eaglLayer = (CAEAGLLayer *)self.layer;
		
		eaglLayer.opaque = YES;
		eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
		   [NSNumber numberWithBool:NO], kEAGLDrawablePropertyRetainedBacking, kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];
		
		context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1];
		
		if (!context || ![EAGLContext setCurrentContext:context]) {
			[self release];
			return nil;
		}
		
		// Enable multitouch
		[ self setMultipleTouchEnabled:NO ];
		
        _animating = NO;
        _animationTimer = nil;
		_displayLinkSupported = FALSE;
		_animationFrameInterval = SF_DEFAULT_FRAME_INTERVAL;
		_displayLink = nil;
		
		// A system version of 3.1 or greater is required to use CADisplayLink. The NSTimer
		// class is used as fallback when it isn't available.
		NSString *reqSysVer = @"3.1";
		NSString *currSysVer = [[UIDevice currentDevice] systemVersion];
		if ([currSysVer compare:reqSysVer options:NSNumericSearch] != NSOrderedAscending)
			_displayLinkSupported = TRUE;
		
	}
	return self;
}

-(void)createFramebuffer{
	sfDebug(DEBUG_EAGLVIEW, "Creating frame buffer etc...");
	glGenFramebuffersOES(1, &_viewFramebuffer);
	glGenRenderbuffersOES(1, &_viewRenderbuffer);

	glBindFramebufferOES(GL_FRAMEBUFFER_OES, _viewFramebuffer);
	glBindRenderbufferOES(GL_RENDERBUFFER_OES, _viewRenderbuffer);
	
	glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_COLOR_ATTACHMENT0_OES, GL_RENDERBUFFER_OES, _viewRenderbuffer);
	[context renderbufferStorage:GL_RENDERBUFFER_OES fromDrawable:(CAEAGLLayer*)self.layer];
	glBindRenderbufferOES(GL_RENDERBUFFER_OES, _viewRenderbuffer);
	
    //PERF ISSUE:
    //this should be called infrequently as it may cause the 
    //gl hardware to lockstep with the cpu
    
	glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_WIDTH_OES, &_backingWidth);
	glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_HEIGHT_OES, &_backingHeight);
	
	glGenRenderbuffersOES(1, &_depthRenderbuffer);
	glBindRenderbufferOES(GL_RENDERBUFFER_OES, _depthRenderbuffer);
	glRenderbufferStorageOES(GL_RENDERBUFFER_OES, GL_DEPTH_COMPONENT16_OES, _backingWidth, _backingHeight);
	glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_DEPTH_ATTACHMENT_OES, GL_RENDERBUFFER_OES, _depthRenderbuffer);
	
    sfDebug(DEBUG_EAGLVIEW, "Skipping flush...");
	//glFlush();
	
	if (SFGL::instance()->glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES) != GL_FRAMEBUFFER_COMPLETE_OES){
		sfThrow("Failed to make complete framebuffer object %x", glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES));
    }
	
}

-(void)destroyFramebuffer{
	sfDebug(DEBUG_EAGLVIEW, "Destroying frame buffer etc...");
	glDeleteFramebuffersOES(1, &_viewFramebuffer);
	_viewFramebuffer = 0;
	glDeleteRenderbuffersOES(1, &_viewRenderbuffer);
	_viewRenderbuffer = 0;
	
	if(_depthRenderbuffer) {
		glDeleteRenderbuffersOES(1, &_depthRenderbuffer);
		_depthRenderbuffer = 0;
	}
}

-(GLint)backingWidth{
    return _backingWidth;
}

-(GLint)backingHeight{
    return _backingHeight;
}

-(void)dealloc{
    //no cleanup for this one - hierarchy
	[context release];
	[super dealloc];
}

-(void)swapBuffers{
	glBindRenderbufferOES(GL_RENDERBUFFER_OES, _viewRenderbuffer);
	[context presentRenderbuffer:GL_RENDERBUFFER_OES];
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	SFTouchEvent *touchEvent = [SFTouchEvent initWithTouches:touches eventType:TOUCH_EVENT_BEGAN view:self];
	[SFGameEngine pushTouchEvent:touchEvent];
    [touchEvent release];
}


-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
	SFTouchEvent *touchEvent = [SFTouchEvent initWithTouches:touches eventType:TOUCH_EVENT_MOVED view:self];
	[SFGameEngine pushTouchEvent:touchEvent];
    [touchEvent release];
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	SFTouchEvent *touchEvent = [SFTouchEvent initWithTouches:touches eventType:TOUCH_EVENT_ENDED view:self];
	[SFGameEngine pushTouchEvent:touchEvent];
    [touchEvent release];
}

@end
