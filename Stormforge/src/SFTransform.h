//
//  SFTransform.h
//  ZombieArcade
//
//  Created by Adam Iredale on 4/02/10.
//  Copyright 2010 Stormforge Software. All rights reserved.
//

#include "SFVec.h"
#include "SFAng.h"
#include "SFObj.h"

typedef enum
{
	SF_TRANSFORM_MATRIX_NONE = 0,
	SF_TRANSFORM_MATRIX_BIND,
	SF_TRANSFORM_MATRIX_APPLY
    
} SF_TRANSFORM_MATRIX_TYPE;

class SFTransform : public SFObj {
    SFVec *_loc, *_scl, *_dir;
    SFAng *_rot;
    GLfloat *_matrix;
protected:
    const char* className();
    void printContent();
public:
    SFTransform();
    ~SFTransform();
    
    //members of the transform
    SFVec* loc();
    SFAng* rot();
    SFVec* scl();
    SFVec* dir();
    GLfloat *matrix();
    
    void setDefaults();
    void setFromTransform(SFTransform* transform);
    void rotateZDegrees(GLfloat degrees);
    void rotateZRadians(GLfloat radians);
    void updateLocFromMatrix();
    void updateRotFromMatrix();
    void updateMatrixScale();
    
    void compileMatrix();
    void applyTransform();
    void multMatrix();
    
    //copiers
    SFTransform* copy();
};