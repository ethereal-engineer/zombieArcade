//
//  SFGLContext.m
//  ZombieArcade
//
//  Created by Adam Iredale on 16/02/10.
//  Copyright 2010 Stormforge Software. All rights reserved.
//

#import "SFGL.h"
#import "SFUtils.h"
#import "SFGameEngine.h"
#import "SFDebug.h"

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
#define SLOW_DRAW_DELAY_MS 50
#define OVERRIDE_CLEAR_COLOUR 0
#define REPLACEMENT_CLEAR_COLOUR DIFFUSE_COLOUR_BLENDER_GREY
#define DEBUG_COLOUR 0
#define DEBUG_LIGHTS 0
#define DRAW_DEBUG_OVERLAYS 0

#if DEBUG_SFGLCONTEXT
//for debugging
static const NSDictionary *GL_NAME = [[NSDictionary alloc ] initWithObjectsAndKeys:@"GL_FOG",[[NSNumber alloc] initWithUnsignedInt:GL_FOG],
                                      @"GL_DEPTH_TEST",[[NSNumber alloc] initWithUnsignedInt:GL_DEPTH_TEST],
                                      @"GL_LIGHTING",[[NSNumber alloc] initWithUnsignedInt:GL_LIGHTING],
                                      @"GL_TEXTURE_2D",[[NSNumber alloc] initWithUnsignedInt:GL_TEXTURE_2D],
                                      @"GL_CULL_FACE",[[NSNumber alloc] initWithUnsignedInt:GL_CULL_FACE],
                                      @"GL_ALPHA_TEST",[[NSNumber alloc] initWithUnsignedInt:GL_ALPHA_TEST],
                                      @"GL_BLEND",[[NSNumber alloc] initWithUnsignedInt:GL_BLEND],
                                      @"GL_COLOR_LOGIC_OP",[[NSNumber alloc] initWithUnsignedInt:GL_COLOR_LOGIC_OP],
                                      @"GL_DITHER",[[NSNumber alloc] initWithUnsignedInt:GL_DITHER],
                                      @"GL_STENCIL_TEST",[[NSNumber alloc] initWithUnsignedInt:GL_STENCIL_TEST],
                                      @"GL_POINT_SMOOTH",[[NSNumber alloc] initWithUnsignedInt:GL_POINT_SMOOTH],
                                      @"GL_LINE_SMOOTH",[[NSNumber alloc] initWithUnsignedInt:GL_LINE_SMOOTH],
                                      @"GL_SCISSOR_TEST",[[NSNumber alloc] initWithUnsignedInt:GL_SCISSOR_TEST],
                                      @"GL_COLOR_MATERIAL",[[NSNumber alloc] initWithUnsignedInt:GL_COLOR_MATERIAL],
                                      @"GL_NORMALIZE",[[NSNumber alloc] initWithUnsignedInt:GL_NORMALIZE],
                                      @"GL_RESCALE_NORMAL",[[NSNumber alloc] initWithUnsignedInt:GL_RESCALE_NORMAL],
                                      @"GL_POLYGON_OFFSET_FILL",[[NSNumber alloc] initWithUnsignedInt:GL_POLYGON_OFFSET_FILL],
                                      @"GL_VERTEX_ARRAY",[[NSNumber alloc] initWithUnsignedInt:GL_VERTEX_ARRAY],
                                      @"GL_NORMAL_ARRAY",[[NSNumber alloc] initWithUnsignedInt:GL_NORMAL_ARRAY],
                                      @"GL_COLOR_ARRAY",[[NSNumber alloc] initWithUnsignedInt:GL_COLOR_ARRAY],
                                      @"GL_TEXTURE_COORD_ARRAY",[[NSNumber alloc] initWithUnsignedInt:GL_TEXTURE_COORD_ARRAY],
                                      @"GL_MULTISAMPLE",[[NSNumber alloc] initWithUnsignedInt:GL_MULTISAMPLE],
                                      @"GL_SAMPLE_ALPHA_TO_COVERAGE",[[NSNumber alloc] initWithUnsignedInt:GL_SAMPLE_ALPHA_TO_COVERAGE],
                                      @"GL_SAMPLE_ALPHA_TO_ONE",[[NSNumber alloc] initWithUnsignedInt:GL_SAMPLE_ALPHA_TO_ONE],
                                      @"GL_SAMPLE_COVERAGE",[[NSNumber alloc] initWithUnsignedInt:GL_SAMPLE_COVERAGE],
                                      @"GL_ARRAY_BUFFER",[[NSNumber alloc] initWithUnsignedInt:GL_ARRAY_BUFFER],
                                      @"GL_ELEMENT_ARRAY_BUFFER",[[NSNumber alloc] initWithUnsignedInt:GL_ELEMENT_ARRAY_BUFFER],
                                      @"GL_TEXTURE0",[[NSNumber alloc] initWithUnsignedInt:GL_TEXTURE0],
                                      @"GL_TEXTURE1",[[NSNumber alloc] initWithUnsignedInt:GL_TEXTURE1],
                                      @"GL_LIGHT0", [[NSNumber alloc] initWithUnsignedInt:GL_LIGHT0],
                                      @"GL_LIGHT1", [[NSNumber alloc] initWithUnsignedInt:GL_LIGHT1],
                                      @"GL_LIGHT2", [[NSNumber alloc] initWithUnsignedInt:GL_LIGHT2],
                                      @"GL_LIGHT3", [[NSNumber alloc] initWithUnsignedInt:GL_LIGHT3],
                                      @"GL_LIGHT4", [[NSNumber alloc] initWithUnsignedInt:GL_LIGHT4],
                                      @"GL_LIGHT5", [[NSNumber alloc] initWithUnsignedInt:GL_LIGHT5],
                                      @"GL_LIGHT6", [[NSNumber alloc] initWithUnsignedInt:GL_LIGHT6],
                                      @"GL_LIGHT7", [[NSNumber alloc] initWithUnsignedInt:GL_LIGHT7],
                                      @"GL_AMBIENT", [[NSNumber alloc] initWithUnsignedInt:GL_AMBIENT],
                                      @"GL_DIFFUSE", [[NSNumber alloc] initWithUnsignedInt:GL_DIFFUSE],
                                      @"GL_SPECULAR", [[NSNumber alloc] initWithUnsignedInt:GL_SPECULAR],
                                      @"GL_POSITION", [[NSNumber alloc] initWithUnsignedInt:GL_POSITION],
                                      @"GL_SPOT_DIRECTION", [[NSNumber alloc] initWithUnsignedInt:GL_SPOT_DIRECTION],
                                      @"GL_SPOT_EXPONENT", [[NSNumber alloc] initWithUnsignedInt:GL_SPOT_EXPONENT],
                                      @"GL_SPOT_CUTOFF", [[NSNumber alloc] initWithUnsignedInt:GL_SPOT_CUTOFF],
                                      @"GL_CONSTANT_ATTENUATION", [[NSNumber alloc] initWithUnsignedInt:GL_CONSTANT_ATTENUATION],
                                      @"GL_LINEAR_ATTENUATION", [[NSNumber alloc] initWithUnsignedInt:GL_LINEAR_ATTENUATION],
                                      @"GL_QUADRATIC_ATTENUATION", [[NSNumber alloc] initWithUnsignedInt:GL_QUADRATIC_ATTENUATION],
                                      @"GL_MODELVIEW", [[NSNumber alloc] initWithUnsignedInt:GL_MODELVIEW],
                                      @"GL_PROJECTION", [[NSNumber alloc] initWithUnsignedInt:GL_PROJECTION], nil];
#endif

#if REPORT_3D_DRAW_STATE
NSString *gLastReport;
#endif

@implementation SFGLContext

-(id)initWithAPI:(EAGLRenderingAPI)api sharegroup:(EAGLSharegroup*)sharegroup{
    self = [super initWithAPI:api sharegroup:sharegroup];
    if (self != nil){
        _glCapSet = [[SFGLSet alloc] init];
        _coordArrayTextures = [[SFGLSet alloc] init];
        _texture2DTextures = [[SFGLSet alloc] init];
#if FULL_GL_DEBUG
        for (NSNumber *glnum in GL_NAME) {
            sfDebug(TRUE, "Cap: %s (0x%x)", [[self getGlName:[glnum unsignedIntValue]] UTF8String], [glnum unsignedIntValue]);
        }
#endif
        [self setInitialStates];        
    }
    return self;
}
#if REPORT_3D_DRAW_STATE
-(void)reportDrawState{
    NSString *newDrawState = [NSString stringWithFormat:@"\n\nDRAW STATE: {%s}\n\n", [[self getCapSummary] UTF8String]];
    if ((!gLastReport) or ![newDrawState isEqualToString:gLastReport]) {
        sfDebug(TRUE, "%s",[newDrawState UTF8String]);
        [gLastReport release];
        gLastReport = [newDrawState retain];
    }
}
#endif

#if DEBUG_SFGLCONTEXT
-(NSString*)getGlName:(GLenum)cap{
    return [GL_NAME objectForKey:[NSNumber numberWithUnsignedInt:cap]];
}
#endif


-(void)setInitialStates{
    [_glCapSet setState:GL_DITHER state:YES];
    [_glCapSet setState:GL_MULTISAMPLE state:YES];
}

-(BOOL)getGlTexture2DState:(GLuint)texture{
    return [_texture2DTextures getState:texture];
}

-(BOOL)getGlTextureCoordArrayState:(GLuint)texture{
    return [_coordArrayTextures getState:texture];
}

-(BOOL)enableGlTexture2D:(BOOL)enable{
    //enables a coord array for the given texture
    //because these commands affect the active texture - not the global state
    
    if (enable){
        //want to enable
        if ([self getGlTexture2DState:_activeTexture]) {
            //already enabled - bail
#if FULL_GL_DEBUG
            sfDebug(TRUE, "(c:%x) glEnable: cap GL_TEXTURE_2D already enabled for texture %s", self, [[self getGlName:_activeTexture] UTF8String]);
#endif
#if REPEAT_ALL_COMMANDS == 0
            return NO;
#endif
        }
#if FULL_GL_DEBUG
        sfDebug(TRUE, "(c:%x) glEnable: cap GL_TEXTURE_2D enabling for texture %s...", self, [[self getGlName:_activeTexture] UTF8String]);
#endif
        [_texture2DTextures setState:_activeTexture state:YES];
        glEnable(GL_TEXTURE_2D);
    } else {
        //want to disable
        if (![self getGlTexture2DState:_activeTexture]) {
            //already disabled - bail
#if FULL_GL_DEBUG
            sfDebug(TRUE, "(c:%x) glDisable: cap GL_TEXTURE_2D already disabled for texture %s", self, [[self getGlName:_activeTexture] UTF8String]);
#endif
#if REPEAT_ALL_COMMANDS == 0
            return NO;
#endif
        }
#if FULL_GL_DEBUG
        sfDebug(TRUE, "(c:%x) glDisable: cap GL_TEXTURE_2D disabling for texture %s...", self, [[self getGlName:_activeTexture] UTF8String]);
#endif
        [_texture2DTextures setState:_activeTexture state:NO];
        glDisable(GL_TEXTURE_2D);
    }
    return YES;
}

-(BOOL)enableGlTextureCoordArray:(BOOL)enable{
    //enables a coord array for the given texture
    //because these commands affect the active texture - not the global state
    
    if (enable){
        //want to enable
        if ([self getGlTextureCoordArrayState:_clientActiveTexture]) {
            //already enabled - bail
#if FULL_GL_DEBUG
            sfDebug(TRUE, "(c:%x) glEnableClientState: array GL_TEXTURE_COORD_ARRAY already enabled for texture %s", self, [[self getGlName:_clientActiveTexture] UTF8String]);
#endif
#if REPEAT_ALL_COMMANDS == 0
            return NO;
#endif
        }
#if FULL_GL_DEBUG
        sfDebug(TRUE, "(c:%x) glEnableClientState: array GL_TEXTURE_COORD_ARRAY enabling for texture %s...", self, [[self getGlName:_clientActiveTexture] UTF8String]);
#endif
        [_coordArrayTextures setState:_clientActiveTexture state:YES];
        glEnableClientState(GL_TEXTURE_COORD_ARRAY);
    } else {
        //want to disable
        if (![self getGlTextureCoordArrayState:_clientActiveTexture]) {
            //already disabled - bail
#if FULL_GL_DEBUG
            sfDebug(TRUE, "(c:%x) glDisableClientState: array GL_TEXTURE_COORD_ARRAY already disabled for texture %s", self, [[self getGlName:_clientActiveTexture] UTF8String]);
#endif
#if REPEAT_ALL_COMMANDS == 0
            return NO;
#endif
        }
#if FULL_GL_DEBUG
        sfDebug(TRUE, "(c:%x) glDisableClientState: array GL_TEXTURE_COORD_ARRAY disabling for texture %s...", self, [[self getGlName:_clientActiveTexture] UTF8String]);
#endif
        [_coordArrayTextures setState:_clientActiveTexture state:NO];
        glDisableClientState(GL_TEXTURE_COORD_ARRAY);
    }
    return YES;
}

-(void)dealloc{
    //no cleanup for this thing - hierarchy
    [_texture2DTextures release];
    [_coordArrayTextures release];
    [_glCapSet release];
    [super dealloc];
}

#if SLOW_ACTUAL_STATE_CHECKS
-(BOOL)capIsEnabled:(GLenum)cap{
    BOOL glIs = glIsEnabled(cap);
    if ([_glCapSet getState:cap] != glIs){
        sfDebug(TRUE, "Cached state discrepancy! %s actual state is %d", [[self getGlName:cap] UTF8String], glIs);
    }
    return glIs;
}

-(BOOL)isBuffer:(GLuint)buffer{
    return glIsBuffer(buffer);
}

-(BOOL)isTexture:(GLuint)texture{
    BOOL glTexIs = glIsTexture(texture);
    if ((_activeTexture == texture) != (glTexIs)) {
        sfDebug(TRUE, "Tex discrepancy - texture active in gl is %u", glTexIs);
    }
    return glTexIs;
}

#else
-(BOOL)isBuffer:(GLuint)buffer{
    sfDebug(TRUE, "FINISH THIS"); 
}

-(BOOL)isTexture:(GLuint)texture{
    return (_activeTexture == texture);
}

-(BOOL)capIsEnabled:(GLenum)cap{
    return [_glCapSet getState:cap];
}


#endif

+(BOOL)capIsEnabled:(GLenum)cap{
    return [(SFGLContext*)[EAGLContext currentContext] capIsEnabled:cap];
}

-(BOOL)glEnable:(GLenum)cap{
    //the set lets us know in advance if this is already enabled and so skips the call
    if (cap == GL_TEXTURE_2D) {
        return [self enableGlTexture2D:YES];
    }
    if ([self capIsEnabled:cap]) {
#if FULL_GL_DEBUG
        sfDebug(TRUE, "(c:%x) glEnable: cap %s already enabled", self, [[self getGlName:cap] UTF8String]);
#endif
#if REPEAT_ALL_COMMANDS == 0
        return NO;
#endif
    }
#if FULL_GL_DEBUG
    sfDebug(TRUE, "(c:%x) glEnable: cap %s enabling...", self, [[self getGlName:cap] UTF8String]);
#endif
    //if we are here then we need to enable a cap
    //and add it to our set
    //[_glCapSet addObject:capNum];
    [_glCapSet setState:cap state:YES];
    glEnable(cap);
    return YES;
}

-(void)glTexCoordPointer:(GLint)size type:(GLenum)type stride:(GLsizei)stride pointer:(const GLvoid *)pointer{
#if FULL_GL_DEBUG
    sfDebug(TRUE, "(c:%x) glTexCoordPointer: looking for tex coords of size %uB at 0x%x...", self, size, pointer);
#endif
    glTexCoordPointer(size, type, stride, pointer);
}

+(void)glVertexPointer:(GLint)size type:(GLenum)type stride:(GLsizei)stride pointer:(const GLvoid *)pointer{
    [[self currentSFGLContext] glVertexPointer:size type:type stride:stride pointer:pointer];
}

-(void)glVertexPointer:(GLint)size type:(GLenum)type stride:(GLsizei)stride pointer:(const GLvoid *)pointer{
#if FULL_GL_DEBUG
    sfDebug(TRUE, "(c:%x) glVertexPointer: looking for vertex data of size %uB at 0x%x...", self, size, pointer);
#endif
    glVertexPointer(size, type, stride, pointer);
}

+(void)glTexCoordPointer:(GLint)size type:(GLenum)type stride:(GLsizei)stride pointer:(const GLvoid *)pointer{
    [[self currentSFGLContext] glTexCoordPointer:size type:type stride:stride pointer:pointer];
}

-(BOOL)glDisable:(GLenum)cap{
    //the set lets us know in advance if this is already disabled and so skips the call
    if (cap == GL_TEXTURE_2D) {
        return [self enableGlTexture2D:NO];
    }
    if (![self capIsEnabled:cap]) {
#if FULL_GL_DEBUG
        sfDebug(TRUE, "(c:%x) glDisable: cap %s already disabled", self, [[self getGlName:cap] UTF8String]);
#endif
#if REPEAT_ALL_COMMANDS == 0
        return NO;
#endif
    }
#if FULL_GL_DEBUG
    sfDebug(TRUE, "(c:%x) glDisable: cap %s disabling...", self, [[self getGlName:cap] UTF8String]);
#endif
    //if we are here then we need to disable a cap
    //and remove it from our set
    //[_glCapSet removeObject:capNum];
    [_glCapSet setState:cap state:NO];
    glDisable(cap);
    return YES;
}

-(BOOL)glActiveTexture:(GLenum)texture{
    if ([self isTexture:texture]) {
#if FULL_GL_DEBUG
        sfDebug(TRUE, "(c:%x) glActiveTexture: texture already set to %s", self, [[self getGlName:texture] UTF8String]);
#endif
#if REPEAT_ALL_COMMANDS == 0
        return NO;
#endif
    }
#if FULL_GL_DEBUG
    sfDebug(TRUE, "(c:%x) glActiveTexture: active texture setting to %s...", self, [[self getGlName:texture] UTF8String]);
#endif
    _activeTexture = texture;
    glActiveTexture(texture);
    return YES;
}

-(BOOL)glColor4f:(vec4)color{
    if (memcmp(&_colour, &color, sizeof(vec4) == 0)) {
#if FULL_GL_DEBUG
        sfDebug(TRUE, "(c:%x) glColor4f: color already set to %.0f %.0f %.0f %.0f", self, [color UTF8Description]);
#endif
#if REPEAT_ALL_COMMANDS == 0
        return NO;
#endif
    }
#if FULL_GL_DEBUG
    sfDebug(TRUE, "(c:%x) glColor4f: color setting to %.0f %.0f %.0f %.0f...", self, [color UTF8Description]);
#endif
    
        memcpy(&_colour, &color, sizeof(vec4));
    glColor4f(_colour.x, _colour.y, _colour.z, _colour.w);
#if DEBUG_COLOUR
    sfDebug(TRUE, "Colour set to: %.2f, %.2f, %.2f, %.2f", [_colour getR], [_colour getG], [_colour getB], [_colour getA]);
#endif
    return YES;
}

-(void)releaseActiveMaterial{
    if (_activeMaterial) {
        [_activeMaterial release];
        _activeMaterial = nil;
    }
}

-(void)setActiveMaterial:(id)activeMaterial{
    //allows us to skip rendering this material if we
    //have already set it up - speed enhancement
    //note that this will be skipped when repeating all
#if FULL_GL_DEBUG
    sfDebug(TRUE, "Setting active material to %s...", [[activeMaterial description] UTF8String]);
#endif
#if REPEAT_ALL_COMMANDS
    return;
#endif
    [self releaseActiveMaterial];
    _activeMaterial = [activeMaterial retain];
}

-(id)getActiveMaterial{
    return _activeMaterial;
}

+(void)setActiveMaterial:(id)activeMaterial{
    [[self currentSFGLContext] setActiveMaterial:activeMaterial];
}

+(id)getActiveMaterial{
    return [[self currentSFGLContext] getActiveMaterial];
}

-(BOOL)glAlphaFunc:(GLenum)func ref:(GLclampf)ref{
    if ((func == _alphaFunc) and (ref == _alphaFuncRef)) {
#if FULL_GL_DEBUG
        sfDebug(TRUE, "(c:%x) glAlphaFunc: already set to %u, %f", self, func, ref);
#endif        
#if REPEAT_ALL_COMMANDS == 0
        return NO;
#endif
    }
#if FULL_GL_DEBUG
    sfDebug(TRUE, "(c:%x) glAlphaFunc: setting to %u, %f...", self, func, ref);
#endif  
    _alphaFunc = func;
    _alphaFuncRef = ref;
    glAlphaFunc(func, ref);
    return YES;
}

-(BOOL)glTexEnvf:(GLenum)target pname:(GLenum)pname param:(GLfloat)param{
    if (_imageFilter == param) {
#if FULL_GL_DEBUG
        sfDebug(TRUE, "(c:%x) glTexEnvf: already set to %f", self, param);
#endif  
#if REPEAT_ALL_COMMANDS == 0
        return NO;
#endif
    }
#if FULL_GL_DEBUG
    sfDebug(TRUE, "(c:%x) glTexEnvf: setting to %f", self, param);
#endif  
    _imageFilter = param;
    glTexEnvf( GL_TEXTURE_FILTER_CONTROL_EXT,
               GL_TEXTURE_LOD_BIAS_EXT, 
              param);
    return YES;
}

-(BOOL)glBindBuffer:(GLenum)target buffer:(GLuint)buffer{
    GLuint compareWithBuffer;
    switch (target) {
        case GL_ARRAY_BUFFER:
            compareWithBuffer = _boundArrayBuffer;
            _boundArrayBuffer = buffer;
            break;
        case GL_ELEMENT_ARRAY_BUFFER:
            compareWithBuffer = _boundElementArrayBuffer;
            _boundElementArrayBuffer = buffer;
            break;
    }
    if (buffer == compareWithBuffer) {
#if FULL_GL_DEBUG
        sfDebug(TRUE, "(c:%x) glBindBuffer: buffer %s already bound to %u", self, [[self getGlName:target] UTF8String], buffer);
#endif          
#if REPEAT_ALL_COMMANDS == 0
        return NO;
#endif
    }
#if FULL_GL_DEBUG
    sfDebug(TRUE, "(c:%x) glBindBuffer: binding buffer %s to %u...", self, [[self getGlName:target] UTF8String], buffer);
#endif    
    glBindBuffer(target, buffer);
    return YES;
}

-(void)glTexSubImage2D:(GLenum)target level:(GLint)level xoffset:(GLint)xoffset yoffset:(GLint)yoffset width:(GLsizei)width
                height:(GLsizei)height format:(GLenum)format type:(GLenum)type
                pixels:(const GLvoid *)pixels{
#if FULL_GL_DEBUG
    sfDebug(TRUE, "(c:%x) glTexSubImage2D: buffering %ux%u image with offset %d, %d from 0x%x for %s with bound texture %u...", self, width, height, xoffset, yoffset, pixels, [[self getGlName:target] UTF8String], _boundTexture);
#endif   
    glTexSubImage2D(target,
                    level,
                    xoffset,
                    yoffset,
                    width,
                    height,
                    format, type, pixels);
}

+(void)glTexSubImage2D:(GLenum)target level:(GLint)level xoffset:(GLint)xoffset yoffset:(GLint)yoffset width:(GLsizei)width
                height:(GLsizei)height format:(GLenum)format type:(GLenum)type
                pixels:(const GLvoid *)pixels{
    [[self currentSFGLContext] glTexSubImage2D:target
                                         level:level
                                       xoffset:xoffset
                                       yoffset:yoffset
                                         width:width
                                        height:height
                                        format:format
                                          type:type
                                        pixels:pixels];
}

-(BOOL)glBindTexture:(GLenum)target texture:(GLuint)texture{
    if (_boundTexture == texture) {
#if FULL_GL_DEBUG
        sfDebug(TRUE, "(c:%x) glBindTexture: texture %u already bound to %s", self, texture, [[self getGlName:target] UTF8String]);
#endif
#if REPEAT_ALL_COMMANDS == 0
        return NO;
#endif
    }
#if FULL_GL_DEBUG
    sfDebug(TRUE, "(c:%x) glBindTexture: binding texture %u to %s...", self, texture, [[self getGlName:target] UTF8String]);
#endif
    _boundTexture = texture;
    glBindTexture(target, texture);
    return YES;
}

-(BOOL)frameBufferOk{
    return (_lastFrameBufferStatusOES == GL_FRAMEBUFFER_COMPLETE_OES);
}

-(NSString*)getCapSummary{
    //for debugging - gives a summary of the cap states etc
    NSMutableArray *capSum = [[[NSMutableArray alloc] init] autorelease];
    [capSum addObject:@"Caps:"];
    for (id cap in [_glCapSet trueSummary]) {
        [capSum addObject:[self getGlName:[cap unsignedIntegerValue]]];
    }
#if REPORT_CAPS_ONLY
    return [capSum componentsJoinedByString:@" "];
#endif
    [capSum addObject:@"Texture2DActive:"];
    for (id tex in [_texture2DTextures trueSummary]){
        [capSum addObject:[self getGlName:[tex unsignedIntegerValue]]];
    }
    [capSum addObject:@"TextureCoordArrayActive:"];
    for (id tex in [_coordArrayTextures trueSummary]){
        [capSum addObject:[self getGlName:[tex unsignedIntegerValue]]];
    }
    [capSum addObject:[NSString stringWithFormat:@"BlendMode:%u", _blendMode]];
    [capSum addObject:[NSString stringWithFormat:@"ActiveTexture:%s", [[self getGlName:_activeTexture] UTF8String]]];
    [capSum addObject:[NSString stringWithFormat:@"ClientActiveTexture:%s", [[self getGlName:_clientActiveTexture] UTF8String]]];
#if REPORT_BUFFERS
    [capSum addObject:[NSString stringWithFormat:@"BoundArrayBuffer:%u", _boundArrayBuffer]];
    [capSum addObject:[NSString stringWithFormat:@"BoundElementArrayBuffer:%u", _boundElementArrayBuffer]];
#endif
    return [capSum componentsJoinedByString:@" "];
}

-(void)glFinish{
    sfDebug(TRUE, "(c:%x) glFinish: WAITING for all commands to be finished...", self);
    glFinish();
}

+(void)glFinish{
    [[self currentSFGLContext] glFinish];
}

-(BOOL)glDrawElements:(GLenum)mode count:(GLsizei)count type:(GLenum)type indicies:(const GLvoid *)indices{
    if (![self frameBufferOk]) {
        sfDebug(TRUE, "(c:%x) glDrawElements: Can't draw - no framebuffer", self);
        return NO;
    }
#if REPORT_3D_DRAW_STATE
    //sfDebug(TRUE, "\n\n(c:%x) glDrawElements...", self);
    [self reportDrawState];
#endif  
    glDrawElements(mode, count, type, indices);
#if SLOW_3D_DRAW
    [SFGameEngine swapBuffers:YES];
    [SFUtils sleep:SLOW_DRAW_DELAY_MS];
#endif
    return YES;
}

-(BOOL)glDrawArrays:(GLenum)mode first:(GLint)first count:(GLsizei)count{
    if (![self frameBufferOk]) {
        sfDebug(TRUE, "(c:%x) glDrawArrays: Can't draw - no framebuffer", self);
        return NO;
    }
#if REPORT_2D_DRAW_STATE
    //sfDebug(TRUE, "\n\n(c:%x) glDrawArrays...", self);
    [self reportDrawState];
#endif  
    glDrawArrays(mode, first, count);
#if SLOW_2D_DRAW
    [SFGameEngine swapBuffers:YES];
    [SFUtils sleep:SLOW_DRAW_DELAY_MS];
#endif
    return YES;
}

-(GLenum)glCheckFramebufferStatusOES:(GLenum)framebuffer{
    _lastFrameBufferStatusOES = glCheckFramebufferStatusOES(framebuffer);
    return _lastFrameBufferStatusOES;
}

-(void)glDeleteBuffers:(GLsizei)n buffers:(const GLuint*)buffers{
#if DEBUG_BUFFER_DELETE
    sfDebug(TRUE, "Deleting buffers:");
    for (int i = 0; i < n; ++i) {
        sfDebug(TRUE, "BUF:%u", buffers[i]);
    }
#endif
    glDeleteBuffers(n, buffers);
#if DEBUG_BUFFER_DELETE
    sfDebug(TRUE, "%d Buffers deleted", n);
#endif
}

+(void)glDeleteBuffers:(GLsizei)n buffers:(const GLuint*)buffers{
    [[self currentSFGLContext] glDeleteBuffers:n buffers:buffers];
}

-(void)glDeleteTextures:(GLsizei)n textures:(const GLuint *)textures{
#if DEBUG_TEX_DELETE
    sfDebug(TRUE, "Deleting textures:");
    for (int i = 0; i < n; ++i) {
        sfDebug(TRUE, "TEX:%u", textures[i]);
    }
#endif
    glDeleteTextures(n, textures);
#if DEBUG_TEX_DELETE
    sfDebug(TRUE, "%d Textures deleted", n);
#endif
}

+(void)glDeleteTextures:(GLsizei)n textures:(const GLuint *)textures{
    [[self currentSFGLContext] glDeleteTextures:n textures:textures];
}

-(void*)mapBuffer:(GLuint)buffer target:(GLenum)target{
    void *ptr = nil;
    
	[self glBindBuffer:target buffer:buffer];
    
#if FULL_GL_DEBUG
    sfDebug(TRUE, "(c:%x) mapBuffer: mapping buffer %u target 0x%x...", self, buffer, target);
#endif  
    glMapBufferOES(target, GL_WRITE_ONLY_OES);
    
    //PERF ISSUE:
    //this should be called infrequently as it may cause the 
    //gl hardware to lockstep with the cpu
    
    glGetBufferPointervOES(target, GL_BUFFER_MAP_POINTER_OES, &ptr);
    
	return ptr;
}

-(void)unMapBuffer:(GLuint)buffer target:(GLenum)target{
    
	[self glBindBuffer:target buffer:buffer];
    
#if FULL_GL_DEBUG
    sfDebug(TRUE, "(c:%x) unMapBuffer: unmapping buffer %u target 0x%x...", self, buffer, target);
#endif  
	
	glUnmapBufferOES(target);
    
	[self glBindBuffer:target buffer:0];
}

-(void)glFlush{
#if FLUSH_ENABLED
#if FULL_GL_DEBUG
    sfDebug(TRUE, "(c:%x) glFlush: Flushing...", self);
#endif  
    glFlush();
#endif
}

+(void)glFlush{
    [[self currentSFGLContext] glFlush];
}

-(void)enter2d:(GLfloat)clipStart clipEnd:(GLfloat)clipEnd{
	[self glMatrixMode:GL_PROJECTION ];
	[self glPushMatrix];
	glLoadIdentity();
	
	glOrthof([[SFGameEngine sfWindow] loc].x,
             [[SFGameEngine sfWindow] scl].x,
             [[SFGameEngine sfWindow] loc].y,
             [[SFGameEngine sfWindow] scl].y,
             clipStart, clipEnd );
    
	[self glMatrixMode:GL_MODELVIEW ];
	[self glPushMatrix];
	glLoadIdentity();
	
	if ([SFGLContext glDisable:GL_DEPTH_TEST]){
        glDepthMask(GL_FALSE);
    }
    [SFGLContext glDisable:GL_CULL_FACE];
	
	//[SFGameEngine sfWindow]->mode =	SF_WINDOW_PORTRAIT_2D;
}

-(void)leave2d{
    [self glMatrixMode:GL_PROJECTION ];
	[self glPopMatrix];
    
	[self glMatrixMode:GL_MODELVIEW ];
	[self glPopMatrix];
	
	if ([SFGLContext glEnable:GL_DEPTH_TEST]){
        glDepthMask(GL_TRUE);
    };
    
    [SFGLContext glEnable:GL_CULL_FACE];
}

-(void)enterLandscape3d{
	[self glPushMatrix];
	glRotatef(-90.0f, 0.0f, 0.0f, 1.0f);
}

-(void)leaveLandscape3d{
	[self glPopMatrix];
}


-(void)enterLandscape2d{
//	float tmp = [[[SFGameEngine sfWindow] scl] getX];
//	
//	[[[SFGameEngine sfWindow] scl] setX:[[[SFGameEngine sfWindow] scl] getY]];
//	[[[SFGameEngine sfWindow] scl] setY:tmp];
//	
//	[self glPushMatrix];
//    
//	glRotatef(-90.0f, 0.0f, 0.0f, 1.0f );
//	glTranslatef( -[[[SFGameEngine sfWindow] scl] getX], 0.0f, 0.0f );
//	
//	//[SFGameEngine sfWindow]->mode =	SF_WINDOW_LANDSCAPE_2D;	
}

-(void)leaveLandscape2d{ 
//	float tmp = [[[SFGameEngine sfWindow] scl] getX];
//	
//	[[[SFGameEngine sfWindow] scl] setX:[[[SFGameEngine sfWindow] scl] getY]];
//	[[[SFGameEngine sfWindow] scl] setY:tmp];
//	
//	[self glPopMatrix];	
}

-(void)printCurrentMatrix{
    //prints the current matrix at the top of the active
    //stack
    GLfloat matrix[16];

    glGetFloatv(_currentMatrixStack, (GLfloat*)&matrix);
    [SFUtils debugFloatMatrix:(float*)&matrix width:4 height:4];
}

-(void)glPushMatrix{
#if DEBUG_MATRIX_STACKS
    sfDebug(TRUE, "Pushing matrix onto the %s stack...", [[self getGlName:_currentMatrixStack] UTF8String]);
    [self printCurrentMatrix];
#endif
    glPushMatrix();
}

-(void)glPopMatrix{
#if DEBUG_MATRIX_STACKS
    sfDebug(TRUE, "Popping matrix from the %s stack...", [[self getGlName:_currentMatrixStack] UTF8String]);
    [self printCurrentMatrix];
#endif
    glPopMatrix();
}

-(void)glMatrixMode:(GLenum)mode{
#if DEBUG_MATRIX_STACKS
    sfDebug(TRUE, "Changing to %s stack...", [[self getGlName:mode] UTF8String]);
#endif
    _currentMatrixStack = mode;
    glMatrixMode(mode);
}

+(void)glPushMatrix{
    [[self currentSFGLContext] glPushMatrix];
}

+(void)glPopMatrix{
    [[self currentSFGLContext] glPopMatrix];
}

+(void)glMatrixMode:(GLenum)mode{
    [[self currentSFGLContext] glMatrixMode:mode];
}

-(BOOL)glEnableClientState:(GLenum)array{
    //the set lets us know in advance if this is already enabled and so skips the call
    if (array == GL_TEXTURE_COORD_ARRAY) {
        return [self enableGlTextureCoordArray:YES];
    }
    if ([self capIsEnabled:array]) {
#if FULL_GL_DEBUG
        sfDebug(TRUE, "(c:%x) glEnableClientState: array %s already enabled", self, [[self getGlName:array] UTF8String]);
#endif
#if REPEAT_ALL_COMMANDS == 0
        return NO;
#endif
    }
#if FULL_GL_DEBUG
    sfDebug(TRUE, "(c:%x) glEnableClientState: array %s enabling...", self, [[self getGlName:array] UTF8String]);
#endif
    //if we are here then we need to enable a cap
    //and add it to our set
    //[_glCapSet addObject:capNum];
    [_glCapSet setState:array state:YES];
    glEnableClientState(array);
    return YES;
}

-(BOOL)glDisableClientState:(GLenum)array{
    //the set lets us know in advance if this is already disabled and so skips the call
    if (array == GL_TEXTURE_COORD_ARRAY) {
        return [self enableGlTextureCoordArray:NO];
    }
    if (![self capIsEnabled:array]) {
#if FULL_GL_DEBUG
        sfDebug(TRUE, "(c:%x) glDisableClientState: array %s already disabled - skipped", self, [[self getGlName:array] UTF8String]);
#endif
#if REPEAT_ALL_COMMANDS == 0
        return NO;
#endif
    }
#if FULL_GL_DEBUG
    sfDebug(TRUE, "(c:%x) glDisableClientState: array %s disabling...", self, [[self getGlName:array] UTF8String]);
#endif
    //if we are here then we need to disable a cap
    //and remove it from our set
    //[_glCapSet removeObject:capNum];
    [_glCapSet setState:array state:NO];
    glDisableClientState(array);
    return YES;
}


-(void)objectReset{
#if FULL_GL_DEBUG
    sfDebug(TRUE, "(c:%x) vvvObject Reset BEGINvvv", self);
#endif
    [self glBindBuffer:GL_ARRAY_BUFFER buffer:0];
    [self glBindBuffer:GL_ELEMENT_ARRAY_BUFFER buffer:0];
    [self glDisableClientState:GL_COLOR_ARRAY];
	[self glDisableClientState:GL_NORMAL_ARRAY];
#if FULL_GL_DEBUG
    sfDebug(TRUE, "(c:%x) ^^^Object Reset END^^^", self);
#endif
}

-(void)setBlendMode:(unsigned int)blendMode{
    
    if (_blendMode == blendMode){
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
    
    _blendMode = blendMode;
    switch(blendMode)
    {
        case SF_MATERIAL_COLOR:
        {
            glBlendEquationOES( GL_FUNC_ADD_OES );
            glBlendFunc( GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA );
            
            break;
        }
            
        case SF_MATERIAL_MULTIPLY:
        {
            glBlendEquationOES( GL_FUNC_ADD_OES );
            glBlendFunc( GL_DST_COLOR, GL_ZERO );
            
            break;
        }
            
        case SF_MATERIAL_ADD:
        {
            glBlendEquationOES( GL_FUNC_ADD_OES );
            glBlendFunc( GL_SRC_ALPHA, GL_ONE );
            
            break;
        }
            
        case SF_MATERIAL_SUBTRACT:
        {
            glBlendEquationOES( GL_FUNC_SUBTRACT_OES );
            glBlendFunc( GL_SRC_ALPHA, GL_ONE );
            
            break; 
        }
            
        case SF_MATERIAL_DIVIDE:
        {
            glBlendEquationOES( GL_FUNC_ADD_OES );
            glBlendFunc( GL_ONE, GL_ONE );
            
            break; 
        }
            
        case SF_MATERIAL_DIFFERENCE:
        { 
            glBlendEquationOES( GL_FUNC_SUBTRACT_OES );
            glBlendFunc( GL_ONE, GL_ONE );
            
            break; 
        }
            
        case SF_MATERIAL_SCREEN:
        {
            glBlendEquationOES( GL_FUNC_ADD_OES );
            glBlendFunc( GL_SRC_COLOR, GL_DST_COLOR );
            
            break; 
        }
    }
}

-(void)glTexImage2D:(GLenum)target level:(GLint)level internalformat:(GLint)internalformat width:(GLsizei)width
             height:(GLsizei)height border:(GLint)border format:(GLenum)format type:(GLenum)type
             pixels:(const GLvoid *)pixels{
#if FULL_GL_DEBUG
    sfDebug(TRUE, "(c:%x) glTexImage2D: buffering %ux%u image from 0x%x for %s with bound texture %u...", self, width, height, pixels, [[self getGlName:target] UTF8String], _boundTexture);
#endif   
    glTexImage2D(target,
                 level,
                 internalformat,
                 width,
                 height, border,
                 format, type, pixels);
}

+(void)glTexImage2D:(GLenum)target level:(GLint)level internalformat:(GLint)internalformat width:(GLsizei)width
             height:(GLsizei)height border:(GLint)border format:(GLenum)format type:(GLenum)type
             pixels:(const GLvoid *)pixels{
    [[self currentSFGLContext] glTexImage2D:target
                                      level:level
                             internalformat:internalformat
                                      width:width
                                     height:height
                                     border:border
                                     format:format
                                       type:type
                                     pixels:pixels];
}

-(void)glBufferData:(GLenum)target size:(GLsizeiptr)size data:(const GLvoid *)data usage:(GLenum)usage{
#if FULL_GL_DEBUG
    GLuint compareWithBuffer;
    switch (target) {
        case GL_ARRAY_BUFFER:
            compareWithBuffer = _boundArrayBuffer;
            break;
        case GL_ELEMENT_ARRAY_BUFFER:
            compareWithBuffer = _boundElementArrayBuffer;
            break;
    }
    sfDebug(TRUE, "(c:%x) glBufferData: buffering %uB from 0x%x for %s with bound buffer %u...", self, size, data, [[self getGlName:target] UTF8String], compareWithBuffer);
#endif 
    glBufferData(target, size, data, usage);
}

+(void)glBufferData:(GLenum)target size:(GLsizeiptr)size data:(const GLvoid *)data usage:(GLenum)usage{
    [[self currentSFGLContext] glBufferData:target size:size data:data usage:usage];
}

+(void)setBlendMode:(unsigned int)blendMode{
    [[self currentSFGLContext] setBlendMode:blendMode];
}

//-(BOOL)glClearColor:(SFColour *)clear{
//  //  if ([clear equalsVector:_clearColour]) {
////        return NO;
////    }
////#if OVERRIDE_CLEAR_COLOUR
////    [clear setVector:REPLACEMENT_CLEAR_COLOUR];
////#endif
////    glClearColor([clear getR], [clear getG], [clear getB], [clear getA]);
////    return YES;
//}
//
//+(BOOL)glClearColor:(SFColour *)clear{
//    return [[self currentSFGLContext] glClearColor:clear];
//}

-(void)materialReset{
#if FULL_GL_DEBUG
    sfDebug(TRUE, "(c:%x) vvvMaterial Reset BEGINvvv", self);
#endif
    //release the current material (if any)
    [self releaseActiveMaterial];
    
    //sio2StateDisable( sio2->_SIO2state, SF_BLEND );
    [SFGLContext glDisable:GL_BLEND];
    
    //sio2StateSetBlendMode( sio2->_SIO2state, SF_MATERIAL_MIX );
    [SFGLContext setBlendMode:SF_MATERIAL_MIX];
    
    //sio2StateDisable( sio2->_SIO2state, SF_ALPHA_TEST );
    [SFGLContext glDisable:GL_ALPHA_TEST];
    
    [SFGLContext glActiveTexture:GL_TEXTURE0];
    [SFGLContext glDisable:GL_TEXTURE_2D];
    [SFGLContext glClientActiveTexture:GL_TEXTURE0];
    [SFGLContext glDisableClientState:GL_TEXTURE_COORD_ARRAY];
    
    [SFGLContext glActiveTexture:GL_TEXTURE1];
    [SFGLContext glDisable:GL_TEXTURE_2D];
    [SFGLContext glClientActiveTexture:GL_TEXTURE1];
    [SFGLContext glDisableClientState:GL_TEXTURE_COORD_ARRAY];
    
    [SFGLContext glColor4f:DIFFUSE_COLOUR_SOLID_WHITE];
#if FULL_GL_DEBUG
    sfDebug(TRUE, "(c:%x) ^^^Material Reset END^^^", self);
#endif
}

-(void)disableAllLamps{
    [self glDisable:GL_LIGHT0];
    [self glDisable:GL_LIGHT1];
    [self glDisable:GL_LIGHT2];
    [self glDisable:GL_LIGHT3];
    [self glDisable:GL_LIGHT4];
	[self glDisable:GL_LIGHT5];
    [self glDisable:GL_LIGHT6];
    [self glDisable:GL_LIGHT7];
}

+(void)disableAllLamps{
    [[self currentSFGLContext] disableAllLamps];
}

-(void)glLightModelfv:(GLenum)pname params:(SFVec*)params{
    glLightModelfv(pname, [params getGlArray]);
}

-(void)glLightModelf:(GLenum)pname param:(GLfloat)param{
    glLightModelf(pname, param);
}

+(void)glLightModelfv:(GLenum)pname params:(SFVec*)params{
    [[self currentSFGLContext] glLightModelfv:pname params:params];
}

+(void)glLightModelf:(GLenum)pname param:(GLfloat)param{
    [[self currentSFGLContext] glLightModelf:pname param:param];
}

-(void)lampSetAmbient:(SFColour*)ambientColour{
	[self glLightModelfv:GL_LIGHT_MODEL_AMBIENT params:ambientColour];
   // float c[4] = {[ambientColour getR],[ambientColour getG],[ambientColour getB],[ambientColour getA]};
   // glLightModelfv(GL_LIGHT_MODEL_AMBIENT, (const GLfloat*)&c);
	[self glLightModelf:GL_LIGHT_MODEL_TWO_SIDE param:1.0f];
}

+(void)lampSetAmbient:(SFColour*)ambientColour{
    [[self currentSFGLContext] lampSetAmbient:ambientColour];
}

-(void)enableLighting{
	[self glEnable:GL_LIGHTING];
    [self glEnable:GL_COLOR_MATERIAL];
    [self glEnable:GL_NORMALIZE];
	glShadeModel( GL_SMOOTH );	
}

-(BOOL)cachedState:(GLenum)cap{
    BOOL state = [_glCapSet getState:cap];
#if FULL_GL_DEBUG
    sfDebug(TRUE, "(c:%x) Cached state %s = %u", self, [[self getGlName:cap] UTF8String], state);
#endif
    return state;
}

+(BOOL)cachedState:(GLenum)cap{
    return [[self currentSFGLContext] cachedState:cap];
}

+(BOOL)cachedClientState:(GLenum)array{
    return [[self currentSFGLContext] cachedState:array];
}

-(void)glLightf:(GLenum)light pname:(GLenum)pname param:(GLfloat)param{
#if FULL_GL_DEBUG
    sfDebug(TRUE, "(c:%x) glLightf: light %s param %s setting to %f...", self, [[self getGlName:light] UTF8String], [[self getGlName:pname] UTF8String], param);
#endif
    glLightf(light, pname, param);
}

-(void)glLightfv:(GLenum)light pname:(GLenum)pname params:(SFVec*)params{
#if FULL_GL_DEBUG
#endif
    const GLfloat *glarray = [params getGlArray];
#if DEBUG_LIGHTS
    sfDebug(TRUE, "Light param %u set to %.2f %.2f %.2f %.2f", pname, glarray[0], glarray[1], glarray[2], glarray[3]);
#endif
    glLightfv(light, pname, glarray);
}

+(void)glLightf:(GLenum)light pname:(GLenum)pname param:(GLfloat)param{
    [[self currentSFGLContext] glLightf:light pname:pname param:param];
}

+(void)glLightfv:(GLenum)light pname:(GLenum)pname params:(SFVec*)params{
    [[self currentSFGLContext] glLightfv:light pname:pname params:params];
}

+(void)enableLighting{
    [[self currentSFGLContext] enableLighting];
}

-(void)disableLighting{
	[self glDisable:GL_LIGHTING];
    [self glDisable:GL_COLOR_MATERIAL];
    [self glDisable:GL_NORMALIZE];
    
	glShadeModel( GL_FLAT );
}

+(void)presentingRenderBuffer{
#if FULL_GL_DEBUG
    sfDebug(TRUE, "***FLIP*** (presenting render buffer)...");
#endif
#if DRAW_DEBUG_OVERLAYS
    //move into 2d landscape...
    //[self enter2d:0.0f clipEnd:1000.0f];
    //[self enterLandscape2d];
    //calculate our matrices...
    //[[[[SFGameEngine sm] currentScene] selectedCamera] cameraMovedUpdateGlMatrix];
    //[[SFGameEngine sfWindow] getViewPortMatrix];
    //tell anyone who cares that they can now draw their debug overlay
    //in this thread
    [[NSNotificationCenter defaultCenter] postNotificationName:SF_NOTIFY_DRAW_DEBUG_NOW 
                                                        object:nil];   
    //[self leaveLandscape2d];
    //[self leave2d];
#endif
#if DELAY_FLIP_BY_MS
    [SFUtils sleep:DELAY_FLIP_BY_MS];
#endif
}

-(BOOL)glClientActiveTexture:(GLenum)texture{
    if (_clientActiveTexture == texture) {
#if FULL_GL_DEBUG
        sfDebug(TRUE, "(c:%x) glClientActiveTexture: texture already set to 0x%x", self, texture);
#endif
#if REPEAT_ALL_COMMANDS == 0
        return NO;
#endif
    }
#if FULL_GL_DEBUG
    sfDebug(TRUE, "(c:%x) glClientActiveTexture: active texture setting to 0x%x...", self, texture);
#endif
    _clientActiveTexture = texture;
    glClientActiveTexture(texture);
    return YES;
}

-(void)glTranslatef:(GLfloat)x y:(GLfloat)y z:(GLfloat)z{
#if FULL_GL_DEBUG
    sfDebug(TRUE, "(c:%x) glTranslatef: translating (%.2f %.2f %.2f)...", self, x, y, z);
#endif
    glTranslatef(x, y, z);
}

+(void)glTranslatef:(GLfloat)x y:(GLfloat)y z:(GLfloat)z{
    [[self currentSFGLContext] glTranslatef:x y:y z:z];
}

-(void)glRotatef:(GLfloat)w x:(GLfloat)x y:(GLfloat)y z:(GLfloat)z{
#if FULL_GL_DEBUG
    sfDebug(TRUE, "(c:%x) glRotatingf: rotating %.2f (%.2f %.2f %.2f)...", self, w, x, y, z);
#endif
    glRotatef(w, x, y, z);
}

+(void)glRotatef:(GLfloat)w x:(GLfloat)x y:(GLfloat)y z:(GLfloat)z{
    [[self currentSFGLContext] glRotatef:w x:x y:y z:z];
}

-(void)glScalef:(GLfloat)x y:(GLfloat)y z:(GLfloat)z{
#if FULL_GL_DEBUG
    sfDebug(TRUE, "(c:%x) glScalef: scaling (%.2f %.2f %.2f)...", self, x, y, z);
#endif
    glScalef(x, y, z);
}

+(void)glScalef:(GLfloat)x y:(GLfloat)y z:(GLfloat)z{
    [[self currentSFGLContext] glScalef:x y:y z:z];
}

+(BOOL)glClientActiveTexture:(GLenum)texture{
    return [[self currentSFGLContext] glClientActiveTexture:texture];
}

+(void)disableLighting{
    [[self currentSFGLContext] disableLighting];
}

+(void)materialReset{
    [[self currentSFGLContext] materialReset];
}

+(void)releaseActiveMaterial{
    [[self currentSFGLContext] releaseActiveMaterial];
}

+(BOOL)glDisableClientState:(GLenum)array{
    return [[self currentSFGLContext] glDisableClientState:array];
}

+(void)objectReset{
    [[self currentSFGLContext] objectReset];
}

+(void)enter2d:(GLfloat)clipStart clipEnd:(GLfloat)clipEnd{
    [[self currentSFGLContext] enter2d:clipStart clipEnd:clipEnd];
}

+(void)leave2d{
    [[self currentSFGLContext] leave2d];
}

+(void)enterLandscape2d{
    [[self currentSFGLContext] enterLandscape2d];
}

+(void)leaveLandscape2d{
    [[self currentSFGLContext] leaveLandscape2d];
}

+(void)enterLandscape3d{
    [[self currentSFGLContext] enterLandscape3d];
}

+(void)leaveLandscape3d{
    [[self currentSFGLContext] leaveLandscape3d];
}

+(void*)mapBuffer:(GLuint)buffer target:(GLenum)target{
    return [[self currentSFGLContext] mapBuffer:buffer target:target];
}

+(BOOL)glEnableClientState:(GLenum)array{
    return [[self currentSFGLContext] glEnableClientState:array];
}

+(void)unMapBuffer:(GLuint)buffer target:(GLenum)target{
    [[self currentSFGLContext] unMapBuffer:buffer target:target];
}

+(GLenum)glCheckFramebufferStatusOES:(GLenum)framebuffer{
    return [[self currentSFGLContext] glCheckFramebufferStatusOES:framebuffer];
}

+(BOOL)glDrawArrays:(GLenum)mode first:(GLint)first count:(GLsizei)count{
    return [[self currentSFGLContext] glDrawArrays:mode first:first count:count];
}

+(BOOL)glDrawElements:(GLenum)mode count:(GLsizei)count type:(GLenum)type indicies:(const GLvoid *)indices{
    return [[self currentSFGLContext] glDrawElements:mode count:count type:type indicies:indices];
}

+(BOOL)glBindTexture:(GLenum)target texture:(GLuint)texture{
    return [[self currentSFGLContext] glBindTexture:target texture:texture];
}

+(BOOL)glBindBuffer:(GLenum)target buffer:(GLuint)buffer{
    return [[self currentSFGLContext] glBindBuffer:target buffer:buffer];
}

+(BOOL)glTexEnvf:(GLenum)target pname:(GLenum)pname param:(GLfloat)param{
    return [[self currentSFGLContext] glTexEnvf:target pname:pname param:param];    
}

+(SFGLContext*)currentSFGLContext{
    return (SFGLContext*)[EAGLContext currentContext];
}

+(BOOL)glEnable:(GLenum)cap{
    return [[self currentSFGLContext] glEnable:cap];
}

+(BOOL)glDisable:(GLenum)cap{
    return [[self currentSFGLContext] glDisable:cap];
}

+(BOOL)glActiveTexture:(GLenum)texture{
    return [[self currentSFGLContext] glActiveTexture:texture];
}

+(BOOL)glColor4f:(SFColour*)color{
    return [[self currentSFGLContext] glColor4f:color];
}

+(BOOL)glAlphaFunc:(GLenum)func ref:(GLclampf)ref{
    return [[self currentSFGLContext] glAlphaFunc:func ref:ref];
}

@end
