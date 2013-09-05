/*
 *  SFGL.h
 *  ZombieArcade
 *
 *  Created by Adam Iredale on 25/03/10.
 *  Copyright 2010 Stormforge Software. All rights reserved.
 *
 */

//a fast c++ version of the SFGLContext guts for the SFGLContext
//basically, all gl calls go via here so that we can cache states
//and not double-call

#ifndef SFGL_H

#include <OpenGLES/ES1/gl.h>
#include "SFObj.h"
#include "SFDefines.h"
#include "SFVec.h"

#define GL_CAP_SIZE 65535

typedef enum {
    SF_WIDGET_VBO_STD,
    SF_WIDGET_VBO_CENTER,
    SF_WIDGET_VBO_ALL
} SF_WIDGET_VBO;

class SFGL : public SFObj {
    bool _glCap[GL_CAP_SIZE]; //the set of active GL capabilities
    bool _coordArrayTextures[GL_CAP_SIZE]; //coordinate array texture activation status
    bool _texture2DTextures[GL_CAP_SIZE]; //texture2D texture activation status
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
    void *_activeMaterial;
    GLfloat _triangleCount;
    unsigned int _widgetVBOs[SF_WIDGET_VBO_ALL];
private:
    SFGL();
    ~SFGL();
    bool glTexture2DIsEnabled();
    bool glTextureCoordArrayIsEnabled();
    bool enableGlTexture2D(bool enable);
    bool enableGlTextureCoordArray(bool enable);
    bool isBuffer(GLuint buffer);
    bool isTexture(GLuint texture);
    bool frameBufferOk();
    void printCurrentMatrix();
public:
    void glGetBufferPointervOES(GLenum target, GLuint buffer, GLvoid** ptr);
    void glGetFloatv(GLenum pname, GLfloat *params);
    void glFlush();
    bool glEnable(GLenum cap);
    bool glEnableClientState(GLenum array);
    void glFinish();
    bool glDisable(GLenum cap);
    bool glDisableClientState(GLenum array);
    bool glActiveTexture(GLenum texture);
    bool glClientActiveTexture(GLenum texture);
    bool capIsEnabled(GLenum cap);
    bool glColor4f(vec4 color);
    bool glAlphaFunc(GLenum func, GLclampf ref);
    bool glTexEnvf(GLenum target, GLenum pname, GLfloat param);
    
    void glDrawWidget(GLboolean centered);
    
    bool glBindBuffer(GLenum target, GLuint buffer);
    bool glBindTexture(GLenum target, GLuint texture);
    bool glDrawElements(GLenum mode, GLsizei count, GLenum type, const GLvoid* indices);
    bool glDrawArrays(GLenum mode, GLint first, GLsizei count);
    bool glClearColor(vec4 clear);
    GLenum glCheckFramebufferStatusOES(GLenum framebuffer);
    void glBufferData(GLenum target, GLsizeiptr size, const GLvoid* data, GLenum usage);
    void glTexImage2D(GLenum target, GLint level, GLint internalformat, GLsizei width, GLsizei height,
                      GLint border, GLenum format, GLenum type, const GLvoid *pixels);
    void glTexSubImage2D(GLenum target, GLint level, GLint xoffset, GLint yoffset, GLsizei width, GLsizei height,
                         GLenum format, GLenum type, const GLvoid* pixels);
    void glTexCoordPointer(GLint size, GLenum type, GLsizei stride, const GLvoid* pointer);
    void glVertexPointer(GLint size, GLenum type, GLsizei stride, const GLvoid* pointer);
    
    void glTranslatef(GLfloat x, GLfloat y, GLfloat z);
    void glRotatef(GLfloat w, GLfloat x, GLfloat y, GLfloat z);
    void glScalef(GLfloat x, GLfloat y, GLfloat z);
    void glLightf(GLenum light, GLenum pname, GLfloat param);
    void glLightfv(GLenum light, GLenum pname, const GLfloat* params);
    void glLightModelfv(GLenum pname, const GLfloat* params);
    void glLightModelf(GLenum pname, GLfloat param);
    
    void glDeleteBuffers(GLsizei n, const GLuint* buffers);
    void glDeleteTextures(GLsizei n, const GLuint* textures);
    
    //matrix
    void glPushMatrix();
    void glPopMatrix();
    void glMatrixMode(GLenum mode);
    
    bool cachedState(GLenum cap);
    
    void* mapBuffer(GLuint buffer, GLenum target);
    void unMapBuffer(GLuint buffer, GLenum target);
                                          
    void setBlendMode(unsigned int blendMode);
    
    bool setActiveMaterial(void *activeMaterial);
    
    void enter2d(GLfloat clipStart, GLfloat clipEnd);
    void leave2d();
    void enterLandscape2d();
    void leaveLandscape2d();
    void enterLandscape3d();
    void leaveLandscape3d();
    
    void presentingRenderBuffer(); //a debugging clarity
    
    void objectReset();
    void materialReset();
    void disableAllLamps();
    void disableLighting();
    void enableLighting();
    void lampSetAmbient(const GLfloat* ambientColour);
    
    void releaseActiveMaterial();

    static SFGL *instance();
    static void startUp();
    static void shutdown();
};

#define SFGL_H
#endif