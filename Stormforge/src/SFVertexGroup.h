//
//  SFVertexGroup.h
//  ZombieArcade
//
//  Created by Adam Iredale on 8/03/10.
//  Copyright 2010 Stormforge Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SFGameObject.h"
#import "SFMaterial.h"
#import "SFResource.h"

#define DEBUG_SFVERTEXGROUP 0

@interface SFVertexGroup : SFGameObject {
	GLuint	_mode;
	GLuint	_vbo;
	NSString *_materialName;
    SFMaterial *_material;
    unsigned int _vertexCount, _loadedVertexOffset;
	unsigned short *_vertices;
    unsigned char _renderInPass;
}

-(void)setVertexCount:(int)vertexCount mode:(GLuint)mode;
-(void)render:(BOOL)useMaterial renderPass:(unsigned int)renderPass altMaterial:(SFMaterial*)altMaterial;
-(void)setMaterial:(SFMaterial*)material;
-(void)genId;
-(unsigned short*)vertices;
-(void)addVertexShort:(unsigned short)vertexShort;
-(GLuint)mode;
-(int)vertexCount;
-(SFMaterial*)material;
-(void)bindMaterial:(SFResource*)useResource;
-(void)setMaterialName:(NSString*)materialName;
-(BOOL)willRenderInPass:(unsigned int)pass;
@end
