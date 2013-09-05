/*
 *  SFStream.h
 *  ZombieArcade
 *
 *  Created by Adam Iredale on 25/03/10.
 *  Copyright 2010 Stormforge Software. All rights reserved.
 *
 */

//a slim and FAST stream class for reading from disk
//based solely on f-stream

#include <stdio.h>
#include "SFObj.h"

class SFStream : public SFObj {
    char *_fileName;
    unsigned char *_data;
    unsigned char *_pointer;
    size_t _size;
    size_t _pos;
    bool _open;
    FILE *_fileHandle;
private:
    void copyFileName(char *fileName);
    void resetAll();
    void allocBuffer(size_t bufferSize);
    void closeFileOnly();
    size_t readLocal(unsigned char *buffer, size_t maxLength);
    void seekLocal(size_t offset, int seekFrom);
    size_t readFile(unsigned char *buffer, size_t maxLength);
    void seekFile(size_t offset, int seekFrom);
public:
    SFStream();
    ~SFStream();
    char* fileName();
    size_t read(unsigned char *buffer, size_t maxLength);
    void write(unsigned char *buffer, size_t len);
    unsigned char* readPtr(size_t len);
    bool openFile(char *fileName);
    size_t bufferEntireFile();
    void openBuffer(char *bufferName, size_t bufferSize);
    void close();
    void seek(size_t offset, int seekFrom);
    size_t tell();
    size_t size();
    size_t bytesRemaining();
};