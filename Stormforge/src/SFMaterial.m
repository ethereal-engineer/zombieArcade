//
//  SFMaterial.m
//  ZombieArcade
//
//  Created by Adam Iredale on 8/02/10.
//  Copyright 2010 Stormforge Software. All rights reserved.
//

#import "SFMaterial.h"
#import "SFUtils.h"
#import "SFGL.h"
#import "SFConst.h"
#import "SFGameEngine.h"
#import "SFScene.h"

#define DEBUG_ALPHA_TEST 0

#if DEBUG_ALPHA_TEST
static float globalAlvl = 0.2;
#endif
@implementation SFMaterial

+(NSString*)fileDirectory{
    return @"material";
}

-(void)setupTextureDictionary{
    //create a dictionary entry in our object info
    //so we can store information about the textures
    //we will have
    id dictionaryTexInfo = [[NSMutableDictionary alloc] init];
    id texInfo0 = [[NSMutableDictionary alloc] init];
    id texInfo1 = [[NSMutableDictionary alloc] init];
    [dictionaryTexInfo setObject:texInfo0 forKey:[NSNumber numberWithInt:SF_MATERIAL_CHANNEL0]];
    [dictionaryTexInfo setObject:texInfo1 forKey:[NSNumber numberWithInt:SF_MATERIAL_CHANNEL1]];
    [self setObjectInfo:dictionaryTexInfo forKey:@"textureInfo"];
    [texInfo0 release];
    [texInfo1 release];
    [dictionaryTexInfo release];
}

-(id)textureInfo:(int)materialChannel{
    return [[self objectInfoForKey:@"textureInfo"] objectForKey:[NSNumber numberWithInt:materialChannel]];
}

-(BOOL)loadInfo:(SFTokens*)tokens{

    if (tokens->tokenIs("tfl0")) {
        [self setTextureFlags:tokens->valueAsFloats(1)[0] forChannel:SF_MATERIAL_CHANNEL0];
        return YES;
    }
    
    if (tokens->tokenIs("t0")) {
        [self setTextureName:[NSString stringWithUTF8String:tokens->valueAsString()] forChannel:SF_MATERIAL_CHANNEL0];
        return YES;
    }
    if (tokens->tokenIs("tfi0")) {
        [self setTextureFilter:tokens->valueAsFloats(1)[0] forChannel:SF_MATERIAL_CHANNEL0];
        return YES;
    }
    
    if (tokens->tokenIs("tfl1")) {
        [self setTextureFlags:tokens->valueAsFloats(1)[0] forChannel:SF_MATERIAL_CHANNEL1];
        return YES;
    }
    
    if (tokens->tokenIs("t1")) {
        [self setTextureName:[NSString stringWithUTF8String:tokens->valueAsString()] forChannel:SF_MATERIAL_CHANNEL1];
        return YES;
    }
    if (tokens->tokenIs("tfi1")) {
        [self setTextureFilter:tokens->valueAsFloats(1)[0] forChannel:SF_MATERIAL_CHANNEL1];
        return YES;
    }
    
    if (tokens->tokenIs("d")) {
        _defaultDiffuse->setFloats(tokens->valueAsFloats(3), 3);
        return YES;
    }
    
    if (tokens->tokenIs("sp")) {
        _specular->setFloats(tokens->valueAsFloats(3), 3);
        return YES;
    }
    
    if (tokens->tokenIs("a")) {
        [self setAlpha:tokens->valueAsFloats(1)[0]];
        return YES;
    }
    
    if (tokens->tokenIs("sh")) {
        [self setShininess:tokens->valueAsFloats(1)[0]];
        return YES;
    }
    
    if (tokens->tokenIs("fr")) {
        [self setFriction:tokens->valueAsFloats(1)[0]];
        return YES;
    }
    
    if (tokens->tokenIs("re")) {
        [self setRestitution:tokens->valueAsFloats(1)[0]];
        return YES;
    }
    
    if (tokens->tokenIs("al")) {
        [self setAlvl:tokens->valueAsFloats(1)[0]];
        return YES;
    }
    
    if (tokens->tokenIs("b")) {
        [self setBlend:tokens->valueAsFloats(1)[0]];
        return YES;
    }

	return NO;
}

-(void)setDrawDisabled:(BOOL)disabled{
    _drawDisabled = disabled;
}

-(id)initCopyWithDictionary:(NSDictionary *)dictionary{
    self = [super initCopyWithDictionary:dictionary];
    if (self != nil) {
        _diffuse = new SFColour();
        _specular = new SFColour();
        _defaultDiffuse = new SFColour();
        _textures[SF_MATERIAL_CHANNEL0] = NULL;
        _textures[SF_MATERIAL_CHANNEL1] = NULL;
        _alvl = 0.0f;
        _alpha = 1.0f;
        [self setupTextureDictionary];
    }
    return self;
}

-(id)initWithDictionary:(NSDictionary *)dictionary{
    self = [super initWithDictionary:dictionary];
    if (self != nil){
    }
    return self;
}

-(void)cleanupTextures{
    if (_textures[SF_MATERIAL_CHANNEL0]) {
        [(SFImage*)_textures[SF_MATERIAL_CHANNEL0] release];
        _textures[SF_MATERIAL_CHANNEL0] = NULL;
    }
    if (_textures[SF_MATERIAL_CHANNEL1]) {
        [(SFImage*)_textures[SF_MATERIAL_CHANNEL1] release];
        _textures[SF_MATERIAL_CHANNEL1] = NULL;
    }
}

-(void)cleanUp{
    delete _diffuse;
    delete _specular;
    delete _defaultDiffuse;
    if (_fadeColourDiffuse) {
        delete _fadeColourDiffuse;
        _fadeColourDiffuse = nil;
    }
    [self cleanupTextures];
    [super cleanUp];
}

-(id)initWithName:(NSString*)name dictionary:(NSDictionary*)dictionary{
    self = [self initWithDictionary:dictionary];
    if (self != nil) {
        [self setName:name];
    }
    return self;
}

-(void)setFadeLevel{
    //the material is going to change and needs to
    //be rendered - set it so
    SFGL::instance()->releaseActiveMaterial();
	if (_fadeSolidRenders) {
		--_fadeSolidRenders;
		return;
	}
	if (_fadeTransparentRendersRemaining) {
		[self setAlpha:((float)_fadeTransparentRendersRemaining / (float)_fadeTransparentRenders)];
		--_fadeTransparentRendersRemaining;
	} else {
		_fading = NO;
		[self setAlpha:0.0f];
        [self queueObjectNote:SF_NOTIFY_MATERIAL_FINISHED_FADE userInfo:nil];
	}
    
}

-(void)resetFadeOut{
	_fading = NO;
	[self resetDiffuse];
}

-(void)setFadeOut:(float)solid fadeOut:(float)fadeOut{
	[self resetFadeOut];
	_fadeSolidRenders = [[[self sm] currentScene] timeToRenderPasses:solid];
	_fadeTransparentRenders = [[[self sm] currentScene] timeToRenderPasses:fadeOut];
	_fadeTransparentRendersRemaining = _fadeTransparentRenders;
	_fading = YES;
}

-(void)processFlash{
    //the material is going to change and needs to
    //be rendered - set it so
    SFGL::instance()->releaseActiveMaterial();
	if (_totalFlashRenders == 0) {
		[self flashOff];
	} else if (_totalFlashRenders > 0) {
		--_totalFlashRenders;
	}
	if (!_currentFlashRenderCount) {
		//time to swap what flash state we are in (ON/OFF)
		_flashStateIsOn = !_flashStateIsOn;
		if (_flashStateIsOn) {
			_currentFlashRenderCount = _flashOnRenders;
		} else {
			_currentFlashRenderCount = _flashOffRenders;
		}
		
	}
	if (_flashStateIsOn) {
		[self setDiffuse:_flashColour];
	} else {
		[self resetDiffuse];
	}
	
	--_currentFlashRenderCount;
}

-(void)resetDiffuse{
    //resets the diffuse lighting back to the default
    _diffuse->setVector(_defaultDiffuse);
}

-(void)fadeColour:(vec4)fadeColour fadeTime:(float)fadeTime{
    //another fancy eye candy - blends a colour over a period of time
    if (_fadeColourDiffuse) {
        delete _fadeColourDiffuse;
        _fadeColourDiffuse = nil;
    }
    _fadeColourDiffuse = new SFVec(fadeColour);
    _fadeColourRenders = [[[self sm] currentScene] timeToRenderPasses:fadeTime];
    _fadeColourRendersRemaining = _fadeColourRenders;
    _fadingColour = YES;
}

-(void)resolveDependantItems:(id)useResource{
    [super resolveDependantItems:useResource];
    [self bindImages:useResource];
}

-(void)processFadingColour{
    //the material is going to change and needs to
    //be rendered - set it so
    SFGL::instance()->materialReset();
    if (!_fadeColourRendersRemaining) {
        _fadingColour = NO;
        return;
    }
    //currently just fades to white light
    float fadeRatio = (float)_fadeColourRendersRemaining / (float)_fadeColourRenders;
    _fadeColourDiffuse->scale(fadeRatio);
    SFVec *whiteColour = new SFVec(COLOUR_SOLID_WHITE);
    whiteColour->scale(1 - fadeRatio);
    _fadeColourDiffuse->add(whiteColour);
    
    //but don't scale the alpha!
    _fadeColourDiffuse->setW(1.0f);
    _diffuse->setVector(_fadeColourDiffuse);
    --_fadeColourRendersRemaining;
    delete whiteColour;
}

-(void)flash:(vec4)flashColour flashOn:(float)flashOn flashOff:(float)flashOff offAfter:(float)offAfter{
	//allows us to create any simple on-off flashing pattern we like via diffuse lighting
    //if we are already flashing, return
    if (_flashing) {
        return;
    }
	_flashColour = flashColour;
	_flashStateIsOn = NO;
	_flashOnRenders = [[[self sm] currentScene] timeToRenderPasses:flashOn];
	_flashOffRenders = [[[self sm] currentScene] timeToRenderPasses:flashOff];
	_currentFlashRenderCount = _flashOnRenders;
	_totalFlashRenders = [[[self sm] currentScene] timeToRenderPasses:offAfter];
	_flashing = YES;
}

-(void)flash:(vec4)flashColour flashOn:(float)flashOn flashOff:(float)flashOff{
	[self flash:flashColour flashOn:flashOn flashOff:flashOff offAfter:-1];
}

-(void)flashOff{
	//stop flashing and reset diffuse
	_flashing = NO;
	[self resetDiffuse];
}

-(void)setDiffuse:(vec4)diffuse{
    _diffuse->setVec4(diffuse);
}

-(void)setSpecular:(SFColour*)specular{
    _specular->setVector(specular);
}

-(SFColour*)defaultDiffuse{
    return _defaultDiffuse;
}
-(void)setDefaultDiffuse:(vec4)defaultDiffuse{
    _defaultDiffuse->setVec4(defaultDiffuse);
};

-(void)setTextureName:(NSString*)name forChannel:(int)forChannel{
    [[self textureInfo:forChannel] setObject:[name lastPathComponent] forKey:@"name"];
}

-(void)setTextureFlags:(unsigned int)flags forChannel:(int)forChannel{
    [[self textureInfo:forChannel] setObject:[NSNumber numberWithUnsignedInt:flags] forKey:@"flags"];
}

-(void)setTextureFilter:(float)filter forChannel:(int)forChannel{
    [[self textureInfo:forChannel] setObject:[NSNumber numberWithFloat:filter] forKey:@"filter"];
}

-(void)setAlpha:(float)alpha{
    _alpha = alpha;
    _diffuse->setAlpha(alpha);
    _specular->setAlpha(alpha);
}

-(void)setShininess:(float)shininess{
    _shininess = shininess;
}

-(void)setFriction:(float)friction{
    _friction = friction;
}

-(void)setRestitution:(float)restitution{
    _restitution = restitution;
}

-(float)friction{
    return _friction;
}

-(float)restitution{
    return _restitution;
}

-(float)alpha{
    return _alpha;
}

-(float)alvl{
    return _alvl;
}

-(void)setAlvl:(float)alvl{
    _alvl = alvl;
}

-(SFColour*)diffuse{
    return _diffuse;
}

-(SFColour*)specular{
    return _specular;
}

-(id)texture:(int)materialChannel{
    return (id)_textures[materialChannel];
}

-(void)setTexture:(int)materialChannel texture:(id)texture{
    if (_textures[materialChannel]) {
        [(SFImage*)_textures[materialChannel] release];
        _textures[materialChannel] = NULL;
    }
    if (!texture) {
        return;
    }
    [texture retain];
    _textures[materialChannel] = texture;
}

-(unsigned char)blend{
    return _blend;
}

-(void)cloneMaterial:(SFMaterial*)aCopy{
    //[[aCopy diffuse] setVector:_diffuse];
    //[[aCopy specular] setVector:_specular];
    [aCopy setAlpha:_alpha];
    [aCopy setAlvl:_alvl];
    [aCopy setShininess:_shininess];
    [aCopy setFriction:_friction];
    [aCopy setRestitution:_restitution];
    [aCopy setBlend:_blend];
    [aCopy setTexture:SF_MATERIAL_CHANNEL0 texture:[self texture:SF_MATERIAL_CHANNEL0]];
    [aCopy setTexture:SF_MATERIAL_CHANNEL1 texture:[self texture:SF_MATERIAL_CHANNEL1]];
}

-(void)postCopySetup:(id)aCopy{
    [super postCopySetup:aCopy];
    [self cloneMaterial:aCopy];
}

-(void)bindImages:(id)imageResource{
    for (id texId in [self objectInfoForKey:@"textureInfo"]){
        //fetch the images that we previously talked about...
        //only those that have names
        id texInfo = [[self objectInfoForKey:@"textureInfo"] objectForKey:texId];
        id texName = [texInfo objectForKey:@"name"];
        if (!texName) {
            continue;
        }
        id newImage = [imageResource getItem:texName
                               itemClass:[SFImage class]
                                     tryLoad:YES
                                  dictionary:nil];
        if (newImage) {
            [newImage setFilter:[[texInfo objectForKey:@"filter"] floatValue]];
            [newImage resetFlagState:[[texInfo objectForKey:@"flags"] unsignedIntValue]];
            [newImage prepare];
            [self setTexture:[texId integerValue] texture:newImage];
        }
    }
    //don't need this anymore
    [self removeObjectInfoForKey:@"textureInfo"];
}

-(void)setBlend:(unsigned char)blend{
    _blend = blend;
}

-(void)render{ 
    
    if (_drawDisabled){
		[self setAlpha:0.5f];
	} else {
        if (!_diffuse->equals(_defaultDiffuse)) {
            [self resetDiffuse];
        }
	}
    
    if (_flashing) {
		[self processFlash];
	}
    
    if (_fading) {
		[self setFadeLevel];
	}
    
    if (_fadingColour) {
        [self processFadingColour];
    }
    
    //firstly, if the current context has already rendered this mat,
    //we can skip rendering it
    if (!SFGL::instance()->setActiveMaterial(self)) {
        return;
    }
    
    // Alpha Blending
    if (_blend) {
        SFGL::instance()->glEnable(GL_BLEND);
        SFGL::instance()->setBlendMode(_blend);
    } else { 
        SFGL::instance()->glDisable(GL_BLEND);
    }	
    
    
    // Alpha test
    if (_alvl) {
        SFGL::instance()->glEnable(GL_ALPHA_TEST);
#if DEBUG_ALPHA_TEST
        SFGL::instance()->glAlphaFunc(GL_GREATER, globalAlvl);
#else
        SFGL::instance()->glAlphaFunc(GL_GREATER, _alvl);
#endif
    } else {
        SFGL::instance()->glDisable(GL_ALPHA_TEST);
    }
    
    
    // Texture
    //from the largest to the smallest
    for (int iTextureChannel = SF_MATERIAL_CHANNEL_ALL - 1; iTextureChannel >= SF_MATERIAL_CHANNEL0; --iTextureChannel) {
        //id texture = [_textures objectForKey:[NSNumber numberWithInt:iTextureChannel]];
        SFImage *texture = (SFImage*)_textures[iTextureChannel];
        GLenum glTexChannel = (unsigned int)iTextureChannel + GL_TEXTURE0;
        if (texture) {
            SFGL::instance()->glActiveTexture(glTexChannel);
            SFGL::instance()->glEnable(GL_TEXTURE_2D);
            //render the image
            SFGL::instance()->glTexEnvf(GL_TEXTURE_FILTER_CONTROL_EXT, GL_TEXTURE_LOD_BIAS_EXT, [texture filter]);
            SFGL::instance()->glBindTexture(GL_TEXTURE_2D, [texture tid]);
        } else {
            SFGL::instance()->glActiveTexture(glTexChannel);
            SFGL::instance()->glDisable(GL_TEXTURE_2D);
        }
    }
    
    if (SFGL::instance()->capIsEnabled(GL_COLOR_MATERIAL)){
        glMaterialfv( GL_FRONT_AND_BACK, GL_SPECULAR , _specular->floatArray());		
        glMaterialf ( GL_FRONT_AND_BACK, GL_SHININESS, _shininess);
    }
    SFGL::instance()->glColor4f(_diffuse->getVec4());
}

@end
