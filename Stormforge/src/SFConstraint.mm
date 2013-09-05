//
//  SFConstraint.m
//  ZombieArcade
//
//  Created by Adam Iredale on 17/11/09.
//  Copyright 2009 Stormforge Software. All rights reserved.
//

#import "SFConstraint.h"

void SFConstraint::autoCopyStr(char **strTo, char *strFrom){
    int newLen = strlen(strFrom);
    *strTo = (char*)calloc(1, (newLen + 1) * sizeof(char));
    strcpy(*strTo, strFrom);
    char *strToPtr = *strTo;
    strToPtr[newLen] = 0;
}

SFConstraint::SFConstraint(char *name){
    //set the name
    this->autoCopyStr(&this->_name, name);
    this->_targetName = NULL;
}

SFConstraint::~SFConstraint(){
    //dealloc
    free(this->_targetName);
    free(this->_name);
}

btVector3 SFConstraint::floatsToBtVector3(float *floats){
    return btVector3(floats[0], floats[1], floats[2]);
}

btVector3 SFConstraint::pivot(){
    return this->floatsToBtVector3(this->_pivot);
}

btVector3 SFConstraint::minRotation(){
    return this->floatsToBtVector3(this->_rotMin);
}

btVector3 SFConstraint::maxRotation(){
    return this->floatsToBtVector3(this->_rotMax);
}

btVector3 SFConstraint::minLocation(){
    return this->floatsToBtVector3(this->_locMin);
}

btVector3 SFConstraint::maxLocation(){
    return this->floatsToBtVector3(this->_locMax);
}

btVector3 SFConstraint::axis(){
    return this->floatsToBtVector3(this->_axis);
}

char* SFConstraint::targetName(){
    return this->_targetName;
}

float SFConstraint::influence(){
    return this->_influence;
}

char* SFConstraint::name(){
    return this->_name;
}

bool SFConstraint::targetNameIs(char *targetName){
    return strcmp(this->_targetName, targetName) == 0;    
}

void SFConstraint::setInfluence(float influence){
    this->_influence = influence;
}

void SFConstraint::setTargetName(char *targetName){
    this->autoCopyStr(&this->_targetName, targetName);
}

void SFConstraint::copy3Float(float *copyTo, float *copyFrom){
    memcpy(copyTo, copyFrom, sizeof(float) * 3);
}

void SFConstraint::setAxis(float *axis){
    //assumes a 3-point axis
    this->copy3Float(this->_axis, axis);
}

void SFConstraint::setMaxLocation(float *maxLoc){
    //assumes a 3-point axis
    this->copy3Float(this->_locMax, maxLoc);
}

void SFConstraint::setMinLocation(float *minLoc){
    //assumes a 3-point axis
    this->copy3Float(this->_locMin, minLoc);
}

void SFConstraint::setMaxRotation(float *maxRot){
    //assumes a 3-point axis
    this->copy3Float(this->_rotMax, maxRot);
}

void SFConstraint::setMinRotation(float *minRot){
    //assumes a 3-point axis
    this->copy3Float(this->_rotMin, minRot);
}

void SFConstraint::setPivot(float *pivot){
    //assumes a 3-point axis
    this->copy3Float(this->_pivot, pivot);
}