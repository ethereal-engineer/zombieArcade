//
//  SFBezierPoint.h
//  ZombieArcade
//
//  Created by Adam Iredale on 4/03/10.
//  Copyright 2010 Stormforge Software. All rights reserved.
//

#include "SFVec.h"

class SFBezierPoint : public SFVec {
protected:
    bool setFloatsUsingXYZW();
    const char* className();
    void printContent();
public:
    SFBezierPoint() : SFVec(4){};
    SFBezierPoint(GLfloat *floats, int count) : SFVec(count){
        this->setFloats(floats, count);
    };
    SFVec* knot();
    GLfloat handle1();
    GLfloat handle2();
    void setHandle1(GLfloat handle1);
    void setHandle2(GLfloat handle2);
};
