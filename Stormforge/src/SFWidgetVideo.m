//
//  SFWidgetVideo.m
//  ZombieArcade
//
//  Created by Adam Iredale on 30/12/09.
//  Copyright 2009 Stormforge Software. All rights reserved.
//

#import "SFWidgetVideo.h"
#import "SFUtils.h"
#import "SFGameEngine.h"
#import "SFSound.h"

@implementation SFWidgetVideo

-(void)setupVideoMaterial{
    [self setBaseImageDirect:[_video currentFrame]];
    [self updateImageSize];
}

-(id)initWithVideoName:(NSString *)videoName callbackObject:(id)callbackObject callbackSelector:(SEL)callbackSelector useSound:(BOOL)useSound dictionary:(NSDictionary*)dictionary{
	self = [super initWidget:videoName
				   imageName:NULL
					position:Vec2Zero
					centered:NO
				   touchRect:CGRectZero
			   visibleOnShow:TRUE
			   enabledOnShow:TRUE
			  callbackObject:callbackObject
			callbackSelector:callbackSelector
			dictionary:dictionary];
	if (self != nil) {
        _video = [[self rm] getItem:videoName itemClass:[SFVideo class] tryLoad:YES];
        if (useSound) {
            _sound = [SFSound quickStreamFetch:[[videoName stringByDeletingPathExtension] stringByAppendingPathExtension:@"ogg"]];
        }
	}
	return self;
}

-(BOOL)isFinished{
    return _videoFinished;
}

-(void)setVideoFinished{
    _videoFinished = YES;
    [self callbackWithReason:CR_DONE];
}

-(BOOL)renderFlatObject{
    BOOL renderedOk = NO;
	if (_videoFinished){
        return NO;
    }
    if ([_video nextFrame]) {
        // Check if our image have a Texture ID (tid), if not it means
        // that we didn't have a first frame yet. So instead of rendering
        // a blank texture, we wait to have at least 1 frame in order to
        // start drawing our widgets
        [self setupVideoMaterial];
        //[_material setTexture:SF_MATERIAL_CHANNEL0 texture:[video currentFrame]];
        renderedOk = [super renderFlatObject];
        SFGL::instance()->materialReset();
    }
    _videoFinished = ![_video isPlaying];
    return renderedOk;
}

-(void)play{
	[_video play:NO];
    // [self playAmbientSound:_sound];
}

@end
