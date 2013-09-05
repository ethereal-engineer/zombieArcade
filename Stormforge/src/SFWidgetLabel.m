//
//  SFWidgetLabel.m
//  ZombieArcade
//
//  Created by Adam Iredale on 22/11/09.
//  Copyright 2009 Stormforge Software. All rights reserved.
//

#import "SFWidgetLabel.h"
#import "SFMaterial.h"
#import "SFUtils.h"

@implementation SFWidgetLabel

-(void)setFontInfo:(NSString*)fontName{
    //get extra information so we can draw the font correctly
    NSDictionary *stripInfo = [[_atlas getStripInfo:fontName] retain];
    _space = [[stripInfo objectForKey:@"characterSpacing"] floatValue];
    _size = _boundsRect.size.width;
    _charOffset = [[stripInfo objectForKey:@"characterOffset"] intValue]; //how many characters from the ascii map were skipped
    _lineSpace = [[stripInfo objectForKey:@"lineSpacing"] intValue]; //pixels to move by when moving to next character
    _isFixedWidth = [[stripInfo objectForKey:@"fixedWidth"] boolValue];
    _wideSpace = [[stripInfo objectForKey:@"wideSpace"] intValue];
    _thinSpace = [[stripInfo objectForKey:@"thinSpace"] intValue];
    [stripInfo release];
}

-(float)getCharSpace:(unichar)character{
    if (_isFixedWidth) {
        return _space;
    }
    switch (character) {
        case 'W':
        case 'M':
        case 'R':
        case 'm':
        case 'r':
            return _wideSpace;
            break;
        case 'I':
        case 'l':
        case 'i':
        case '1':
        case '!':
        case '`':
        case '.':
        case ',':
        case '(':
        case ')':
        case '{':
        case '}':
        case '[':
        case ']':
        case '|':
            return _thinSpace;
            break;
        default:
            return _space;
            break;
    }
}

-(float)getLineSpace:(NSString *)line{
    //given a line, how much space does it take up - depends on characters and settings
    //in fixedwidth fonts, each letter takes up the same amount
    float variableSpace = 0;
    
    if (_isFixedWidth) {
        return [line length] * _space;
    } else {
        for (int i = 0; i < [line length]; ++i) {
            variableSpace += [self getCharSpace:[line characterAtIndex:i]];
        }
    }
    return variableSpace;
}

-(id)initLabel:(NSString*)fontName
initialCaption:(NSString*)initialCaption
	  position:(vec2)position
      centered:(BOOL)centered
 visibleOnShow:(BOOL)visibleOnShow
updateViaCallback:(BOOL)updateViaCallback{
	
	self = [super initWidget:@"font"
                   atlasItem:fontName
                    position:position
                    centered:centered
               visibleOnShow:visibleOnShow
                enableOnShow:NO];
	if (self != nil) {
		_internalCaption = [initialCaption copy];
		_updateViaCallback = updateViaCallback;
        [self setFontInfo:fontName];
	}
	return self;
}

-(NSString*)getCaption{
	return _internalCaption;
}

-(void)setCaption:(NSString*)caption{
    //ensure we never render without a caption object
    id oldCaption = _internalCaption;
    _internalCaption = [caption copy];
    [oldCaption release];
}

-(void)renderLabel{
    
    [_material render];
	
	//[_font bindFont];
	
	SFGL::instance()->glPushMatrix();
	{	
        
		//[_font renderText:_internalCaption centered:_centered];
  	}
	SFGL::instance()->glPopMatrix();
	
}

-(void)cleanUp{
    [_internalCaption release];
    [super cleanUp];
}

-(void)draw{
    //instead of drawing one time we will be drawing many times and advancing
    //etc
    //_transform->multMatrix();

    float space;
    
    //here we split the string into lines by new line character
    NSArray *lines = [_internalCaption componentsSeparatedByString:@"\n"];
    
    //if this is centered, we offset by the total number of lines and the space
    //each line takes up vertically (halved)
    if (_justification == ljCenter) {
        SFGL::instance()->glTranslatef(0.0f,
                                       (_space + _lineSpace) * [lines count] * 0.5f,
                                       0.0f);  
    }
    
    for (NSString *line in lines) {
        
        //if this is centered, we offset by the length of the current line halved
        //to start with
        if (_justification == ljCenter) {
            SFGL::instance()->glTranslatef([self getLineSpace:line] * -0.5f, 0.0f, 0.0f);
        }
        
        //at this point, we have used NO space - so we reset our spaces counter
        space = 0.0f;
        
        for (int i = 0; i < [line length]; ++i) {
            
            unichar oneChar = [line characterAtIndex:i];
            float charSpace = [self getCharSpace:oneChar];
            
            //draw one character
            [self setImageOffsetLinear:(oneChar - _charOffset)];
            SFGL::instance()->glTexCoordPointer(2, GL_FLOAT, 0, _mainStripTexUV);
            [super draw];
//            SFGL::instance()->glDrawArrays(GL_TRIANGLE_FAN,
//                                           (oneChar - _charOffset) << 2,
//                                           4);
            
            //advance one space
            SFGL::instance()->glTranslatef(charSpace, 0.0f, 0.0f);
            //tally all spaces advanced
            space += charSpace;
            
        }
        
        if (_justification == ljCenter) {
            //if we are centered, we move back only HALF of all the space we have moved forwards
            SFGL::instance()->glTranslatef(-space * 0.5f,
                                           -(_size + _lineSpace),
                                           0.0f);
            
        } else {
            //if we are left aligned, we move back all of it
            SFGL::instance()->glTranslatef(-space,
                                           -(_size + _lineSpace),
                                           0.0f);
        }
    }
}

-(void)setJustification:(SFLabelJustification)justification{
    _justification = justification;
}

-(BOOL)render{
	//if we need a dynamic label set, get it
	if (_updateViaCallback) {
		[_widgetDelegate widgetCallback:self reason:CR_UPDATE_LABEL];
	}
	[super render];
    return YES;
}

@end
