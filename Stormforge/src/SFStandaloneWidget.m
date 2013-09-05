//
//  SFSplash.m
//  ZombieArcade
//
//  Created by Adam Iredale on 27/11/09.
//  Copyright 2009 Stormforge Software. All rights reserved.
//

#import "SFStandaloneWidget.h"
#import "SFGameEngine.h"

@implementation SFStandaloneWidget

-(void)setupWidget:(SFWidget**)widget{
    //children must alloc and init widget in this routine
}

-(BOOL)renderContent{
    //render the internal widget
    return [_internalWidget render];
}

-(id)initWithDictionary:(NSDictionary*)dictionary{
	self = [super initWithDictionary:dictionary];
	if (self != nil) {
        _firstRender = YES;
        [self setupWidget:&_internalWidget];
        [_internalWidget show];
	}
	return self;
}

-(void)firstRenderSetup{
    SFGL::instance()->glClearColor(COLOUR_SOLID_WHITE);
}

-(BOOL)render{
    if (_firstRender) {
        [self firstRenderSetup];
        _firstRender = NO;
    }
	SFGL::instance()->glMatrixMode(GL_MODELVIEW);
	glLoadIdentity();
	
	BOOL renderedOk = NO;
    
	//renders a widget and a loading label
    SFGL::instance()->enter2d(0.0f, 1.0f);
	{
		//enter 2d landscape mode
		SFGL::instance()->enterLandscape2d();
		{		
			
			//render the content
			renderedOk = [self renderContent];
			
			//leave 2d landscape mode
			SFGL::instance()->leaveLandscape2d();
		}
		SFGL::instance()->leave2d();
	}
	SFGL::instance()->objectReset();
#if SF_USE_GL_VBOS
	SFGL::instance()->glBindBuffer(GL_ARRAY_BUFFER, 0);
#endif
    //only swap buffers if we rendered ok
    [SFGameEngine swapBuffers:renderedOk]; 
    return renderedOk;
}

-(void)cleanUp{
    [_internalWidget cleanUp];
    [_internalWidget release];
    [super cleanUp];
}

@end
