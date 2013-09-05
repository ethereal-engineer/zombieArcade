//
//  SFColour.h
//  ZombieArcade
//
//  Created by Adam Iredale on 10/03/10.
//  Copyright 2010 Stormforge Software. All rights reserved.
//

#ifndef SFCOLOUR_H

#include "SFVec.h"

class SFColour : public SFVec {
    //same as a vector, just has a different sort order
    //for the floats
public:
    SFColour() : SFVec(Vec4Make(1.0f, 1.0f, 1.0f, 1.0f)){};
    SFColour(GLfloat floats[]) : SFVec(floats, 4){};
    SFColour(vec4 colour) : SFVec(colour){};
    GLfloat r();
    GLfloat g();
    GLfloat b();
    GLfloat a();
    GLfloat alpha();
    void setAlpha(GLfloat alpha);
    void setR(GLfloat r);
    void setG(GLfloat g);
    void setB(GLfloat b);
    void setA(GLfloat a);
};

#define COLOUR_SOLID_RED Vec4Make(1.0f, 0.0f, 0.0f, 1.0f)
#define COLOUR_SOLID_BLUE Vec4Make(0.0f, 0.0f, 1.0f, 1.0f)
#define COLOUR_LIGHT_BLUE Vec4Make(0.16f, 1.0f, 1.0f, 1.0f)
#define COLOUR_SOLID_YELLOW Vec4Make(1.0f, 1.0f, 0.5f, 1.0f)
#define COLOUR_SOLID_AMBER Vec4Make(1.0f, 0.8f, 0.0f, 1.0f)
#define COLOUR_GOLD Vec4Make(0.97f, 0.745f, 0.271f, 1.0f)
#define COLOUR_SOLID_GREEN Vec4Make(0.0f, 1.0f, 0.0f, 1.0f)
#define COLOUR_SOLID_WHITE Vec4Make(1.0f, 1.0f, 1.0f, 1.0f)
#define COLOUR_80PC_TRANSPARENT Vec4Make(1.0f, 1.0f, 1.0f, 0.2f)
#define COLOUR_SOLID_BLOOD_RED Vec4Make(0.66f, 0.0f, 0.0f, 1.0f)
#define COLOUR_BLACK Vec4Make(0.0f, 0.0f, 0.0f, 1.0f)
#define COLOUR_BLENDER_GREY Vec4Make(0.8f, 0.8f, 0.8f, 1.0f)
#define COLOUR_HOT_PINK Vec4Make(0.965f, 0.322f, 0.875f, 1.0f)

#define SFColourBlank COLOUR_SOLID_WHITE

#define SFCOLOUR_H
#endif