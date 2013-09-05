/*
 *  SFStream.mm
 *  ZombieArcade
 *
 *  Created by Adam Iredale on 25/03/10.
 *  Copyright 2010 Stormforge Software. All rights reserved.
 *
 */

#include "SFStream.h"

SFStream::SFStream(){
    this->resetAll();
}

SFStream::~SFStream(){
    this->close();
}

void SFStream::resetAll(){
    this->_data = NULL;
    this->_fileName = NULL;
    this->_fileHandle = NULL;
    this->_open = false;
    this->_size = 0;
    this->_pos = 0;
    this->_pointer = NULL;
}

size_t SFStream::bytesRemaining(){
    //return the number of bytes remaining in the stream
    return this->size() - this->tell();
}

size_t SFStream::readLocal(unsigned char *buffer, size_t maxLength){
    size_t readBytes = this->bytesRemaining();
    if (!readBytes) {
        return 0;
    }
    if (maxLength < readBytes ) {
        readBytes = maxLength;
    }
    //then just copy it using memcpy
    memcpy(buffer, this->_pointer, readBytes);
    //advance the pointer and pos
    this->seekLocal(readBytes, SEEK_CUR);
    return readBytes;
}

size_t SFStream::readFile(unsigned char *buffer, size_t maxLength){
    size_t bytesRead = fread(buffer, 1, maxLength, this->_fileHandle);
    //update the pos
    this->_pos += bytesRead;
    return bytesRead;
}

void SFStream::seekFile(size_t offset, int seekFrom){
    fseek(this->_fileHandle, offset, seekFrom);
    //update the pos
    this->_pos = ftell(this->_fileHandle);
}

size_t SFStream::read(unsigned char *buffer, size_t maxLength){
    //if we have a file handle open, read from that
    //otherwise, read from our local data buffer
    if (this->_fileHandle) {
        return this->readFile(buffer, maxLength);
    } else {
        return this->readLocal(buffer, maxLength);
    }

}

void SFStream::write(unsigned char *buffer, size_t len){
    if (!this->_data) {
        return; //can't write - buffer not ready
    }
    if (this->bytesRemaining() < len) {
        return; //i am not overwriting my limits!
    }
    //otherwise, just memcpy it - we aren't writing
    //to file just now
    memcpy(this->_pointer, buffer, len);
    //then seek the pointer
    this->seekLocal(len, SEEK_CUR);
}

char* SFStream::fileName(){
    return this->_fileName;
}

unsigned char* SFStream::readPtr(size_t len){
    //read a certain amount of data and return a 
    //pointer to the head of that read data
    //if we are reading a file, we use the
    //local buffer as storage
    //if we are reading from the buffer,
    //we just return a pointer to the current
    //location then advance len bytes
    if (this->_fileHandle) {
        this->allocBuffer(len);
        this->readFile(this->_data, len);
        return this->_pointer;
    } else {
        unsigned char *ptr = &this->_data[this->_pos];
        this->seekLocal(len, SEEK_CUR);
        return ptr;
    }
}

void SFStream::copyFileName(char *fileName){
    //copy the filename to our own place
    int nameLen = strlen(fileName);
    this->_fileName = (char *)malloc(sizeof(char) * (nameLen + 1));
    this->_fileName[nameLen] = 0; //term it
    strcpy(this->_fileName, fileName);
}

bool SFStream::openFile(char *fileName){
    if (this->_open) {
        return false; //already open!!!
    }
    //just want to open for reading
    this->_fileHandle = fopen(fileName, "rb");
    //check that it's a good handle
    if (!this->_fileHandle) {
        return false;
    }
    this->_open = true;
    //we will also keep the filename for
    //reference
    this->copyFileName(fileName);
    //all ready to read
    return true;
}

void SFStream::allocBuffer(size_t bufferSize){
    this->_data = (unsigned char*)realloc(this->_data, bufferSize);
    //setup the pointer to point correctly
    this->_pointer = &this->_data[0];
    //set the pos
    this->_pos = 0;
    //and the size
    this->_size = bufferSize;
}

size_t SFStream::bufferEntireFile(){
    //in the case we want to close the file
    //stream and read it all from memory
    //(faster read - but more memory required)
    //returns size of file
    if (!_open) {
        return -1; //not open!
    }
    //alloc the space we need
    this->allocBuffer(this->size());
    //read the WHOLE file in one go
    fread(this->_data, 1, this->size(), this->_fileHandle);
    //close the file pointer
    this->closeFileOnly();
    //now we have the whole thing in memory
    return this->size();
}

size_t SFStream::tell(){
    //return the position of the cursor
    return this->_pos;
}

void SFStream::openBuffer(char *bufferName, size_t bufferSize){
    //we want to open a memory buffer to write into
    //from somewhere else - we also want to name it
    this->copyFileName(bufferName);
    this->allocBuffer(bufferSize);
    this->_open = true;
}

void SFStream::closeFileOnly(){
    if (this->_fileHandle != NULL) {
        fclose(this->_fileHandle);
        this->_fileHandle = NULL;
    }
}

void SFStream::close(){
    if (!this->_open) {
        return; //skip dummy requests
    }
    //if we opened a file, close it
    //if we created a buffer, destroy it
    this->closeFileOnly();
    
    if (this->_data != NULL) {
        free(this->_data);
    }
    //filenames are also useless at this point
    if (this->_fileName) {
        free(this->_fileName);
    }
    this->resetAll();
}

void SFStream::seekLocal(size_t offset, int seekFrom){
    switch (seekFrom) {
        case SEEK_SET:
            //just jump straight to it
            this->_pos = offset;
            break;
        case SEEK_END:
            this->_pos = this->_size - offset;
            break;
        default:
            //SEEK_CUR
            this->_pos += offset;
            break;
    }
    //jump to the new pos
    this->_pointer = &this->_data[this->_pos];
}

void SFStream::seek(size_t offset, int seekFrom){
    //if we have a file handle, use that, otherwise,
    //seek local
    if (this->_fileHandle != NULL) {
        this->seekFile(offset, seekFrom);
    } else {
        this->seekLocal(offset, seekFrom);
        //the above already updates the pos
    }
}

size_t SFStream::size(){
    if (this->_size == 0) {
        //size not found - find it now
        //get the size of the file by seeking to the end
        //and back
        size_t currentPos = this->tell();
        this->seek(0, SEEK_END);
        this->_size = this->tell();
        this->seek(currentPos, SEEK_SET);
    }
    return this->_size;
}

