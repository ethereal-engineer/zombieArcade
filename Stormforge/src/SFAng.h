/*
 *  SFAng.h
 *  ZombieArcade
 *
 *  Created by Adam Iredale on 5/04/10.
 *  Copyright 2010 Stormforge Software. All rights reserved.
 *
 */

//angluar subclass of SFVec

#include "SFVec.h"

class SFAng : public SFVec {
public:
    SFAng(int count) : SFVec(count){};
    void anglesPositive();
    void clamp360();
};