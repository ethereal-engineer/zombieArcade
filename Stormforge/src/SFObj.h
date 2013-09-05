/*
 *  SFObj.h
 *  ZombieArcade
 *
 *  Created by Adam Iredale on 7/04/10.
 *  Copyright 2010 Stormforge Software. All rights reserved.
 *
 */

//c++ base class - keep it THIN

#ifndef SFOBJ_H

class SFObj {
protected:
    //if there's any extra stuff to print,
    //override and put it here
    virtual void printContent();
    //override this with class name
    //for debugging only, really
    virtual const char* className();
public:
    //output class and pointer
    void print();
};

#define SFOBJ_H
#endif