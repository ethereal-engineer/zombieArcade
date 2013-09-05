/*
 *  SFVec.h
 *  ZombieArcade
 *
 *  Created by Adam Iredale on 25/03/10.
 *  Copyright 2010 Stormforge Software. All rights reserved.
 *
 */

#ifndef SFVEC_H

#include <OpenGLES/ES1/gl.h>
#include <CoreGraphics/CGGeometry.h>
#include "btBulletDynamicsCommon.h"
#include "SFObj.h"

typedef struct{
    GLfloat x;
    GLfloat y;
} vec2;

typedef struct{
    GLfloat x;
    GLfloat y;
    GLfloat z;
} vec3;

typedef struct{
    GLfloat x;
    GLfloat y;
    GLfloat z;
    GLfloat w;
} vec4;

class SFVec : public SFObj {
    //floats stored as x,y,z,w
protected:
    GLfloat *_floats;
    char _count;
    int _set;
    virtual bool setFloatsUsingXYZW();
    const char* className();
    void printContent();
private:
    void setup(int count);
public:
    int size();
    SFVec(vec2 vectorIn);
    SFVec(vec3 vectorIn);
    SFVec(vec4 vectorIn);
    SFVec(SFVec *vec);
    SFVec(btVector3 vectorIn);
    SFVec(CGPoint pointIn);
    SFVec(int count);
    SFVec(GLfloat *floats, int count);
    SFVec();
    ~SFVec();
    
    //manipulators
    void add(SFVec *vec);
    void subtract(SFVec *vec);
    bool equals(SFVec *vec);
    bool equals(vec3 vectorIn);
    bool equals(vec4 vectorIn);
    void scale(GLfloat factor);
    void reset();
    void addW(GLfloat w);
    void addX(GLfloat x);
    void addY(GLfloat y);
    void addZ(GLfloat z);
    void rotate3D(GLfloat x, GLfloat z, GLfloat d);
    void screenRotation2D();
    void xySwap();
    GLfloat normalise();
    
    //copies
    SFVec* copy();
    
    //news
    SFVec* directionTo(SFVec *vec);
    SFVec* diff(SFVec *vec);
    
    //info
    GLfloat w();
    GLfloat x();
    GLfloat y();
    GLfloat z();
    GLfloat *floatArray();
    GLfloat magnitude();
    GLfloat magnitude(int dimensions);
    GLfloat distanceFrom(SFVec *vec);
    GLfloat distanceFrom(SFVec *vec, int dimensions);
    int length();
    btVector3 getBtVector3();
    vec2 getVec2();
    vec3 getVec3();
    vec4 getVec4();
    
    //setters
    //void setVector(SFVec vec);
    void setVector(SFVec *vec);
    void setBtVector3(btVector3 vectorIn);
    void setCGPoint(CGPoint pointIn);
    void setVec2(vec2 vectorIn);
    void setVec3(vec3 vectorIn);
    void setVec4(vec4 vectorIn);
    void setFloats(GLfloat* floats, int count);
    void setW(GLfloat w);
    void setX(GLfloat x);
    void setY(GLfloat y);
    void setZ(GLfloat z);
};

static inline vec2 Vec2Make(float x, float y){
    vec2 newVec;
    newVec.x = x; 
    newVec.y = y; 
    return newVec;
};

static inline vec3 Vec3Make(float x, float y, float z){
    vec3 newVec; 
    newVec.x = x; 
    newVec.y = y; 
    newVec.z = z; 
    return newVec;
};

static inline vec4 Vec4Make(float x, float y, float z, float w){
    vec4 newVec; 
    newVec.x = x; 
    newVec.y = y; 
    newVec.z = z; 
    newVec.w = w; 
    return newVec;
};

#define Vec2Zero Vec2Make(0,0)
#define Vec3Zero Vec3Make(0,0,0)
#define Vec4Zero Vec4Make(0,0,0,0)

#define SFVEC_H
#endif
