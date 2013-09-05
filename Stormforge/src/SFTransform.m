//
//  SFTransform.m
//  ZombieArcade
//
//  Created by Adam Iredale on 4/02/10.
//  Copyright 2010 Stormforge Software. All rights reserved.
//

#include "SFTransform.h"
#include "SFGL.h"
#include "SFUtils.h"
#include "SFGLManager.h"
#include "SFDebug.h"

#define DEFAULT_SCALE Vec4Make(1.0f, 1.0f, 1.0f, 1.0f)
#define DEFAULT_DIRECTION Vec4Make(0.0f, -1.0f, 0.0f, -1.0f) //everything starts facing forward - minus y

void SFTransform::setDefaults(){
    this->_scl->setVec4(DEFAULT_SCALE);
    this->_dir->setVec4(DEFAULT_DIRECTION);
}

SFTransform::SFTransform(){
    //the 4 x 4 matrix of glfloats
    //for gl
    this->_matrix = (GLfloat*)malloc(sizeof(GLfloat) * 16);
    memset(this->_matrix, 0, sizeof(GLfloat) * 16);
    //vecs
    this->_loc = new SFVec(4);
    this->_rot = new SFAng(4);
    this->_scl = new SFVec(DEFAULT_SCALE);
    this->_dir = new SFVec(DEFAULT_DIRECTION);
}

SFTransform::~SFTransform(){
    delete this->_loc;
    delete this->_rot;
    delete this->_scl;
    delete this->_dir;
    free(this->_matrix);
}

//members of the transform
SFVec* SFTransform::loc(){
    return this->_loc;
}

SFAng* SFTransform::rot(){
    return this->_rot;
}

SFVec* SFTransform::scl(){
    return this->_scl;
}

SFVec* SFTransform::dir(){
    return this->_dir;
}

GLfloat* SFTransform::matrix(){
    return this->_matrix;
}

const char* SFTransform::className(){
    return "SFTransform";
}

void SFTransform::printContent(){
    this->_loc->print();
    this->_rot->print();
    this->_scl->print();
    this->_dir->print();
}

void SFTransform::setFromTransform(SFTransform* transform){
    this->_loc->setVector(transform->loc());
    this->_rot->setVector(transform->rot());
    this->_scl->setVector(transform->scl());
    this->_dir->setVector(transform->dir());
    memcpy(this->_matrix, transform->matrix(), sizeof(GLfloat) * 16);
}

void SFTransform::rotateZDegrees(GLfloat degrees){
    this->rotateZRadians(degrees * SF_DEG_TO_RAD);
}

void SFTransform::rotateZRadians(GLfloat radians){
    //rotates the direction based on a (0,1) forward dir
    this->_dir->setX(sinf(radians));
    this->_dir->setY(-cosf(radians));
}

void SFTransform::updateLocFromMatrix(){
    memcpy(this->_loc->floatArray(), &this->_matrix[12], 12);
}

void SFTransform::updateRotFromMatrix(){
    this->_rot->setX(acosf( this->_matrix[0]) / (SF_PI * 180.0f));
    this->_rot->setY(acosf( this->_matrix[5]) / (SF_PI * 180.0f));
    this->_rot->setZ(acosf( this->_matrix[10]) / (SF_PI * 180.0f));
}

void SFTransform::updateMatrixScale(){
    if (!this->_scl->equals(DEFAULT_SCALE)) {
        this->_matrix[0]  *= this->_scl->x();
        this->_matrix[1]  *= this->_scl->x();
        this->_matrix[2]  *= this->_scl->x();
        
        this->_matrix[4]  *= this->_scl->y();
        this->_matrix[5]  *= this->_scl->y();
        this->_matrix[6]  *= this->_scl->y();
        
        this->_matrix[8]  *= this->_scl->z();
        this->_matrix[9]  *= this->_scl->z();
        this->_matrix[10] *= this->_scl->z();
    }
}

void SFTransform::compileMatrix(){
    //we are compiling a matrix from scratch here
    //so we can do it in any context
    if (![EAGLContext currentContext]) {
        [EAGLContext setCurrentContext:[SFGLManager quickSharedContext]];
    }
    glPushMatrix();
	{
		glLoadIdentity();
		
		this->applyTransform();
		
        //PERF ISSUE:
        //this should be called infrequently as it may cause the 
        //gl hardware to lockstep with the cpu
		glGetFloatv(GL_MODELVIEW_MATRIX, this->_matrix);
	}
    glPopMatrix();
}

void SFTransform::applyTransform(){
    glTranslatef(this->_loc->x(),
                 this->_loc->y(),
                 this->_loc->z());
    
    glRotatef(this->_rot->z(),
              0.0f,
              0.0f,
              1.0f);	
    
    glRotatef(this->_rot->y(),
              0.0f,
              1.0f,
              0.0f);
    
    glRotatef(this->_rot->x(),
              1.0f,
              0.0f,
              0.0f);
    
    glScalef(this->_scl->x(),
             this->_scl->y(),
             this->_scl->z());
}

void SFTransform::multMatrix(){
    glMultMatrixf(this->_matrix);
}

//copiers
SFTransform* SFTransform::copy(){
    SFTransform *newTrans = new SFTransform();
    newTrans->setFromTransform(this);
    return newTrans;
}
