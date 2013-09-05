//
//  SFWidget.m
//  ZombieArcade
//
//  Created by Adam Iredale on 22/11/09.
//  Copyright 2009 Stormforge Software. All rights reserved.
//

#import "SFWidget.h"
#import "SFUtils.h"
#import "SFDefines.h"
#import "SFConst.h"
#import "SFSound.h"
#import "SFGameEngine.h"
#import "SFDebug.h"

@implementation SFWidget

-(void)loadFromAtlas{
    //using the atlas provided by the atlas manager, we can simplify loading

    //set the atlas image as our material source
    SFImage *atlasImage = [[_atlas atlasImage] retain];
    [_material setTexture:SF_MATERIAL_CHANNEL0 texture:atlasImage];
    
    //keep a link to the items in the atlas we are keen on
    _mainStrip = [_atlas getStrip:_atlasItem];
    
    NSDictionary *itemInfo = [[_atlas getStripInfo:_atlasItem] retain];
    [SFUtils assert:(itemInfo != nil) failText:@"No information for atlas item"];
    
    NSString *originStr = [itemInfo objectForKey:@"origin"];
    NSString *overlayStr = [itemInfo objectForKey:@"overlayStrip"];
    NSString *shadowStr = [itemInfo objectForKey:@"shadow"];
    NSString *highlightStr = [itemInfo objectForKey:@"highlight"];
    NSString *touchStr = [itemInfo objectForKey:@"touch"];
    NSString *centerOffsetStr = [itemInfo objectForKey:@"centerOffset"];
    
    if (originStr) {
        _boundsRect = CGRectFromString(originStr);
    } else {
        //no specific origin - use the whole image
        _boundsRect = CGRectMake(0, 0, [atlasImage width], [atlasImage height]);
    }
    [self setMargins:0 vertical:0];
    //now we can build the vertex array
    [self setDimensions:CGPointMake(_boundsRect.size.width, _boundsRect.size.height)];
    //reset image offset
    [self setImageOffset:CGPointMake(0,0)];
    
    if (centerOffsetStr) {
        _centerOffset = CGPointFromString(centerOffsetStr);
    }
    
    if (overlayStr) {
        _overlayStrip = [_atlas getStrip:overlayStr];
        _overlayDimensions = CGRectFromString([[_atlas getStripInfo:overlayStr] objectForKey:@"origin"]);
        //create the overlay's verticies
        _overlayVertex = [self newRectangularVertexArray:CGRectMake(0, 0, _overlayDimensions.size.width, 
                                                                    _overlayDimensions.size.height) ccw:YES];
        _useOverlay = YES;
        //reset the overlay offset
        [self setOverlayOffset:CGPointMake(0,0)];
    }
    
    if (shadowStr) {
        SFAtlasStrip *shadowStrip = [_atlas getStrip:shadowStr];
        _shadowTexUV = shadowStrip->cellPoints(CGPointZero);
    }
    
    if (highlightStr) {
        SFAtlasStrip *highlightStrip = [_atlas getStrip:highlightStr];
        _highlightTexUV = highlightStrip->cellPoints(CGPointZero);
    }
    
    if (touchStr) {
        _touchRect = CGRectFromString(touchStr);
    }
    
    NSDictionary *soundInfo = [itemInfo objectForKey:@"sounds"];
    
    if (!soundInfo) {
        return;
    }
    
    //activate/deactivate sounds (only the names - not loaded until used)
    _soundActivate = [[soundInfo objectForKey:@"activate"] retain];
    _soundDeactivate = [[soundInfo objectForKey:@"deactivate"] retain];
    
    [atlasImage release];
    [itemInfo release];
}

-(id)initWidget:(NSString*)atlasName
      atlasItem:(NSString*)atlasItem
       position:(vec2)position
       centered:(BOOL)centered
  visibleOnShow:(BOOL)visibleOnShow 
   enableOnShow:(BOOL)enableOnShow{
    self = [self initBlankWidget:position
                        centered:centered
                   visibleOnShow:visibleOnShow
                    enableOnShow:enableOnShow];
    if (self != nil) {
        _atlas = [[[self atlm] loadAtlas:atlasName] retain];
        _atlasItem = [atlasItem retain];
        [self loadFromAtlas];
        [self setMargins:0 vertical:0];
    }
    return self;
}

-(id)initBlankWidget:(vec2)position
       centered:(BOOL)centered
  visibleOnShow:(BOOL)visibleOnShow 
   enableOnShow:(BOOL)enableOnShow{
    self = [self initShadedWidget:position
                         centered:centered
                    visibleOnShow:visibleOnShow
                     enableOnShow:enableOnShow];
    if (self != nil) {

    }
    return self;
}

-(void)setImageOffset:(CGPoint)imageOffset{
    //update our float array pointers    
    _currentOffset = imageOffset;
    _mainStripTexUV = _mainStrip->cellPoints(imageOffset);
}

-(void)setImageOffsetLinear:(int)imageOffset{
    //just move continually along the array
    //cells in a line - NOT compatible with current offset or sequences
    _mainStripTexUV = _mainStrip->linearCellPoints(imageOffset);
}

-(void)setOverlayOffset:(CGPoint)overlayOffset{
    //update our float array pointers    
    _currentOverlayOffset = overlayOffset;
    _overlayStripTexUV = _overlayStrip->cellPoints(overlayOffset);
}

-(void)startImageSequence:(CGPoint)startOffset endOffset:(CGPoint)endOffset loop:(BOOL)loop{
    _sequenceStart = startOffset;
    _sequenceEnd = endOffset;
    _loopSequence = loop;
    [self resetImageSequence];
}

-(void)resetImageSequence{
    [self setImageOffset:_sequenceStart];    
}

-(BOOL)prevImage{
    if (CGPointEqualToPoint(_sequenceStart, _currentOffset)) {
        if (!_loopSequence) {
            return NO;
        } else {
            [self setImageOffset:CGPointMake(_sequenceEnd.x, _sequenceEnd.y)];
        }
    } else {
        if (_currentOffset.x == _sequenceStart.x) {
            //roll back a line
            [self setImageOffset:CGPointMake(_sequenceEnd.x, _currentOffset.y + 1)];
        } else {
            //move leftward
            [self setImageOffset:CGPointMake(_currentOffset.x - 1, _currentOffset.y)];
        }
    }
    return YES;
}

-(BOOL)nextImage{
    //moves through an image sequence in
    //a row-then-column (like reading) fashion
    if (CGPointEqualToPoint(_currentOffset, _sequenceEnd)) {
        if (!_loopSequence) {
            return NO;
        } else {
            [self setImageOffset:CGPointMake(_sequenceStart.x, _sequenceStart.y)];
        }
    } else {
        if (_currentOffset.x == _sequenceEnd.x) {
            //roll over a line
            [self setImageOffset:CGPointMake(_sequenceStart.x, _currentOffset.y + 1)];
        } else {
            //move rightward
            [self setImageOffset:CGPointMake(_currentOffset.x + 1, _currentOffset.y)];
        }

    }
    return YES;
}

-(void)cleanUp{
    if (_overlayVertex) {
        free(_overlayVertex);
        _overlayVertex = nil;
    }
    [_atlas release];
    [_atlasItem release];
    [super cleanUp];
} 

-(void)preDraw{
    //this allows us to add new widgets mid-scene but
    //remember that buffering textures is a very expensive
    //operation and that we should manually prepare the
    //atlases first in most cases
    if (!_atlasPrepared) {
        [[_material texture:SF_MATERIAL_CHANNEL0] prepare];
        _atlasPrepared = YES;
    }
    
    [super preDraw];
    
    SFGL::instance()->glClientActiveTexture(GL_TEXTURE0);
    SFGL::instance()->glEnableClientState(GL_TEXTURE_COORD_ARRAY);
    //if the widget image has a center offset, align with it now
    SFGL::instance()->glTranslatef(-_centerOffset.x, -_centerOffset.y, 0.0f);  
    
    if (_shadowTexUV and !_activated) {
        //draw the shadow
        SFGL::instance()->glTexCoordPointer(2, GL_FLOAT, 0, (const GLfloat*)_shadowTexUV);
        SFGL::instance()->glDrawArrays(GL_TRIANGLE_FAN, 0, 4);
    }
    
    SFGL::instance()->glTexCoordPointer(2, GL_FLOAT, 0, (const GLfloat*)_mainStripTexUV);
}

-(void)postDraw{
    if (_highlightTexUV and _activated) {
        //draw the highlight
        SFGL::instance()->glTexCoordPointer(2, GL_FLOAT, 0, (const GLfloat*)_highlightTexUV);
        SFGL::instance()->glDrawArrays(GL_TRIANGLE_FAN, 0, 4);
    }
    if (_useOverlay) {
        //draw the overlay as well - first move into place
        GLfloat xDiff = _centerOffset.x + _boundsRect.size.width - _overlayDimensions.size.width,
        yDiff = _centerOffset.y + _boundsRect.size.height - _overlayDimensions.size.height;
        SFGL::instance()->glTranslatef(xDiff / 2.0f, yDiff / 2.0f, 0.0f);
        SFGL::instance()->glVertexPointer(2, GL_FLOAT, 0, (const GLfloat*)_overlayVertex);
        SFGL::instance()->glTexCoordPointer(2, GL_FLOAT, 0, (const GLfloat*)_overlayStripTexUV);
        SFGL::instance()->glDrawArrays(GL_TRIANGLE_FAN, 0, 4); 
    }
    SFGL::instance()->glClientActiveTexture(GL_TEXTURE0);
    SFGL::instance()->glDisableClientState(GL_TEXTURE_COORD_ARRAY);
    [super postDraw];
}

@end
