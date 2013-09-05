/*
 *  SFAng.cpp
 *  ZombieArcade
 *
 *  Created by Adam Iredale on 5/04/10.
 *  Copyright 2010 Stormforge Software. All rights reserved.
 *
 */

#include "SFAng.h"

void SFAng::anglesPositive(){
    //if there are angles expressed in +/- 180 degrees,
    //positivise them
    for (int i = 0; i < this->_count; ++i) {
        if (this->_floats[i] < 0){
            this->_floats[i] += 360.0f;
            //printf("%x floats now %x->%x\n", this, &this->_floats, this->_floats);
        }
    }
}

void SFAng::clamp360(){
    //if the angles are greater than or equal to 360, remove the excess
    for (int i = 0; i < this->_count; ++i) {
        this->_floats[i] = fmodf(this->_floats[i], 360.0f);
    }    
}