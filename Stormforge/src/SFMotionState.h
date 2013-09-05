/*
 *  SFMotionState.h
 *  ZombieArcade
 *
 *  Created by Adam Iredale on 16/04/10.
 *  Copyright 2010 Stormforge Software. All rights reserved.
 *
 */
#include "SFTransform.h"
#include "SF3DObject.h"

//the stormforge motion state to integrate
//with the Bullet Physics engine (cue harmonious dramatic music)

class SFMotionState : public btMotionState {
protected:
    id _graphicsObject;
    btTransform _mPos1;
    void (*_setTransformMethod)(id, SEL, id);
    SEL _setTransformSelector;
public:
    SFMotionState(const btTransform &initialpos, id graphicsObject, SEL setTransformSelector) {
        _graphicsObject = [graphicsObject retain];
        _mPos1 = initialpos;
        _setTransformSelector = setTransformSelector;
        _setTransformMethod = (void (*)(id, SEL, id))[graphicsObject methodForSelector:setTransformSelector];
    }
    
    virtual ~SFMotionState() {
    }
    
    void setNode(id graphicsObject) {
        [_graphicsObject release];
        _graphicsObject = [graphicsObject retain];
    }
    
    virtual void getWorldTransform(btTransform &worldTrans) const {
        worldTrans = _mPos1;
    }
    
    virtual void setWorldTransform(const btTransform &worldTrans) {
        if (_graphicsObject == NULL) return; // silently return before we set a node
        btQuaternion rot = worldTrans.getRotation();
        btVector3 pos = worldTrans.getOrigin();
        _setTransformMethod(_graphicsObject, _setTransformSelector, (id)&worldTrans);
       // [_graphicsObject setTransformFromBtTransform:&worldTrans];
    }
};