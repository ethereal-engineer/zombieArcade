//
//  SFWidget.h
//  ZombieArcade
//
//  Created by Adam Iredale on 22/11/09.
//  Copyright 2009 Stormforge Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SFProtocol.h"
#import "SFTouchEvent.h"
#import "SFImage.h"
#import "SFRect.h"
#import "SFMaterial.h"
#import "SFTransform.h"
#import "SFWidgetShade.h"
#import "SFTextureAtlas.h"
#import "SFAtlasStrip.h"

#define RENDER_WIDGETS 1
#define DEBUG_SFWIDGET 0

@interface SFWidget : SFWidgetShade {

    NSString *_atlasName; //retain a link to the atlas name
    NSString *_atlasItem; //retain the item id
    
    SFTextureAtlas *_atlas;     //the atlas this widget uses
    
    SFAtlasStrip *_mainStrip;  //the main strip of the atlas that we use for opengl UV coords (pointers only here)
    SFAtlasStrip *_overlayStrip;
    GLfloat *_mainStripTexUV;
    GLfloat *_overlayStripTexUV;
    GLfloat *_highlightTexUV;  //because only the main and overlays will change (dynamic images), we don't need to
    GLfloat *_shadowTexUV;     //keep references to the atlas strip of them as well
    
    CGRect  _overlayDimensions; //we keep a copy of the overlay dimensions (overlays are laid in the center of the main)
    GLfloat *_overlayVertex;
    
    CGPoint _currentOffset;     //the current offset that is being rendered
    CGPoint _currentOverlayOffset;    //overlays can be drawn over the top of the widget - useful for text on buttons etc
    CGPoint _centerOffset;      //NOT like the other offsets - this lets us know if the image has a shadow or other thing
                                //that moves it's center position - helps us line up text and buttons etc
    BOOL    _useOverlay;        //draw an overlay over the widget?
    BOOL    _atlasPrepared;     //is the atlas prepped yet?
    BOOL    _loopSequence;      //when we reach the end of the image sequence (or beginning) do we loop around?
    
    CGPoint _sequenceStart, _sequenceEnd;

}

-(id)initWidget:(NSString*)atlasName        //the atlas name
      atlasItem:(NSString*)atlasItem        //the name of the strip that this widget corresponds to in the atlas (e.g. status)
       position:(vec2)position              //the position on screen this widget should be drawn at
       centered:(BOOL)centered              //draw this widget from the center outwards? (otherwise pos is bottom left) 
  visibleOnShow:(BOOL)visibleOnShow         //is this widget initially visible when show is called?
   enableOnShow:(BOOL)enableOnShow;          //is this widget initially enabled (touchable) when show is called?

-(id)initBlankWidget:(vec2)position
            centered:(BOOL)centered
       visibleOnShow:(BOOL)visibleOnShow 
        enableOnShow:(BOOL)enableOnShow;

-(void)setImageOffsetLinear:(int)imageOffset;
-(void)setImageOffset:(CGPoint)imageOffset;    //change the image the widget is displaying by specifying an offset of width and height
-(void)setOverlayOffset:(CGPoint)overlayOffset; //change the offset the widget is displaying
-(void)startImageSequence:(CGPoint)startOffset endOffset:(CGPoint)endOffset loop:(BOOL)loop;
-(void)resetImageSequence;
-(BOOL)nextImage;
-(BOOL)prevImage;
@end
