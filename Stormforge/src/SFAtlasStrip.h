/*
 *  SFAtlasStrip.h
 *  ZombieArcade
 *
 *  Created by Adam Iredale on 13/04/10.
 *  Copyright 2010 Stormforge Software. All rights reserved.
 *
 */

#ifndef SFATLASSTRIP_H

#include "SFObj.h"
#include <OpenGLES/ES1/gl.h>

//a strip of atlas cells, each of which is made up of
//a rectangle of four sets of 2d-coordinates

#define POINTS_PER_CELL 4

typedef struct{
    CGPoint point[POINTS_PER_CELL];
} SFStripCell;

class SFAtlasStrip : public SFObj {
private:
    SFStripCell *_strip;
    float _cellBreadth, _cellDepth;
    int cellToStripIndex(float m, float n);
    SFStripCell buildCell(float atlasWidth, float atlasHeight, 
                          float originX, float originY, 
                          float cellWidth, float cellHeight,
                          float cellM, float cellN);
public:
    SFAtlasStrip(CGPoint atlasDimensions, CGRect firstCell, CGPoint cellArea);
    ~SFAtlasStrip();
    GLfloat* cellPoints(CGPoint cellIndex);
    GLfloat* linearCellPoints(int cellOffset);
};

#define SFATLASSTRIP_H
#endif