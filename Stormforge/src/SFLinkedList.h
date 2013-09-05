/*
 *  SFLinkedList.h
 *  ZombieArcade
 *
 *  Created by Adam Iredale on 7/04/10.
 *  Copyright 2010 Stormforge Software. All rights reserved.
 *
 */

//LIGHT circular linked list class for quick adding and removing
//of a sequentially processed list - includes memory management

#include "SFObj.h"

typedef struct{
    void *data;
    void *nextItem;
} SFLinkedListItem;

class SFLinkedList : public SFObj {
    SFLinkedListItem *_growableMemory;
    unsigned int _memoryCount;
    void **_reclaimableMemory;
    unsigned int _reclaimableCount;
    SFLinkedListItem *_prevItem;
    SFLinkedListItem *_currentItem;
    SFLinkedListItem *_firstItem;
private:
    void *growMemory();
    void *getMemory();
    void relinquishMemory(void* chunk);
    void *reclaimMemory();
protected:
    void printContent();
    const char* className();
public:
    SFLinkedList();
    ~SFLinkedList();
    SFLinkedListItem* currentItem();
    SFLinkedListItem* nextItem();
    //the order really isn't important
    //but this call takes note of the current item
    //as this is a circular linked list
    //so we don't circle for ever
    SFLinkedListItem* firstItem();
    void removeCurrentItem();
    void addItem(void *data);
};