//
//  SFVertexGroup.m
//  ZombieArcade
//
//  Created by Adam Iredale on 8/03/10.
//  Copyright 2010 Stormforge Software. All rights reserved.
//

#import "SFVertexGroup.h"
#import "SFGLManager.h"
#import "SFGameEngine.h"
#import "SFDebug.h"

@implementation SFVertexGroup

-(id)initCopyWithDictionary:(NSDictionary *)dictionary{
    self = [super initCopyWithDictionary:dictionary];
    if (self != nil) {
        //default render in opaque pass
        _renderInPass = SF_RENDER_PASS_OPAQUE;
    }
    return self;
}

-(GLuint)mode{
    return _mode;
}

-(int)vertexCount{
    return _vertexCount;
}

-(SFMaterial*)material{
    return _material;
}

-(unsigned short*)vertices{
    return _vertices;
}

-(void)addVertexShort:(unsigned short)vertexShort{
    memcpy(&_vertices[_loadedVertexOffset], (void*)&vertexShort, sizeof(unsigned short));
    ++_loadedVertexOffset;
}

-(void)setVertexCount:(int)vertexCount mode:(GLuint)mode{
    _vertexCount = vertexCount;
   // _vertices = (unsigned short *)realloc(_vertices, _vertexCount << 1);
    _vertices = (unsigned short *)malloc(_vertexCount << 1);
    _mode = mode;
    sfDebug(DEBUG_SFVERTEXGROUP,"Using vertex mode %u", _mode); 
}

-(void)setMaterialName:(NSString*)materialName{
    _materialName = [materialName retain];
}

-(BOOL)willRenderInPass:(unsigned int)pass{
    return _renderInPass == pass;
}

-(void)render:(BOOL)useMaterial renderPass:(unsigned int)renderPass altMaterial:(SFMaterial*)altMaterial{
	
    if (useMaterial)
	{
        if (altMaterial) {
            [altMaterial render];
        } else {
            [_material render];
        }
	}

#if SF_USE_GL_VBOS
    SFGL::instance()->glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _vbo);
#endif
    
    SFGL::instance()->glDrawElements(_mode, _vertexCount, GL_UNSIGNED_SHORT, SF_BUFFER_OFFSET(0, _vertices));
}

-(void)bindMaterial:(SFResource*)useResource{
    //if we have a pre-set material name, set our material from it
    if ((_materialName) and (!_material)){
        //the vertex group has a material assigned - map it
        id resource = useResource;
        if (!resource) {
            resource = [self rm]; //all resources
        }
        [self setMaterial:[resource getItem:_materialName itemClass:[SFMaterial class] tryLoad:YES]];
    }
}

-(void)genId{
#if SF_USE_GL_VBOS
    if (_vbo) {
        return;
    }
    if (_vertices) {
		glGenBuffers(1, &_vbo);
		
        //sfDebug(TRUE, "%s vertgroup %s(%d) got vbo %u", [[self description] UTF8String], _SIO2vertexgroup->name, groupIndex, _SIO2vertexgroup->vbo);
        
        SFGL::instance()->glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _vbo);
		
        SFGL::instance()->glBufferData(GL_ELEMENT_ARRAY_BUFFER, _vertexCount << 1, &_vertices[0], GL_STATIC_DRAW);
        
		if (_material)
		{
			free(_vertices);
			_vertices = nil;
		}
	}
#endif
}

-(void)setVertices:(unsigned short*)vertices{
    memcpy(_vertices, vertices, _vertexCount << 1);
    [self genId];
}

-(void)duplicateVertices:(SFVertexGroup*)aCopy{
    
    //this happens AFTER we have buffered them into GL so we need to map them to 
    //use them

#if SF_USE_GL_VBOS
    _vertices = (unsigned short *)SFGL::instance()->mapBuffer(_vbo, GL_ELEMENT_ARRAY_BUFFER);
    {
#endif
        [aCopy setVertices:_vertices];
#if SF_USE_GL_VBOS
    }
    SFGL::instance()->unMapBuffer(_vbo, GL_ELEMENT_ARRAY_BUFFER);
    _vertices = nil;
#endif
}

-(void)setMaterial:(SFMaterial*)material{
    if (_material) {
        [_material release];
    }
    if (material) {
        _material = [material retain];
        //categorise the vertex group into one of the following for render order
        if ([material alvl] > 0.0f) {
            //sfDebug(TRUE, "Material %s classified as ALPHA_TEST in vgroup %d", [material UTF8Description], vertexGroupIndex);
            _renderInPass = SF_RENDER_PASS_ALPHA_TEST;
        } else if ([material alpha] < 1.0f) {
            //sfDebug(TRUE, "Material %s classified as ALPHA_BLEND in vgroup %d", [material UTF8Description], vertexGroupIndex);
            _renderInPass = SF_RENDER_PASS_ALPHA_BLEND;
        } else {
            _renderInPass = SF_RENDER_PASS_OPAQUE;
        }

    } else {
        _material = nil;
    }
}

-(void)cleanUp{
    if (![EAGLContext currentContext]) {
        [EAGLContext setCurrentContext:[SFGameEngine glContext]];
    }
    
#if SF_USE_GL_VBOS
    SFGL::instance()->glDeleteBuffers(1, &_vbo);
#endif
    
    if (_vertices) {
        free(_vertices);
        _vertices = nil;
    }
    if (_material) {
        [_material release];
    }
    [super cleanUp];
}

-(void)postCopySetup:(id)aCopy{
    [super postCopySetup:aCopy];
    [aCopy setMaterialName:[_materialName copy]];
    [aCopy setMaterial:_material]; //link the material until further notice
    [aCopy setVertexCount:_vertexCount mode:_mode];
    [self duplicateVertices:aCopy];
}

@end
