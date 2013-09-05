//
//  SFRect.m
//  ZombieArcade
//
//  Created by Adam Iredale on 8/03/10.
//  Copyright 2010 Stormforge Software. All rights reserved.
//

#include "SFRect.h"

//use w and z as width and height and x,y as origin

GLfloat SFRect::top(){
    return this->bottom() + this->height();
}

GLfloat SFRect::left(){
    if (this->_centered) {
        return this->x() - (this->width() / 2.0f);
    }
    return this->x();
}

GLfloat SFRect::bottom(){
    if (this->_centered) {
        return this->y() - (this->height() / 2.0f);
    }
    return this->y();    
}

GLfloat SFRect::right(){
    return this->left() + this->width();
}

bool SFRect::containsPoint(vec2 point){
    //printf("Contains point: %.2f, %.2f?\n", point.x, point.y);
    //this->print();
    bool contains = (point.x >= this->left() and
                     point.x <= this->right() and
                     point.y <= this->top() and
                     point.y >= this->bottom());
   // printf("Result = %u\n", contains);
    return contains;
}

void SFRect::setCGRect(CGRect rect){
    this->setOrigin(rect.origin.x, rect.origin.y);
    this->setWidth(rect.size.width);
    this->setHeight(rect.size.height);
}

SFVec* SFRect::bottomLeft(){
    return this;
}

void SFRect::print(){
    printf("SFRect 0x%x {\n", (unsigned int)this);
    printf("BL: %.2f, %.2f\n", this->left(), this->bottom());
    printf("TR: %.2f, %.2f\n", this->right(), this->top());
    printf("}\n");
}

void SFRect::setOrigin(GLfloat x, GLfloat y){
    this->setX(x);
    this->setY(y);
}

GLfloat SFRect::width(){
    return this->w();
}

GLfloat SFRect::height(){
    return this->z();
}

GLfloat SFRect::area(){
    return this->height() * this->width();
}

void SFRect::setWidth(GLfloat width){
    this->setW(width);
}

void SFRect::setHeight(GLfloat height){
    this->setZ(height);
}

void SFRect::setCentered(bool centered){
    this->_centered = centered;
}

