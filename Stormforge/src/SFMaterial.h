//
//  SFMaterial.h
//  ZombieArcade
//
//  Created by Adam Iredale on 8/02/10.
//  Copyright 2010 Stormforge Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SFLoadableGameObject.h"
#import "SFImage.h"
#import "SFColour.h"

#define DEBUG_MATERIALS 0
#define SF_NOTIFY_MATERIAL_FINISHED_FADE @"SFNotifyMaterialFinishedFade"

typedef enum
{
	SF_MATERIAL_MIX = 0,
	SF_MATERIAL_MULTIPLY,
	SF_MATERIAL_ADD,
	SF_MATERIAL_SUBTRACT,
	SF_MATERIAL_DIVIDE,
	SF_MATERIAL_DARKEN,
	SF_MATERIAL_DIFFERENCE,
	SF_MATERIAL_LIGHTEN,
	SF_MATERIAL_SCREEN,
	SF_MATERIAL_OVERLAY,
	SF_MATERIAL_HUE,
	SF_MATERIAL_SATURATION,
	SF_MATERIAL_VALUE,
	SF_MATERIAL_COLOR
	
} SF_MATERIAL_BLEND;

typedef enum{
    SF_MATERIAL_CHANNEL0 = 0,
    SF_MATERIAL_CHANNEL1 = 1,
    SF_MATERIAL_CHANNEL_ALL = 2
} SF_MATERIAL_CHANNEL;

typedef enum{
    SF_RENDER_PASS_OPAQUE,
    SF_RENDER_PASS_ALPHA_TEST,
    SF_RENDER_PASS_ALPHA_BLEND,
    SF_RENDER_PASS_ALL
} SF_RENDER_PASS;

@interface SFMaterial : SFLoadableGameObject {
    
    SFColour *_diffuse, *_specular, *_defaultDiffuse;
    
    float _alpha, _shininess, _friction, _restitution, _alvl;
	
	unsigned char _blend;
	
    //NSMutableDictionary *_textures;
	
    void* _textures[SF_MATERIAL_CHANNEL_ALL];
    
    //variables for flashing
	vec4 _flashColour;
    SFVec *_fadeColourDiffuse;
	BOOL _flashing;
	unsigned int _flashOnRenders, _flashOffRenders;
	BOOL _flashStateIsOn;
	unsigned int _currentFlashRenderCount;
	int _totalFlashRenders;
	
	//for fading out
	BOOL _fading;
	unsigned int _fadeSolidRenders, _fadeTransparentRenders, _fadeTransparentRendersRemaining;
	
    //for fading colour
    BOOL _fadingColour;
    unsigned int _fadeColourRenders, _fadeColourRendersRemaining;
    
    //if this is set, the object will be drawn 50% transparent
	BOOL _drawDisabled;
    
}
-(id)initWithName:(NSString*)name dictionary:(NSDictionary*)dictionary;
-(float)friction;
-(float)restitution;
-(SFColour*)diffuse;
-(void)setDiffuse:(vec4)diffuse;
-(SFColour*)specular;
-(void)setSpecular:(SFColour*)specular;
-(SFColour*)defaultDiffuse;
-(void)setDefaultDiffuse:(vec4)defaultDiffuse;
-(SFImage*)texture:(int)materialChannel;
-(void)setAlvl:(float)alvl;
-(void)setAlpha:(float)alpha;
-(void)setShininess:(float)shininess;
-(void)setFriction:(float)friction;
-(void)setRestitution:(float)restitution;
-(float)alvl;
-(float)alpha;
-(void)setTexture:(int)materialChannel texture:(id)texture;
-(unsigned char)blend;
-(void)setBlend:(unsigned char)blend;
-(void)setTextureFilter:(float)filter forChannel:(int)forChannel;
-(void)setTextureName:(NSString*)name forChannel:(int)forChannel;
-(void)setTextureFlags:(unsigned int)flags forChannel:(int)forChannel;
-(void)resetDiffuse;
-(void)bindImages:(id)imageResource;
-(void)cloneMaterial:(SFMaterial*)aCopy;
-(void)fadeColour:(vec4)fadeColour fadeTime:(float)fadeTime;
-(void)render;
-(void)setDrawDisabled:(BOOL)disabled;
-(void)flash:(vec4)flashColour flashOn:(float)flashOn flashOff:(float)flashOff offAfter:(float)offAfter;
-(void)flash:(vec4)flashColour flashOn:(float)flashOn flashOff:(float)flashOff;
-(void)flashOff;
-(void)resetFadeOut;
-(void)setFadeOut:(float)solid fadeOut:(float)fadeOut;
@end
