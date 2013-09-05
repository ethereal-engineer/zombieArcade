//
//  SFBezierPoint.m
//  ZombieArcade
//
//  Created by Adam Iredale on 4/03/10.
//  Copyright 2010 Stormforge Software. All rights reserved.
//

#include "SFBezierPoint.h"

//using w and z as leading and trailing handles and x,y as the knot

SFVec* SFBezierPoint::knot(){
    return this;
}

GLfloat SFBezierPoint::handle1(){
    return this->w();
}

GLfloat SFBezierPoint::handle2(){
    return this->z();
}

void SFBezierPoint::setHandle1(GLfloat handle1){
    this->setW(handle1);
}

void SFBezierPoint::setHandle2(GLfloat handle2){
    this->setZ(handle2);
}

bool SFBezierPoint::setFloatsUsingXYZW(){
    return false;
}

const char* SFBezierPoint::className(){
    return "SFBezierPoint";
}

void SFBezierPoint::printContent(){
    printf("Handle 1: %.2f\n", this->handle1());
    printf("Knot: %.2f, %.2f\n", this->x(), this->y());
    printf("Handle 2: %.2f\n", this->handle2());
}