/*
 *  SFAtlasStrip.mm
 *  ZombieArcade
 *
 *  Created by Adam Iredale on 13/04/10.
 *  Copyright 2010 Stormforge Software. All rights reserved.
 *
 */

#include "SFAtlasStrip.h"

static const GLfloat *breadthStrip = (GLfloat[]){0.0, 1.0, 1.0, 0.0};
static const GLfloat *depthStrip = (GLfloat[]){1.0, 1.0, 0.0, 0.0};

int SFAtlasStrip::cellToStripIndex(float m, float n){
    //- the cell array (strip) is stored in rows so we must offset rows to 
    //get to what we want 
    return (n * this->_cellBreadth + m);
}

SFStripCell SFAtlasStrip::buildCell(float atlasWidth, float atlasHeight, float originX, float originY, 
                                    float cellWidth, float cellHeight, float cellM, float cellN){
    //note - cellM and N are the coordinates of the cell we are building, expressed in cell widths
    //and heights from the first cell, respectively
    
    //our quick formula for this is as follows:
    
    // (originX, originY) + (cellWidth/atlasWidth, cellHeight/atlasHeight) * ((cellM, cellN) + ((0,1,1,0),(0,0,1,0)))
    //
    // the matrixy thing is just a quick way of breaking down a rectangle into scalars and points
    
    float scaledWidth = cellWidth / atlasWidth,
    scaledHeight = cellHeight / atlasHeight;
    
    float scaledOriginX = originX / atlasWidth,
    scaledOriginY = originY / atlasHeight;
    
    SFStripCell cell;
    
    //printf("\n CELL: ");
    
    for (int i = 0; i < POINTS_PER_CELL; ++i){
        cell.point[i] = CGPointMake(((breadthStrip[i] + cellM) * scaledWidth) + scaledOriginX, 
                                    ((depthStrip[i] + cellN) * scaledHeight) + scaledOriginY);
      //  printf("(%.2f, %.2f)->", cell.point[i].x, cell.point[i].y);
    }
    
    //printf("\n");
    
    return cell;
}

SFAtlasStrip::SFAtlasStrip(CGPoint atlasDimensions, CGRect firstCell, CGPoint cellArea){
    //given the atlas dimensions, the first cell and the area of cells (given in cell heights and widths)
    //we build a fully indexed atlas strip
    //- UV coordinates are expressed (over the atlas at least) in points between 0.0,0.0 and 1.0,1.0,
    //0.0,0.0 being the top-leftmost point and 1.0,1.0 being the bottom-rightmost point
    //- the firstcell dimensions and offset is given in actual image coordinates, as is the atlas dimension
    //- the cell area tells us how many cells broad and deep this strip is - each cell requires 8 floats
    //to describe it - (this could be better using triangle strips but it's not important enough right
    //now) - that's 4 * 2 float-sets
    
    this->_cellBreadth = cellArea.x;
    this->_cellDepth = cellArea.y;
    
    this->_strip = (SFStripCell*)malloc(cellArea.x * cellArea.y * sizeof(SFStripCell));
    
    int stripOffset = 0; //easier on the CPU than calling cellToStripIndex each time
    
    for (int i = 0; i < cellArea.y; ++i) {
        for (int j = 0; j < cellArea.x; ++j) {
            this->_strip[stripOffset] = this->buildCell(atlasDimensions.x,
                                                        atlasDimensions.y,
                                                        firstCell.origin.x,
                                                        firstCell.origin.y,
                                                        firstCell.size.width,
                                                        firstCell.size.height,
                                                        j, i);
            ++stripOffset;
        }
    }
}

SFAtlasStrip::~SFAtlasStrip(){
    //dealloc it all
    free(this->_strip);
}

GLfloat* SFAtlasStrip::cellPoints(CGPoint cellIndex){
    //returns a const pointer to the appropriate place in the strip array
    //where cell (m,n) begins (converting from 2d to 1d array in the process)
    return (GLfloat*)&this->_strip[this->cellToStripIndex(cellIndex.x, cellIndex.y)];
}

GLfloat* SFAtlasStrip::linearCellPoints(int cellOffset){
    //just a straight up reference to the first point of the nth cell in the array
    return (GLfloat*)&this->_strip[cellOffset];
}