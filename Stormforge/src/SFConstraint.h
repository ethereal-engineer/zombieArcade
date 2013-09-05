//
//  SFConstraint.h
//  ZombieArcade
//
//  Created by Adam Iredale on 17/11/09.
//  Copyright 2009 Stormforge Software. All rights reserved.
//
#include "btVector3.h"

class SFConstraint{
    char *_name;
    float _influence;
    char *_targetName;
    float _axis[3];
    float _locMax[3];
    float _locMin[3];
    float _rotMax[3];
    float _rotMin[3];
    float _pivot[3];
private:
    void autoCopyStr(char **strTo, char *strFrom);
    void copy3Float(float *to, float *from);
    btVector3 floatsToBtVector3(float *floats);
public:
    SFConstraint(char *name);
    ~SFConstraint();
    void setInfluence(float influence);
    void setTargetName(char *targetName);
    void setAxis(float *axis);
    void setMaxLocation(float *maxLoc);
    void setMinLocation(float *minLoc);
    void setMaxRotation(float *maxRot);
    void setMinRotation(float *minRot);
    void setPivot(float *pivot);
    btVector3 pivot();
    btVector3 minRotation();
    btVector3 maxRotation();
    btVector3 minLocation();
    btVector3 maxLocation();
    btVector3 axis();
    char *targetName();
    float influence();
    char *name();
    bool targetNameIs(char *targetName);
};