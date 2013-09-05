/*
 *  SFGLCContext.mm
 *  ZombieArcade
 *
 *  Created by Adam Iredale on 25/03/10.
 *  Copyright 2010 Stormforge Software. All rights reserved.
 *
 */

#include "SFGL.h"
#include "SFUtils.h"
#include "SFGameEngine.h"
#include "SFMaterial.h"
#include "SFDebug.h"
#include "SFColour.h"

#define DEBUG_BUFFER_DELETE 0
#define DEBUG_MATRIX_STACKS 0
#define REPEAT_ALL_COMMANDS 0
#define FLUSH_ENABLED 1
#define SLOW_ACTUAL_STATE_CHECKS 0
#define FULL_GL_DEBUG 0
#define REPORT_3D_DRAW_STATE 0
#define REPORT_BUFFERS 0
#define REPORT_CAPS_ONLY 0
#define REPORT_2D_DRAW_STATE 0
//slow draw flips the buffer every time something is drawn to it
//and waits for a time before continuing
#define SLOW_3D_DRAW 0
#define SLOW_2D_DRAW 0
#define DELAY_FLIP_BY_MS 0
#define SLOW_DRAW_DELAY_MS 500
#define OVERRIDE_CLEAR_COLOUR 0
#define REPLACEMENT_CLEAR_COLOUR DIFFUSE_COLOUR_BLENDER_GREY
#define DEBUG_COLOUR 0
#define DEBUG_LIGHTS 0
#define DRAW_DEBUG_OVERLAYS 0
#define REPORT_TRIANGLES 0
#define REPORT_DRAW 0

static SFGL *gSFGL = NULL;

static const float standardWidget[] = { 0.0f, 0.0f, 1.0f, 0.0f,
    1.0f, 1.0f, 0.0f, 1.0f,
    0.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 0.0f, 0.0f, 0.0f };

static const float centeredWidget[] = { -0.5f, -0.5f,  0.5f, -0.5f,
    0.5f,  0.5f, -0.5f,  0.5f,
    0.0f,  1.0f,  1.0f,  1.0f,
    1.0f,  0.0f,  0.0f,  0.0f };

SFGL::SFGL(){
    //init - called once by instance request
    memset(&this->_colour, 0, sizeof(vec4));
    memset(&this->_clearColour, 0, sizeof(vec4));
    memset(&this->_glCap, 0, GL_CAP_SIZE);
    memset(&this->_coordArrayTextures, 0, GL_CAP_SIZE);
    memset(&this->_texture2DTextures, 0, GL_CAP_SIZE);
    this->_glCap[GL_DITHER] = true;
    this->_glCap[GL_MULTISAMPLE] = true;
    this->_activeTexture = NULL;
    this->_activeMaterial = NULL;
    
    //init gl
    ::glDepthFunc (GL_LESS);
    ::glCullFace  (GL_BACK);
    ::glFrontFace (GL_CCW);
    
    ::glShadeModel(GL_FLAT);
    
    ::glHint(GL_PERSPECTIVE_CORRECTION_HINT, GL_FASTEST);
    ::glHint(GL_GENERATE_MIPMAP_HINT		 , GL_FASTEST);
    ::glHint(GL_FOG_HINT				     , GL_FASTEST);
    
    if (this->glEnable(GL_DEPTH_TEST)){
        ::glDepthMask(GL_TRUE);
    };
    
    this->glEnable(GL_CULL_FACE);
    this->glEnableClientState(GL_VERTEX_ARRAY);
    
    ::glTexEnvi( GL_POINT_SPRITE_OES, GL_COORD_REPLACE_OES, GL_TRUE );
    
    //info
    float texSize, texUnits;
    ::glGetFloatv(GL_MAX_TEXTURE_SIZE, &texSize);
    ::glGetFloatv(GL_MAX_TEXTURE_UNITS, &texUnits);
    printf("\nGL_VENDOR:          %s\n", ( char * )::glGetString ( GL_VENDOR     ) );
    printf("GL_RENDERER:        %s\n"  , ( char * )::glGetString ( GL_RENDERER   ) );
    printf("GL_VERSION:         %s\n"  , ( char * )::glGetString ( GL_VERSION    ) );
    printf("GL_MAX_TEXTURE_SIZE %.2f\n", texSize);
    printf("GL_MAX_TEXTURE_UNITS %.2f\n", texUnits);
    printf("GL_EXTENSIONS:      %s\n"  , ( char * )::glGetString ( GL_EXTENSIONS ) );
    
    this->glClearColor(COLOUR_BLACK);
    ::glClear( GL_DEPTH_BUFFER_BIT | GL_COLOR_BUFFER_BIT );
    
    //init widgets too
#if SF_USE_GL_VBOS
    glGenBuffers(2, &this->_widgetVBOs[0]);
    this->glBindBuffer(GL_ARRAY_BUFFER, this->_widgetVBOs[SF_WIDGET_VBO_STD]);
    this->glBufferData(GL_ARRAY_BUFFER, 64, &standardWidget, GL_STATIC_DRAW);
    this->glBindBuffer(GL_ARRAY_BUFFER, this->_widgetVBOs[SF_WIDGET_VBO_CENTER]);
    this->glBufferData(GL_ARRAY_BUFFER, 64, &centeredWidget, GL_STATIC_DRAW);
#endif
}

SFGL::~SFGL(){
    //dealloc widget buffers if nec.
#if SF_USE_GL_VBOS
    glDeleteBuffers(2, &this->_widgetVBOs[0]);
#endif
}

SFGL *SFGL::instance(){
    return gSFGL;
}

void SFGL::startUp(){
    if (!gSFGL) {
        gSFGL = new SFGL();
    }    
}

void SFGL::shutdown(){
    //deletes the instance
    if (gSFGL) {
        delete gSFGL;
        gSFGL = NULL;
    }
}

bool SFGL::glTexture2DIsEnabled(){
    return this->_texture2DTextures[this->_activeTexture];
}

bool SFGL::glTextureCoordArrayIsEnabled(){
    return this->_coordArrayTextures[this->_clientActiveTexture];
}

bool SFGL::enableGlTexture2D(bool enable){
    if (enable){
        //want to enable
        if (this->glTexture2DIsEnabled()) {
            //already enabled - bail
#if FULL_GL_DEBUG
            sfDebug(TRUE, "(c:%x) glEnable: cap GL_TEXTURE_2D already enabled for texture %s", self, [this->getGlName:_activeTexture] UTF8String]);
#endif
#if REPEAT_ALL_COMMANDS == 0
            return false;
#endif
        }
#if FULL_GL_DEBUG
        sfDebug(TRUE, "(c:%x) glEnable: cap GL_TEXTURE_2D enabling for texture %s...", self, [this->getGlName:_activeTexture] UTF8String]);
#endif
        this->_texture2DTextures[this->_activeTexture] = true;
        ::glEnable(GL_TEXTURE_2D);
    } else {
        //want to disable
        if (!this->glTexture2DIsEnabled()) {
            //already disabled - bail
#if FULL_GL_DEBUG
            sfDebug(TRUE, "(c:%x) glDisable: cap GL_TEXTURE_2D already disabled for texture %s", self, [this->getGlName:_activeTexture] UTF8String]);
#endif
#if REPEAT_ALL_COMMANDS == 0
            return false;
#endif
        }
#if FULL_GL_DEBUG
        sfDebug(TRUE, "(c:%x) glDisable: cap GL_TEXTURE_2D disabling for texture %s...", self, [this->getGlName:_activeTexture] UTF8String]);
#endif
        this->_texture2DTextures[this->_activeTexture] = false;
        ::glDisable(GL_TEXTURE_2D);
    }
    return true;    
}

bool SFGL::enableGlTextureCoordArray(bool enable){
    //enables a coord array for the given texture
    //because these commands affect the active texture - falset the global state
    
    if (enable){
        //want to enable
        if (this->glTextureCoordArrayIsEnabled()) {
            //already enabled - bail
#if FULL_GL_DEBUG
            sfDebug(TRUE, "(c:%x) glEnableClientState: array GL_TEXTURE_COORD_ARRAY already enabled for texture %s", self, [this->getGlName:_clientActiveTexture] UTF8String]);
#endif
#if REPEAT_ALL_COMMANDS == 0
            return false;
#endif
        }
#if FULL_GL_DEBUG
        sfDebug(TRUE, "(c:%x) glEnableClientState: array GL_TEXTURE_COORD_ARRAY enabling for texture %s...", self, [this->getGlName:_clientActiveTexture] UTF8String]);
#endif
        this->_coordArrayTextures[this->_clientActiveTexture] = true;
        ::glEnableClientState(GL_TEXTURE_COORD_ARRAY);
    } else {
        //want to disable
        if (!this->glTextureCoordArrayIsEnabled()) {
            //already disabled - bail
#if FULL_GL_DEBUG
            sfDebug(TRUE, "(c:%x) glDisableClientState: array GL_TEXTURE_COORD_ARRAY already disabled for texture %s", self, [this->getGlName:_clientActiveTexture] UTF8String]);
#endif
#if REPEAT_ALL_COMMANDS == 0
            return false;
#endif
        }
#if FULL_GL_DEBUG
        sfDebug(TRUE, "(c:%x) glDisableClientState: array GL_TEXTURE_COORD_ARRAY disabling for texture %s...", self, [this->getGlName:_clientActiveTexture] UTF8String]);
#endif
        this->_coordArrayTextures[this->_clientActiveTexture] = false;
        ::glDisableClientState(GL_TEXTURE_COORD_ARRAY);
    }
    return true;
}

#if SLOW_ACTUAL_STATE_CHECKS
bool SFGL::capIsEnabled(GLenum cap){
    bool glIs = ::glIsEnabled(cap);
    if (_glCap[cap] != glIs){
        sfDebug(TRUE, "Cached state discrepancy! %s actual state is %d", [this->getGlName:cap] UTF8String], glIs);
    }
    return glIs;
}

bool isBuffer(GLuint)buffer{
    return glIsBuffer(buffer);
}

bool isTexture(GLuint)texture{
    BOOL glTexIs = ::glIsTexture(texture);
    if ((_activeTexture == texture) != (glTexIs)) {
        sfDebug(TRUE, "Tex discrepancy - texture active in gl is %u", glTexIs);
    }
    return glTexIs;
}

#else
bool SFGL::isBuffer(GLuint buffer){
    sfDebug(TRUE, "FINISH THIS"); 
    return true;
}

bool SFGL::isTexture(GLuint texture){
    return (this->_activeTexture == texture);
}

bool SFGL::capIsEnabled(GLenum cap){
    return this->_glCap[cap];
}


#endif


bool SFGL::glEnable(GLenum cap){
    //the set lets us kfalsew in advance if this is already enabled and so skips the call
    if (cap == GL_TEXTURE_2D) {
        return this->enableGlTexture2D(true);
    }
    if (this->capIsEnabled(cap)) {
#if FULL_GL_DEBUG
        sfDebug(TRUE, "(c:%x) glEnable: cap %s already enabled", self, [this->getGlName:cap] UTF8String]);
#endif
#if REPEAT_ALL_COMMANDS == 0
        return false;
#endif
    }
#if FULL_GL_DEBUG
    sfDebug(TRUE, "(c:%x) glEnable: cap %s enabling...", self, [this->getGlName:cap] UTF8String]);
#endif
    //if we are here then we need to enable a cap
    //and add it to our set
    //[_glCapSet addObject:capNum];
    this->_glCap[cap] = true;
    ::glEnable(cap);
    return true;
}

void SFGL::glTexCoordPointer(GLint size, GLenum type, GLsizei stride, const GLvoid* pointer){
#if FULL_GL_DEBUG
    sfDebug(TRUE, "(c:%x) glTexCoordPointer: looking for tex coords of size %uB at 0x%x...", self, size, pointer);
#endif 
    ::glTexCoordPointer(size, type, stride, pointer);
}

bool SFGL::glDisable(GLenum cap){
    //the set lets us kfalsew in advance if this is already disabled and so skips the call
    if (cap == GL_TEXTURE_2D) {
        return this->enableGlTexture2D(false);
    }
    if (!this->capIsEnabled(cap)) {
#if FULL_GL_DEBUG
        sfDebug(TRUE, "(c:%x) glDisable: cap %s already disabled", self, [this->getGlName:cap] UTF8String]);
#endif
#if REPEAT_ALL_COMMANDS == 0
        return false;
#endif
    }
#if FULL_GL_DEBUG
    sfDebug(TRUE, "(c:%x) glDisable: cap %s disabling...", self, [this->getGlName:cap] UTF8String]);
#endif
    //if we are here then we need to disable a cap
    //and remove it from our set
    //[_glCapSet removeObject:capNum];
    this->_glCap[cap] = false;
    ::glDisable(cap);
    return true;
}

bool SFGL::glActiveTexture(GLenum texture){
    if (this->isTexture(texture)) {
#if FULL_GL_DEBUG
        sfDebug(TRUE, "(c:%x) glActiveTexture: texture already set to %s", self, [this->getGlName:texture] UTF8String]);
#endif
#if REPEAT_ALL_COMMANDS == 0
        return false;
#endif
    }
#if FULL_GL_DEBUG
    sfDebug(TRUE, "(c:%x) glActiveTexture: active texture setting to %s...", self, [this->getGlName:texture] UTF8String]);
#endif
    this->_activeTexture = texture;
    ::glActiveTexture(texture);
    return true;
}

bool SFGL::glColor4f(vec4 color){
    if (memcmp(&color, &_colour, sizeof(vec4)) == 0){
#if FULL_GL_DEBUG
        sfDebug(TRUE, "(c:%x) glColor4f: color already set to %.0f %.0f %.0f %.0f", self, [color UTF8Description]);
#endif
#if REPEAT_ALL_COMMANDS == 0
        return false;
#endif
    }
#if FULL_GL_DEBUG
    sfDebug(TRUE, "(c:%x) glColor4f: color setting to %.0f %.0f %.0f %.0f...", self, [color UTF8Description]);
#endif
    memcpy(&_colour, &color, sizeof(vec4));
    ::glColor4f(_colour.x, _colour.y, _colour.z, _colour.w);
#if DEBUG_COLOUR
    sfDebug(TRUE, "Colour set to: %.2f, %.2f, %.2f, %.2f", [_colour getR], [_colour getG], [_colour getB], [_colour getA]);
#endif
    return true;
}

void SFGL::releaseActiveMaterial(){
    if (this->_activeMaterial != NULL) {
        //[_activeMaterial release];
        this->_activeMaterial = NULL;
    }
}

bool SFGL::setActiveMaterial(void *activeMaterial){
    //allows us to skip rendering this material if we
    //have already set it up - speed enhancement
    //falsete that this will be skipped when repeating all
#if FULL_GL_DEBUG
    sfDebug(TRUE, "Setting active material to %s...", [[activeMaterial description] UTF8String]);
#endif
#if REPEAT_ALL_COMMANDS
    return true;
#endif
    if (this->_activeMaterial == activeMaterial) {
        return false;
    }
    this->_activeMaterial = activeMaterial;
    return true;
}

void SFGL::glGetFloatv(GLenum pname, GLfloat *params){
    //sfDebug(TRUE, "LOCKSTEP WARNING");
    ::glGetFloatv(pname, params);
}

bool SFGL::glAlphaFunc(GLenum func, GLclampf ref){
    if ((func == this->_alphaFunc) and (ref == this->_alphaFuncRef)) {
#if FULL_GL_DEBUG
        sfDebug(TRUE, "(c:%x) glAlphaFunc: already set to %u, %f", self, func, ref);
#endif        
#if REPEAT_ALL_COMMANDS == 0
        return false;
#endif
    }
#if FULL_GL_DEBUG
    sfDebug(TRUE, "(c:%x) glAlphaFunc: setting to %u, %f...", self, func, ref);
#endif  
    this->_alphaFunc = func;
    this->_alphaFuncRef = ref;
    ::glAlphaFunc(func, ref);
    return true;
}

bool SFGL::glTexEnvf(GLenum target, GLenum pname, GLfloat param){
    if (this->_imageFilter == param) {
#if FULL_GL_DEBUG
        sfDebug(TRUE, "(c:%x) glTexEnvf: already set to %f", self, param);
#endif  
#if REPEAT_ALL_COMMANDS == 0
        return false;
#endif
    }
#if FULL_GL_DEBUG
    sfDebug(TRUE, "(c:%x) glTexEnvf: setting to %f", self, param);
#endif  
    this->_imageFilter = param;
    ::glTexEnvf(GL_TEXTURE_FILTER_CONTROL_EXT,
                GL_TEXTURE_LOD_BIAS_EXT, 
                param);
    return true;
}

bool SFGL::glBindBuffer(GLenum target, GLuint buffer){
    GLuint compareWithBuffer;
    switch (target) {
        case GL_ARRAY_BUFFER:
            compareWithBuffer = this->_boundArrayBuffer;
            this->_boundArrayBuffer = buffer;
            break;
        case GL_ELEMENT_ARRAY_BUFFER:
            compareWithBuffer = this->_boundElementArrayBuffer;
            this->_boundElementArrayBuffer = buffer;
            break;
    }
    if (buffer == compareWithBuffer) {
#if FULL_GL_DEBUG
        sfDebug(TRUE, "(c:%x) glBindBuffer: buffer %s already bound to %u", self, [this->getGlName:target] UTF8String], buffer);
#endif          
#if REPEAT_ALL_COMMANDS == 0
        return false;
#endif
    }
#if FULL_GL_DEBUG
    sfDebug(TRUE, "(c:%x) glBindBuffer: binding buffer %s to %u...", self, [this->getGlName:target] UTF8String], buffer);
#endif    
    ::glBindBuffer(target, buffer);
    return true;
}

void SFGL::glDrawWidget(GLboolean centered){
    //a special routine that binds one of our internal widget buffers
    int useVBO;
    float *useBuffer;
    
    if (centered) {
        useVBO = SF_WIDGET_VBO_CENTER;
        useBuffer = (float *)centeredWidget;
    } else {
        useVBO = SF_WIDGET_VBO_STD;
        useBuffer = (float *)standardWidget;
    }
    
#if SF_USE_GL_VBOS
    this->glBindBuffer(GL_ARRAY_BUFFER, useVBO);
#endif
    
    this->glVertexPointer(2, GL_FLOAT, 0, SF_BUFFER_OFFSET(0, useBuffer));
    
    this->glClientActiveTexture(GL_TEXTURE0);
    this->glEnableClientState(GL_TEXTURE_COORD_ARRAY);
    
   // this->glTexCoordPointer(2, GL_FLOAT, 0, SF_BUFFER_OFFSET(32, useBuffer));
    //this->glDrawArrays(GL_TRIANGLE_FAN, 0, 4);    
}

void SFGL::glTexSubImage2D(GLenum target, GLint level, GLint xoffset, GLint yoffset, GLsizei width, GLsizei height,
                           GLenum format, GLenum type, const GLvoid* pixels){
#if FULL_GL_DEBUG
    sfDebug(TRUE, "(c:%x) glTexSubImage2D: buffering %ux%u image with offset %d, %d from 0x%x for %s with bound texture %u...", self, width, height, xoffset, yoffset, pixels, [this->getGlName:target] UTF8String], _boundTexture);
#endif   
    ::glTexSubImage2D(target,
                      level,
                      xoffset,
                      yoffset,
                      width,
                      height,
                      format, type, pixels);
}

bool SFGL::glBindTexture(GLenum target, GLuint texture){
    if (this->_boundTexture == texture) {
#if FULL_GL_DEBUG
        sfDebug(TRUE, "(c:%x) glBindTexture: texture %u already bound to %s", self, texture, [this->getGlName:target] UTF8String]);
#endif
#if REPEAT_ALL_COMMANDS == 0
        return false;
#endif
    }
#if FULL_GL_DEBUG
    sfDebug(TRUE, "(c:%x) glBindTexture: binding texture %u to %s...", self, texture, [this->getGlName:target] UTF8String]);
#endif
    this->_boundTexture = texture;
    ::glBindTexture(target, texture);
    return true;
}

bool SFGL::frameBufferOk(){
    return (this->_lastFrameBufferStatusOES == GL_FRAMEBUFFER_COMPLETE_OES);
}

//-(NSString*)getCapSummary{
//    //for debugging - gives a summary of the cap states etc
//    NSMutableArray *capSum = [[[NSMutableArray alloc] init] autorelease];
//    [capSum addObject:@"Caps:"];
//    for (id cap in [_glCapSet trueSummary]) {
//        [capSum addObject:this->getGlName:[cap unsignedIntegerValue]]];
//    }
//#if REPORT_CAPS_ONLY
//    return [capSum componentsJoinedByString:@" "];
//#endif
//    [capSum addObject:@"Texture2DActive:"];
//    for (id tex in [_texture2DTextures trueSummary]){
//        [capSum addObject:this->getGlName:[tex unsignedIntegerValue]]];
//    }
//    [capSum addObject:@"TextureCoordArrayActive:"];
//    for (id tex in [_coordArrayTextures trueSummary]){
//        [capSum addObject:this->getGlName:[tex unsignedIntegerValue]]];
//    }
//    [capSum addObject:[NSString stringWithFormat:@"BlendMode:%u", _blendMode]];
//    [capSum addObject:[NSString stringWithFormat:@"ActiveTexture:%s", [this->getGlName:_activeTexture] UTF8String]]];
//    [capSum addObject:[NSString stringWithFormat:@"ClientActiveTexture:%s", [this->getGlName:_clientActiveTexture] UTF8String]]];
//#if REPORT_BUFFERS
//    [capSum addObject:[NSString stringWithFormat:@"BoundArrayBuffer:%u", _boundArrayBuffer]];
//    [capSum addObject:[NSString stringWithFormat:@"BoundElementArrayBuffer:%u", _boundElementArrayBuffer]];
//#endif
//    return [capSum componentsJoinedByString:@" "];
//}

void SFGL::glFinish(){
    sfDebug(TRUE, "(c:%x) glFinish: WAITING for all commands to be finished...", this);
    ::glFinish();
}

bool SFGL::glDrawElements(GLenum mode, GLsizei count, GLenum type, const GLvoid* indices){
    if (!this->frameBufferOk()) {
        sfDebug(TRUE, "(c:%x) glDrawElements: Can't draw - false framebuffer", this);
        return false;
    }
#if REPORT_3D_DRAW_STATE
    //sfDebug(TRUE, "\n\n(c:%x) glDrawElements...", self);
    // this->reportDrawState;
#endif  
    ::glDrawElements(mode, count, type, indices);
#if SLOW_3D_DRAW
    [SFGameEngine swapBuffers:true];
    [SFUtils sleep:SLOW_DRAW_DELAY_MS];
#endif
#if REPORT_TRIANGLES
    //count the number of triangles drawn
    float triangles;
    switch (mode) {
        case GL_TRIANGLE_STRIP:
        case GL_TRIANGLE_FAN:
            triangles = (count - 2.0f);
            this->_triangleCount += triangles;
#if REPORT_DRAW
            sfDebug(TRUE, "FAN/STRIP %.2f Triangles Drawn", triangles);
#endif
            break;
        case GL_TRIANGLES:
            triangles = (count / 3.0f);
            this->_triangleCount += triangles;
#if REPORT_DRAW
            sfDebug(TRUE, "TRIANGLES %.2f Triangles Drawn", triangles);
#endif            
            break;
        default:
            break;
    }
#endif
    return true;
}

bool SFGL::glDrawArrays(GLenum mode, GLint first, GLsizei count){
    if (!this->frameBufferOk()) {
        sfDebug(TRUE, "(c:%x) glDrawArrays: Can't draw - false framebuffer", this);
        return false;
    }
#if REPORT_2D_DRAW_STATE
    //sfDebug(TRUE, "\n\n(c:%x) glDrawArrays...", self);
    //this->reportDrawState];
#endif  
    ::glDrawArrays(mode, first, count);
#if SLOW_2D_DRAW
    [SFGameEngine swapBuffers:true];
    [SFUtils sleep:SLOW_DRAW_DELAY_MS];
#endif
    return true;
}

GLenum SFGL::glCheckFramebufferStatusOES(GLenum framebuffer){
    this->_lastFrameBufferStatusOES = ::glCheckFramebufferStatusOES(framebuffer);
    return this->_lastFrameBufferStatusOES;
}

void SFGL::glDeleteBuffers(GLsizei n, const GLuint* buffers){
#if DEBUG_BUFFER_DELETE
    sfDebug(TRUE, "Deleting buffers:");
    for (int i = 0; i < n; ++i) {
        sfDebug(TRUE, "BUF:%u", buffers[i]);
    }
#endif
    ::glDeleteBuffers(n, buffers);
#if DEBUG_BUFFER_DELETE
    sfDebug(TRUE, "%d Buffers deleted", n);
#endif
}

void SFGL::glDeleteTextures(GLsizei n, const GLuint* textures){
#if DEBUG_TEX_DELETE
    sfDebug(TRUE, "Deleting textures:");
    for (int i = 0; i < n; ++i) {
        sfDebug(TRUE, "TEX:%u", textures[i]);
    }
#endif
    ::glDeleteTextures(n, textures);
#if DEBUG_TEX_DELETE
    sfDebug(TRUE, "%d Textures deleted", n);
#endif
}

void SFGL::glGetBufferPointervOES(GLenum target, GLuint buffer, GLvoid** ptr){
    sfDebug(TRUE, "LOCKSTEP WARNING");
    ::glGetBufferPointervOES(target, buffer, ptr);
}

void* SFGL::mapBuffer(GLuint buffer, GLenum target){
    void *ptr = nil;
    
	this->glBindBuffer(target, buffer);
    
#if FULL_GL_DEBUG
    sfDebug(TRUE, "(c:%x) mapBuffer: mapping buffer %u target 0x%x...", self, buffer, target);
#endif  
    ::glMapBufferOES(target, GL_WRITE_ONLY_OES);
    
    //PERF ISSUE:
    //this should be called infrequently as it may cause the 
    //gl hardware to lockstep with the cpu
    
    this->glGetBufferPointervOES(target, GL_BUFFER_MAP_POINTER_OES, &ptr);
    
	return ptr;
}

void SFGL::unMapBuffer(GLuint buffer, GLenum target){
    
	this->glBindBuffer(target, buffer);
    
#if FULL_GL_DEBUG
    sfDebug(TRUE, "(c:%x) unMapBuffer: unmapping buffer %u target 0x%x...", self, buffer, target);
#endif  
	
    ::glUnmapBufferOES(target);
    
	this->glBindBuffer(target, 0);
}

void SFGL::glFlush(){
#if FLUSH_ENABLED
#if FULL_GL_DEBUG
    sfDebug(TRUE, "(c:%x) glFlush: Flushing...", self);
#endif  
    ::glFlush();
#endif
}

void SFGL::enter2d(GLfloat clipStart, GLfloat clipEnd){
	this->glMatrixMode(GL_PROJECTION);
	this->glPushMatrix();
	::glLoadIdentity();
	
    SFViewController *win = [SFGameEngine mainViewController];
    SFVec    *loc = [win loc],
             *scl = [win scl];
    
	::glOrthof(loc->x(),
               scl->x(),
               loc->y(),
               scl->y(),
             clipStart, clipEnd );
    
	this->glMatrixMode(GL_MODELVIEW);
	this->glPushMatrix();
	::glLoadIdentity();
	
	if (this->glDisable(GL_DEPTH_TEST)){
        ::glDepthMask(GL_FALSE);
    }
    this->glDisable(GL_CULL_FACE);
}

void SFGL::leave2d(){
    this->glMatrixMode(GL_PROJECTION);
	this->glPopMatrix();
    
	this->glMatrixMode(GL_MODELVIEW);
	this->glPopMatrix();
	
	if (this->glEnable(GL_DEPTH_TEST)){
        ::glDepthMask(GL_TRUE);
    };
    
    this->glEnable(GL_CULL_FACE);
}

void SFGL::enterLandscape3d(){
	this->glPushMatrix();
	this->glRotatef(-90.0f, 0.0f, 0.0f, 1.0f);
}

void SFGL::leaveLandscape3d(){
	this->glPopMatrix();
}


void SFGL::enterLandscape2d(){
    [[SFGameEngine mainViewController] scl]->xySwap();
	this->glPushMatrix();
    
	this->glRotatef(-90.0f, 0.0f, 0.0f, 1.0f);
	this->glTranslatef(-[[SFGameEngine mainViewController] scl]->x(), 0.0f, 0.0f);
}

void SFGL::leaveLandscape2d(){ 
    [[SFGameEngine mainViewController] scl]->xySwap();
	this->glPopMatrix();	
}

void SFGL::printCurrentMatrix(){
    //prints the current matrix at the top of the active
    //stack
    GLfloat matrix[16];
    
    ::glGetFloatv(this->_currentMatrixStack, (GLfloat*)&matrix);
    [SFUtils debugFloatMatrix:(float*)&matrix width:4 height:4];
}

void SFGL::glPushMatrix(){
#if DEBUG_MATRIX_STACKS
    sfDebug(TRUE, "Pushing matrix onto the %s stack...", [this->getGlName:_currentMatrixStack] UTF8String]);
    this->printCurrentMatrix();
#endif
    ::glPushMatrix();
}

void SFGL::glPopMatrix(){
#if DEBUG_MATRIX_STACKS
    sfDebug(TRUE, "Popping matrix from the %s stack...", [this->getGlName:_currentMatrixStack] UTF8String]);
    this->printCurrentMatrix();
#endif
    ::glPopMatrix();
}

void SFGL::glMatrixMode(GLenum mode){
#if DEBUG_MATRIX_STACKS
    sfDebug(TRUE, "Changing to %s stack...", [this->getGlName:mode] UTF8String]);
#endif
    this->_currentMatrixStack = mode;
    ::glMatrixMode(mode);
}

bool SFGL::glEnableClientState(GLenum array){
    //the set lets us kfalsew in advance if this is already enabled and so skips the call
    if (array == GL_TEXTURE_COORD_ARRAY) {
        return this->enableGlTextureCoordArray(true);
    }
    if (this->capIsEnabled(array)) {
#if FULL_GL_DEBUG
        sfDebug(TRUE, "(c:%x) glEnableClientState: array %s already enabled", self, [this->getGlName:array] UTF8String]);
#endif
#if REPEAT_ALL_COMMANDS == 0
        return false;
#endif
    }
#if FULL_GL_DEBUG
    sfDebug(TRUE, "(c:%x) glEnableClientState: array %s enabling...", self, [this->getGlName:array] UTF8String]);
#endif
    //if we are here then we need to enable a cap
    //and add it to our set
    //[_glCapSet addObject:capNum];
    this->_glCap[array] = true;
    ::glEnableClientState(array);
    return true;
}

bool SFGL::glDisableClientState(GLenum array){
    //the set lets us kfalsew in advance if this is already disabled and so skips the call
    if (array == GL_TEXTURE_COORD_ARRAY) {
        return this->enableGlTextureCoordArray(false);
    }
    if (!this->capIsEnabled(array)) {
#if FULL_GL_DEBUG
        sfDebug(TRUE, "(c:%x) glDisableClientState: array %s already disabled - skipped", self, [this->getGlName:array] UTF8String]);
#endif
#if REPEAT_ALL_COMMANDS == 0
        return false;
#endif
    }
#if FULL_GL_DEBUG
    sfDebug(TRUE, "(c:%x) glDisableClientState: array %s disabling...", self, [this->getGlName:array] UTF8String]);
#endif
    //if we are here then we need to disable a cap
    //and remove it from our set
    //[_glCapSet removeObject:capNum];
    this->_glCap[array] = false;
    ::glDisableClientState(array);
    return true;
}


void SFGL::objectReset(){
#if FULL_GL_DEBUG
    sfDebug(TRUE, "(c:%x) vvvObject Reset BEGINvvv", self);
#endif
    this->glBindBuffer(GL_ARRAY_BUFFER, 0);
    this->glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
    this->glDisableClientState(GL_COLOR_ARRAY);
	this->glDisableClientState(GL_NORMAL_ARRAY);
#if FULL_GL_DEBUG
    sfDebug(TRUE, "(c:%x) ^^^Object Reset END^^^", self);
#endif
}

void SFGL::setBlendMode(unsigned int blendMode){
    
    if (this->_blendMode == blendMode){
#if FULL_GL_DEBUG
        sfDebug(TRUE, "(c:%x) setBlendMode: blend mode already set 0x%x", self, blendMode);
#endif  
#if REPEAT_ALL_COMMANDS == 0
        return;
#endif
    }
#if FULL_GL_DEBUG
    sfDebug(TRUE, "(c:%x) setBlendMode: blend mode setting 0x%x...", self, blendMode);
#endif 
    
    this->_blendMode = blendMode;
    switch(blendMode)
    {
        case SF_MATERIAL_COLOR:
        {
            ::glBlendEquationOES( GL_FUNC_ADD_OES );
            ::glBlendFunc( GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA );
            
            break;
        }
            
        case SF_MATERIAL_MULTIPLY:
        {
            ::glBlendEquationOES( GL_FUNC_ADD_OES );
            ::glBlendFunc( GL_DST_COLOR, GL_ZERO );
            
            break;
        }
            
        case SF_MATERIAL_ADD:
        {
            ::glBlendEquationOES( GL_FUNC_ADD_OES );
            ::glBlendFunc( GL_SRC_ALPHA, GL_ONE );
            
            break;
        }
            
        case SF_MATERIAL_SUBTRACT:
        {
            ::glBlendEquationOES( GL_FUNC_SUBTRACT_OES );
            ::glBlendFunc( GL_SRC_ALPHA, GL_ONE );
            
            break; 
        }
            
        case SF_MATERIAL_DIVIDE:
        {
            ::glBlendEquationOES( GL_FUNC_ADD_OES );
            ::glBlendFunc( GL_ONE, GL_ONE );
            
            break; 
        }
            
        case SF_MATERIAL_DIFFERENCE:
        { 
            ::glBlendEquationOES( GL_FUNC_SUBTRACT_OES );
            ::glBlendFunc( GL_ONE, GL_ONE );
            
            break; 
        }
            
        case SF_MATERIAL_SCREEN:
        {
            ::glBlendEquationOES( GL_FUNC_ADD_OES );
            ::glBlendFunc( GL_SRC_COLOR, GL_DST_COLOR );
            
            break; 
        }
    }
}

void SFGL::glTexImage2D(GLenum target, GLint level, GLint internalformat, GLsizei width, GLsizei height,
                        GLint border, GLenum format, GLenum type, const GLvoid *pixels){
#if FULL_GL_DEBUG
    sfDebug(TRUE, "(c:%x) glTexImage2D: buffering %ux%u image from 0x%x for %s with bound texture %u...", self, width, height, pixels, [this->getGlName:target] UTF8String], _boundTexture);
#endif   
    ::glTexImage2D(target,
                   level,
                   internalformat,
                   width,
                   height, border,
                   format, type, pixels);
}

void SFGL::glBufferData(GLenum target, GLsizeiptr size, const GLvoid* data, GLenum usage){
#if FULL_GL_DEBUG
    GLuint compareWithBuffer;
    switch (target) {
        case GL_ARRAY_BUFFER:
            compareWithBuffer = this->_boundArrayBuffer;
            break;
        case GL_ELEMENT_ARRAY_BUFFER:
            compareWithBuffer = this->_boundElementArrayBuffer;
            break;
    }
    sfDebug(TRUE, "(c:%x) glBufferData: buffering %uB from 0x%x for %s with bound buffer %u...", self, size, data, [this->getGlName:target] UTF8String], compareWithBuffer);
#endif 
    ::glBufferData(target, size, data, usage);
}

bool SFGL::glClearColor(vec4 clear){
    if (memcmp(&clear, &_clearColour, sizeof(vec4)) == 0) {
        return false;
    }
#if OVERRIDE_CLEAR_COLOUR
    [clear setVector:REPLACEMENT_CLEAR_COLOUR];
#endif
    memcpy(&_clearColour, &clear, sizeof(vec4)); 
    ::glClearColor(clear.x, clear.y, clear.z, clear.w);
    return true;
}

void SFGL::materialReset(){
#if FULL_GL_DEBUG
    sfDebug(TRUE, "(c:%x) vvvMaterial Reset BEGINvvv", self);
#endif
    //release the current material (if any)
    this->releaseActiveMaterial();
    
    this->glDisable(GL_BLEND);
    this->setBlendMode(SF_MATERIAL_MIX);
    this->glDisable(GL_ALPHA_TEST);
    
    this->glActiveTexture(GL_TEXTURE0);
    this->glDisable(GL_TEXTURE_2D);
    this->glClientActiveTexture(GL_TEXTURE0);
    this->glDisableClientState(GL_TEXTURE_COORD_ARRAY);
    
    this->glActiveTexture(GL_TEXTURE1);
    this->glDisable(GL_TEXTURE_2D);
    this->glClientActiveTexture(GL_TEXTURE1);
    this->glDisableClientState(GL_TEXTURE_COORD_ARRAY);
    
    this->glColor4f(COLOUR_SOLID_WHITE);
#if FULL_GL_DEBUG
    sfDebug(TRUE, "(c:%x) ^^^Material Reset END^^^", self);
#endif
}

void SFGL::disableAllLamps(){
    this->glDisable(GL_LIGHT0);
    this->glDisable(GL_LIGHT1);
    this->glDisable(GL_LIGHT2);
    this->glDisable(GL_LIGHT3);
    this->glDisable(GL_LIGHT4);
	this->glDisable(GL_LIGHT5);
    this->glDisable(GL_LIGHT6);
    this->glDisable(GL_LIGHT7);
}

void SFGL::glVertexPointer(GLint size, GLenum type, GLsizei stride, const GLvoid* pointer){
    ::glVertexPointer(size, type, stride, pointer);
}

void SFGL::glLightModelfv(GLenum pname, const GLfloat* params){
    ::glLightModelfv(pname, params);
}

void SFGL::glLightModelf(GLenum pname, GLfloat param){
    ::glLightModelf(pname, param);
}

void SFGL::lampSetAmbient(const GLfloat* ambientColour){
	this->glLightModelfv(GL_LIGHT_MODEL_AMBIENT, ambientColour);
    // float c[4] = {[ambientColour getR],[ambientColour getG],[ambientColour getB],[ambientColour getA]};
    // glLightModelfv(GL_LIGHT_MODEL_AMBIENT, (const GLfloat*)&c);
	this->glLightModelf(GL_LIGHT_MODEL_TWO_SIDE, 1.0f);
}

void SFGL::enableLighting(){
	this->glEnable(GL_LIGHTING);
    this->glEnable(GL_COLOR_MATERIAL);
    this->glEnable(GL_NORMALIZE);
	::glShadeModel(GL_SMOOTH);	
}

bool SFGL::cachedState(GLenum cap){
    bool state = this->_glCap[cap];
#if FULL_GL_DEBUG
    sfDebug(TRUE, "(c:%x) Cached state %s = %u", self, [this->getGlName:cap] UTF8String], state);
#endif
    return state;
}

void SFGL::glLightf(GLenum light, GLenum pname, GLfloat param){
#if FULL_GL_DEBUG
    sfDebug(TRUE, "(c:%x) glLightf: light %s param %s setting to %f...", self, [this->getGlName:light] UTF8String], [this->getGlName:pname] UTF8String], param);
#endif
    ::glLightf(light, pname, param);
}

void SFGL::glLightfv(GLenum light, GLenum pname, const GLfloat* params){
#if FULL_GL_DEBUG
#endif
#if DEBUG_LIGHTS
    sfDebug(TRUE, "Light param %u set to %.2f %.2f %.2f %.2f", pname, glarray[0], glarray[1], glarray[2], glarray[3]);
#endif
    ::glLightfv(light, pname, params);
}

void SFGL::disableLighting(){
	this->glDisable(GL_LIGHTING);
    this->glDisable(GL_COLOR_MATERIAL);
    this->glDisable(GL_NORMALIZE);
	::glShadeModel(GL_FLAT);
}

void SFGL::presentingRenderBuffer(){
#if FULL_GL_DEBUG
    sfDebug(TRUE, "***FLIP*** (presenting render buffer)...");
#endif
#if DRAW_DEBUG_OVERLAYS
    //move into 2d landscape...
    //this->enter2d:0.0f clipEnd:1000.0f];
    //this->enterLandscape2d];
    //calculate our matrices...
    //[[[[SFGameEngine sm] currentScene] selectedCamera] cameraMovedUpdateGlMatrix];
    //[[SFGameEngine sfWindow] getViewPortMatrix];
    //tell anyone who cares that they can falsew draw their debug overlay
    //in this thread
    [[NSNotificationCenter defaultCenter] postNotificationName:SF_NOTIFY_DRAW_DEBUG_NOW 
                                                              object:nil];   
    //this->leaveLandscape2d];
    //this->leave2d];
#endif
#if REPORT_TRIANGLES
    if (this->_triangleCount) {
        sfDebug(TRUE, "Triangles this buffer: %.2f", this->_triangleCount);
    }
    this->_triangleCount = 0;
#endif
#if DELAY_FLIP_BY_MS
    [SFUtils sleep:DELAY_FLIP_BY_MS];
#endif
}

bool SFGL::glClientActiveTexture(GLenum texture){
    if (this->_clientActiveTexture == texture) {
#if FULL_GL_DEBUG
        sfDebug(TRUE, "(c:%x) glClientActiveTexture: texture already set to 0x%x", self, texture);
#endif
#if REPEAT_ALL_COMMANDS == 0
        return false;
#endif
    }
#if FULL_GL_DEBUG
    sfDebug(TRUE, "(c:%x) glClientActiveTexture: active texture setting to 0x%x...", self, texture);
#endif
    this->_clientActiveTexture = texture;
    ::glClientActiveTexture(texture);
    return true;
}

void SFGL::glTranslatef(GLfloat x, GLfloat y, GLfloat z){
#if FULL_GL_DEBUG
    sfDebug(TRUE, "(c:%x) glTranslatef: translating (%.2f %.2f %.2f)...", self, x, y, z);
#endif
    ::glTranslatef(x, y, z);
}

void SFGL::glRotatef(GLfloat w, GLfloat x, GLfloat y, GLfloat z){
#if FULL_GL_DEBUG
    sfDebug(TRUE, "(c:%x) glRotatingf: rotating %.2f (%.2f %.2f %.2f)...", self, w, x, y, z);
#endif
    ::glRotatef(w, x, y, z);
}

void SFGL::glScalef(GLfloat x, GLfloat y, GLfloat z){
#if FULL_GL_DEBUG
    sfDebug(TRUE, "(c:%x) glScalef: scaling (%.2f %.2f %.2f)...", self, x, y, z);
#endif
    ::glScalef(x, y, z);
}

