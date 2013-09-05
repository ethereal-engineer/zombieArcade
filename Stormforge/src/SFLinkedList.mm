/*
 *  SFLinkedList.mm
 *  ZombieArcade
 *
 *  Created by Adam Iredale on 7/04/10.
 *  Copyright 2010 Stormforge Software. All rights reserved.
 *
 */

#include "SFLinkedList.h"

SFLinkedList::SFLinkedList(){
    //reset our pointers
    this->_firstItem = NULL;
    this->_currentItem = NULL;
    this->_prevItem = NULL;
    //NULL our memory space
    this->_memoryCount = 0;
    this->_growableMemory = NULL;
    this->_reclaimableMemory = NULL;
    this->_reclaimableCount = 0;
}

SFLinkedList::~SFLinkedList(){
    //when we go down we have to
    //free our memory areas - both of them
    //if they exist
    if (this->_growableMemory) {
        free(this->_growableMemory);
    }
    if (this->_reclaimableMemory) {
        free(this->_reclaimableMemory);
    }
}

void SFLinkedList::printContent(){
    //a test, really - of the whole list
    SFLinkedListItem *item = this->firstItem();
    int i = 0;
    while (item != NULL) {
        printf("Item: 0x%x\n", item->data);
        item = this->nextItem();
        ++i;
    }
    printf("%u items in total\n", i);
}

const char* SFLinkedList::className(){
    return "SFLinkedList";
}

SFLinkedListItem* SFLinkedList::currentItem(){
    return this->_currentItem;
}

SFLinkedListItem* SFLinkedList::nextItem(){
    if (this->_currentItem) {
        //we have a current item - let's move to the
        //next one
        this->_prevItem = this->_currentItem;
        this->_currentItem = (SFLinkedListItem*)this->_currentItem->nextItem;
        //if the next item is the "first" item
        //then we return null
        if (this->_currentItem == this->_firstItem) {
            return NULL;
        }
        return this->_currentItem;
    } else {
        return NULL;
    }

}

SFLinkedListItem* SFLinkedList::firstItem(){
    //reset our marker for where we stop
    //returning the next item
    this->_prevItem = NULL;
    this->_firstItem = this->_currentItem;
    return this->_currentItem;
}

void SFLinkedList::removeCurrentItem(){
    //to remove an item we break it's link
    //in the chain and allow the previous item
    //to link to the next item (if any)
    if (this->_prevItem) {
        if (this->_prevItem != this->_currentItem) {
            //deal the current item out of the loop
            this->_prevItem->nextItem = this->_currentItem->nextItem;
        } else {
            this->_prevItem = NULL;
        }
    }
    this->relinquishMemory(this->_currentItem);
    //we will move back to the previous item once done
    this->_currentItem = this->_prevItem;
}

void SFLinkedList::relinquishMemory(void* chunk){
    //when we remove an item it relinquishes it's memory
    //so it gets added to the reclaimable memory pool
    this->_reclaimableMemory = (void**)realloc(this->_reclaimableMemory, (this->_reclaimableCount + 1) * sizeof(SFLinkedListItem*));
    this->_reclaimableMemory[_reclaimableCount] = chunk;
    ++this->_reclaimableCount;
}

void *SFLinkedList::reclaimMemory(){
    //if we have reclaimable memory, return it now
    //and reduce our count
    if (this->_reclaimableCount) {
        --this->_reclaimableCount;
        void *reclaimedMemory = this->_reclaimableMemory[_reclaimableCount];
        this->_reclaimableMemory = (void**)realloc(this->_reclaimableMemory, (this->_reclaimableCount) * sizeof(SFLinkedListItem*));
        return reclaimedMemory;
    } else {
        return NULL;
    }
}

void* SFLinkedList::growMemory(){
    //increase our memory useage by one linked list item size
    //this will be cleaned up at dealloc time
    ++this->_memoryCount;
    this->_growableMemory = (SFLinkedListItem*)realloc(this->_growableMemory, this->_memoryCount * sizeof(SFLinkedListItem));
    //return the latest area of grown memory
    return &this->_growableMemory[this->_memoryCount - 1];
}   

void* SFLinkedList::getMemory(){
    //if there is any reclaimable memory we will use that first,
    //otherwise we will grow the memory
    void *reclaimedMemory = this->reclaimMemory();
    if (reclaimedMemory) {
        return reclaimedMemory;
    } else {
        //no reclaimable memory - gotta grow
        //on the down side, that means that we will always take up our
        //max concurrent item size until dealloc - but that's ok (atm)
        return this->growMemory();
    }

}

void SFLinkedList::addItem(void *data){
    //to add an item into this list we
    //insert it immediately between the
    //current item and the next item
    //if any
    SFLinkedListItem *newItem = (SFLinkedListItem*)this->getMemory();
    newItem->data = data;
    newItem->nextItem = newItem;
    
    if (this->_currentItem) {
        newItem->nextItem = this->_currentItem->nextItem;
        this->_currentItem->nextItem = newItem;
    } else {
        this->_currentItem = newItem;
    }

}
