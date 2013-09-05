//
//  SFGLContext.h
//  ZombieArcade
//
//  Created by Adam Iredale on 16/02/10.
//  Copyright 2010 Stormforge Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EAGLView.h"
#import "SFGLSet.h"
#import "SFDefines.h"

#define DEBUG_SFGLCONTEXT 0

@interface SFGLContext : EAGLContext {
    //just adding a cache of states (for now)
    SFGLSet *_glCapSet, *_coordArrayTextures, *_texture2DTextures;
    GLenum _activeTexture, _clientActiveTexture;
    vec4 _colour, _clearColour;
    GLenum _alphaFunc;
    GLclampf _alphaFuncRef;
    GLfloat _imageFilter;
    GLenum _lastFrameBufferStatusOES;
    GLuint _boundArrayBuffer;
    GLuint _boundElementArrayBuffer;
    GLenum _clientStateArray;
    GLenum _currentMatrixStack;
    unsigned int _blendMode;
    GLuint _boundTexture;
    id _activeMaterial;
}

+(BOOL)glEnable:(GLenum)cap;
+(BOOL)glEnableClientState:(GLenum)array;
+(BOOL)glDisable:(GLenum)cap;
+(BOOL)glDisableClientState:(GLenum)array;
+(BOOL)glActiveTexture:(GLenum)texture;
+(BOOL)glClientActiveTexture:(GLenum)texture;
+(BOOL)capIsEnabled:(GLenum)cap;
+(BOOL)glColor4f:(vec4)color;
+(BOOL)glAlphaFunc:(GLenum)func ref:(GLclampf)ref;
+(BOOL)glTexEnvf:(GLenum)target pname:(GLenum)pname param:(GLfloat)param;
+(BOOL)glBindBuffer:(GLenum)target buffer:(GLuint)buffer;
+(BOOL)glBindTexture:(GLenum)target texture:(GLuint)texture;
+(BOOL)glDrawElements:(GLenum)mode count:(GLsizei)count type:(GLenum)type indicies:(const GLvoid *)indices;
+(BOOL)glDrawArrays:(GLenum)mode first:(GLint)first count:(GLsizei)count;
+(BOOL)glClearColor:(vec4)clear;
+(GLenum)glCheckFramebufferStatusOES:(GLenum)framebuffer;
+(void)glBufferData:(GLenum)target size:(GLsizeiptr)size data:(const GLvoid *)data usage:(GLenum)usage;
+(void)glTexImage2D:(GLenum)target level:(GLint)level internalformat:(GLint)internalformat width:(GLsizei)width
             height:(GLsizei)height border:(GLint)border format:(GLenum)format type:(GLenum)type
             pixels:(const GLvoid *)pixels;
+(void)glTexSubImage2D:(GLenum)target level:(GLint)level xoffset:(GLint)xoffset yoffset:(GLint)yoffset width:(GLsizei)width
                height:(GLsizei)height format:(GLenum)format type:(GLenum)type
                pixels:(const GLvoid *)pixels;
+(void)glTexCoordPointer:(GLint)size type:(GLenum)type stride:(GLsizei)stride pointer:(const GLvoid *)pointer;
+(void)glVertexPointer:(GLint)size type:(GLenum)type stride:(GLsizei)stride pointer:(const GLvoid *)pointer;

+(void)glTranslatef:(GLfloat)x y:(GLfloat)y z:(GLfloat)z;
+(void)glRotatef:(GLfloat)w x:(GLfloat)x y:(GLfloat)y z:(GLfloat)z;
+(void)glScalef:(GLfloat)x y:(GLfloat)y z:(GLfloat)z;
+(void)glLightf:(GLenum)light pname:(GLenum)pname param:(GLfloat)param;
+(void)glLightfv:(GLenum)light pname:(GLenum)pname params:(SFVec*)params;
+(void)glLightModelfv:(GLenum)pname params:(SFVec*)params;
+(void)glLightModelf:(GLenum)pname param:(GLfloat)param;

+(void)glDeleteBuffers:(GLsizei)n buffers:(const GLuint*)buffers;
+(void)glDeleteTextures:(GLsizei)n textures:(const GLuint*)textures;

//matrix
+(void)glPushMatrix;
+(void)glPopMatrix;
+(void)glMatrixMode:(GLenum)mode;

+(BOOL)cachedState:(GLenum)cap;

+(void*)mapBuffer:(GLuint)buffer target:(GLenum)target;
+(void)unMapBuffer:(GLuint)buffer target:(GLenum)target;
+(SFGLContext*)currentSFGLContext;
+(void)setBlendMode:(unsigned int)blendMode;

+(void)setActiveMaterial:(id)activeMaterial;
+(id)getActiveMaterial;

+(void)enter2d:(GLfloat)clipStart clipEnd:(GLfloat)clipEnd;
+(void)leave2d;
+(void)enterLandscape2d;
+(void)leaveLandscape2d;
+(void)enterLandscape3d;
+(void)leaveLandscape3d;

+(void)presentingRenderBuffer; //a debugging clarity

+(void)objectReset;
+(void)materialReset;
+(void)disableAllLamps;
+(void)disableLighting;
+(void)enableLighting;
+(void)lampSetAmbient:(SFVec*)ambientColour;

+(void)releaseActiveMaterial;

@end
