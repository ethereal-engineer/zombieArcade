/*
 *  SFObj.mm
 *  ZombieArcade
 *
 *  Created by Adam Iredale on 7/04/10.
 *  Copyright 2010 Stormforge Software. All rights reserved.
 *
 */

#include "SFObj.h"

const char* SFObj::className(){
    return "SFObj";
}

void SFObj::print(){
    printf("%s 0x%x {\n", this->className(), (unsigned int)this);
    this->printContent();
    printf("\n}\n");
}

void SFObj::printContent(){
    //nothing here, override for content
}