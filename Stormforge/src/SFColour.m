//
//  SFColour.m
//  ZombieArcade
//
//  Created by Adam Iredale on 10/03/10.
//  Copyright 2010 Stormforge Software. All rights reserved.
//

#include "SFColour.h"

GLfloat SFColour::r(){
    return this->x();
}

GLfloat SFColour::g(){
    return this->y();
}

GLfloat SFColour::b(){
    return this->z();
}

GLfloat SFColour::a(){
    return this->w();
}

GLfloat SFColour::alpha(){
    return this->a();
}

void SFColour::setAlpha(GLfloat alpha){
    this->setA(alpha);
}

void SFColour::setR(GLfloat r){
    this->setX(r);
}

void SFColour::setG(GLfloat g){
    this->setY(g);
}

void SFColour::setB(GLfloat b){
    this->setZ(b);
}

void SFColour::setA(GLfloat a){
    this->setW(a);
}