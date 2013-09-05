/*
 *  SFTokens.m
 *  ZombieArcade
 *
 *  Created by Adam Iredale on 27/03/10.
 *  Copyright 2010 Stormforge Software. All rights reserved.
 *
 */

#include "SFTokens.h"
#include "SFUtils.h"
#include "SFDebug.h"

SFTokens::SFTokens(){
    this->_rootName = NULL;
    this->_tokenCount = 0;
    this->_tokenName = NULL;
    this->_tokenValue = NULL;
    this->_tokenPos = 0;
}

SFTokens::~SFTokens(){
    //dealloc memory
    for (int i = this->_tokenCount - 1; i >= 0; --i) {
        if (this->_tokenName[i]) {
            free(this->_tokenName[i]);
            this->_tokenName[i] = NULL;
        }
        if (this->_tokenValue[i]) {
            free(this->_tokenValue[i]);
            this->_tokenValue[i] = NULL;
        }
    }
    free(this->_tokenName);
    this->_tokenName = NULL;
    free(this->_tokenValue);
    this->_tokenValue = NULL;
    if (this->_rootName) {
        free(this->_rootName);
        this->_rootName = NULL;
    }
}

void SFTokens::reset(){
    this->_tokenPos = -1;
}

void SFTokens::valueToFloats(int subValues, char* inputValue, int offset){
   // char floatPattern[(subValues * 2) + 1]; //%f how many times?
//    memset_pattern4(&floatPattern, "%f%f", sizeof(char) * subValues * 2);
//    //now our floatpattern will be exactly what we want to use with scanf
//    //eg. %f%f or %f or %f%f%f etc
//    floatPattern[(subValues * 2)] = 0;
//    scanf(floatPattern, _floatArray);
    switch (subValues) {
        case 1:
            sscanf(inputValue, "%f", &this->_floatArray[offset]);
            break;
        case 2:
            sscanf(inputValue, "%f%f", &this->_floatArray[offset], 
                   &this->_floatArray[offset + 1]);
            break;
        case 3:
            sscanf(inputValue, "%f%f%f", &this->_floatArray[offset], 
                   &this->_floatArray[offset + 1], &this->_floatArray[offset + 2]);
            break;
        case 4:
            sscanf(inputValue, "%f%f%f%f", &this->_floatArray[offset], 
                   &this->_floatArray[offset + 1], &this->_floatArray[offset + 2], 
                   &this->_floatArray[offset + 3]);
            break;
        case 5:
            sscanf(inputValue, "%f%f%f%f%f", &this->_floatArray[offset], 
                   &this->_floatArray[offset + 1], &this->_floatArray[offset + 2],
                   &this->_floatArray[offset + 3], &this->_floatArray[offset + 4]);
            break;
        default:
            break;
    }
}

char* SFTokens::tokenName(){
    return this->_tokenName[this->_tokenPos];
}

float* SFTokens::valueAsFloats(int subValues){
    //if subvalues is -1 it means that the first
    //value read will be the count of the rest of
    //the values - otherwise we just scanf the
    //number of floats required
    
    if (subValues == -1) {
        int actualSubValues = 0;
        sscanf(this->valueAsString(), "%d", &actualSubValues);
        //because there are only a few single digit possible
        //values, we use everything past the first char as
        //the second string
        char *newSubString = this->valueAsString();
        ++newSubString;
        //use an offset of 1 to allow us to use the first value 
        //as it is being used here - to specify further content size
        this->_floatArray[0] = actualSubValues;
        this->valueToFloats(actualSubValues, newSubString, 1);
    } else {
        this->valueToFloats(subValues, this->_tokenValue[this->_tokenPos], 0);
    }
    return this->_floatArray;
}

char* SFTokens::valueAsString(){
    return this->_tokenValue[this->_tokenPos];
}

bool SFTokens::tokenIs(char *compareString){
    if (this->tokenIsNull()) {
        return compareString == NULL;
    }
    return strcmp(this->_tokenName[this->_tokenPos], compareString) == 0;
}

bool SFTokens::tokenIsNull(){
    return this->_tokenName[this->_tokenPos] == NULL;
}

bool SFTokens::tokenStartsWith(char *comparePrefix){
    return strncmp(this->_tokenName[this->_tokenPos], comparePrefix, strlen(comparePrefix)) == 0;
}

bool SFTokens::nextToken(){
    if (this->_tokenCount > (this->_tokenPos + 1)) {
        ++this->_tokenPos;
        return true;
    }
    return false;
}

char* SFTokens::rootName(){
    return this->_rootName;
}

int SFTokens::count(){
    return this->_tokenCount;
}

void SFTokens::copyString(char** dest, char* source, int len){
    if (len == 0) {
        return;
    }
    *dest = (char*)calloc(1, sizeof(char) * (len + 1));
    memcpy(*dest, source, sizeof(char) * len);
    //and term the string
    dest[0][len] = 0;
}

void SFTokens::grow(){
    //expand our token storage by one
    ++this->_tokenCount;
    this->_tokenName = (char**)realloc(this->_tokenName, sizeof(char*) * this->_tokenCount);
    this->_tokenValue = (char**)realloc(this->_tokenValue, sizeof(char*) * this->_tokenCount);
    this->_tokenName[this->_tokenCount - 1] = NULL;
    this->_tokenValue[this->_tokenCount - 1] = NULL;
}

const char* SFTokens::className(){
    return "SFTokens";
}

void SFTokens::printContent(){
    //for debugging
    printf("%s\n-=-=-=-=-=-=-=-\nCount:%u\n\n", this->_rootName, this->_tokenCount);
    for (int i = 0; i < this->_tokenCount; ++i) {
        printf("%s\t\t\t=\t%s\n", this->_tokenName[i], this->_tokenValue[i]);
    }
    printf("\n-=-=-=-=-=-=-=-\n");
}

void SFTokens::parseStream(SFStream *stream){
	
    char singleChar;
    bool readingToken = false;
    
    char tokenRoot[SF_MAX_CHAR];
    char tokenName[SF_MAX_CHAR];
    char tokenValue[SF_MAX_CHAR];
    unsigned int tokenRootPos = 0;
    unsigned int tokenNamePos = 0;
    unsigned int tokenValuePos = 0;
    
    BOOL continueToRead;
    size_t readBytes;
    
    while (stream->bytesRemaining() > 0) {
        if (stream->read((unsigned char*)&singleChar, sizeof(char)) > 0){
            switch (singleChar) {
                case 13: //cr
                case 10: //lf
                case '\t':  //tab
                case ' ': //space
                    continue; //move on
                    break;
                case '(': //left bracket
                    
                    //read everything until we hit a right bracket
                    continueToRead = true;
                    readBytes = 0;
                    while (continueToRead) {
                        readBytes = stream->read((unsigned char*)&singleChar, sizeof(char));
                        if (!readBytes) {
                            sfThrow("Unexpected end of stream!!!");
                        }
                        switch (singleChar) {
                            case ')': 
                                continueToRead = NO;
                                break;
                            case '\t': 
                            case ' ': 
                                //skip leading space/tabs
                                if (tokenValuePos == 0) {
                                    continue;
                                }
                                break;
                            case '"':
                                //skip ALL quotes
                                continue;
                                break;
                            default:
                                break;
                        }
                        if (!continueToRead) {
                            break;
                        }
                        tokenValue[tokenValuePos] = singleChar;
                        ++tokenValuePos;
                    };             
                    
                    //if we've never set the root before, set it now
                    if (!readingToken) {
                        //close and reset our root string
                        //tokenRoot[tokenRootPos] = 0;
                        this->copyString(&this->_rootName, tokenRoot, tokenRootPos);
                        tokenRootPos = 0;
                    }
                    
                    //tidy any trailing garbage
                    
                    //trim any trailing space or tab chars
                    for (int i = tokenValuePos - 1; i >= 0; --i){
                        if ((tokenValue[i] == ' ') or (tokenValue[i] == '\t')) {
                            --tokenValuePos;
                        } else {
                            break;
                        }
                    }
                    
                    //then add a token to the array
                    
                    //expand both our arrays by one
                    this->grow();
                    
                    //add the name
                    
                    //close, copy and reset our token name string
                   // tokenName[tokenNamePos] = 0;
                    this->copyString(&this->_tokenName[this->_tokenCount-1], tokenName, tokenNamePos);
                    tokenNamePos = 0;
                    
                    //add the token
                    
                    //the value is finished - close and reset it
                   // tokenValue[tokenValuePos] = 0;
                    this->copyString(&this->_tokenValue[this->_tokenCount-1], tokenValue, tokenValuePos);
                    tokenValuePos = 0;
                    
                    break;
                    
                case '{': //open curly bracket
                    readingToken = YES;
                    break;
                case '}': //close curly bracket
                    readingToken = NO;
                    break;
                default:
                    //everything else - read it into either the root 
                    //or name depending on what we are reading at the moment
                    if (readingToken) {
                        tokenName[tokenNamePos] = singleChar;
                        ++tokenNamePos;
                    } else {
                        tokenRoot[tokenRootPos] = singleChar;
                        ++tokenRootPos;
                    }
                    break;
            }
        }
    }
    
}