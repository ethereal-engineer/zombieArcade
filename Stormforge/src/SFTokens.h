/*
 *  SFTokens.h
 *  ZombieArcade
 *
 *  Created by Adam Iredale on 27/03/10.
 *  Copyright 2010 Stormforge Software. All rights reserved.
 *
 */

//instead of using a fat dictionary with NSString-based storage,
//this thin tokens approach will be used to init objects from files

#include "SFStream.h"
#include "SFObj.h"

#define MAX_TOKEN_SUBVALUES 5

class SFTokens : public SFObj {
    char *_rootName;
    char **_tokenName;
    char **_tokenValue;
    int _tokenCount;
    //for later browsing
    int _tokenPos;
    float _floatArray[MAX_TOKEN_SUBVALUES];
protected:
    const char* className();
    void printContent();
private:
    void grow();
    void copyString(char** dest, char* source, int len);
    void valueToFloats(int subValues, char* inputValue, int offset);
public:
    SFTokens();
    ~SFTokens();
    void parseStream(SFStream *stream);
    char *rootName();
    int count();
    void print();
    void reset();
    bool nextToken();
    char *tokenName();
    float *valueAsFloats(int subValues);
    char *valueAsString();
    bool tokenIs(char *compareString);
    bool tokenIsNull();
    bool tokenStartsWith(char *comparePrefix);
};