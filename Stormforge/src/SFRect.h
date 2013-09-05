//
//  SFRect.h
//  ZombieArcade
//
//  Created by Adam Iredale on 8/03/10.
//  Copyright 2010 Stormforge Software. All rights reserved.
//

#ifndef SFRECT_H

#include "SFVec.h"

class SFRect : public SFVec {
    bool _centered;
public:
    SFRect() : SFVec(){
        this->_centered = false;
    };
    SFRect(GLfloat x, GLfloat y, GLfloat width, GLfloat height) : SFVec(4){
        this->setOrigin(x, y);
        this->setWidth(width);
        this->setHeight(height);
        this->_centered = false;
    };
    GLfloat top();
    GLfloat left();
    GLfloat bottom();
    GLfloat right();
    void setOrigin(GLfloat x, GLfloat y);
    GLfloat width();
    GLfloat height();
    GLfloat area();
    void setWidth(GLfloat width);
    void setHeight(GLfloat height);
    void setCentered(bool centered);
    void setCGRect(CGRect rect);
    bool containsPoint(vec2 point);
    SFVec *bottomLeft();
    void print();
};

#define SFRECT_H
#endif