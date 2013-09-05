/*
 *  SFDebug.h
 *  ZombieArcade
 *
 *  Created by Adam Iredale on 5/04/10.
 *  Copyright 2010 Stormforge Software. All rights reserved.
 *
 */

template<char count>
struct SVaPassNext{
    SVaPassNext<count-1> big;
    unsigned long dw;
};

template<> struct SVaPassNext<0>{};

class CVaPassNext{
public:
    SVaPassNext<50> svapassnext;
    CVaPassNext(va_list & args){
		try{//to avoid access violation
			
			memcpy(&svapassnext, args, sizeof(svapassnext));
		} catch (...) {}
    }
};

#define va_pass(valist) CVaPassNext(valist).svapassnext

void sfThrow(char *fmtText, ...);

#define sfAssert(bool, ...) sfAssertOutput(bool, __FILE__, __FUNCTION__, __LINE__, __VA_ARGS__);

//ensure that debugging DOES NOT affect release
#ifdef sfDebug
#undef sfDebug
#endif
#if SF_DEBUG
//real debugging
#define sfDebug(int, ...) sfDebugOutput(int, __FILE__, __FUNCTION__, __LINE__, __VA_ARGS__)
#else
//nop debugging
#define sfDebug(...) NULL
#endif

void sfPrintThreadStats();
void sfSleep(int milliseconds);
void sfSnapData(unsigned char *data, int len);
void sfCheckData(unsigned char *data, int len);
void sfAssertOutput(bool checkCondition, const char* file, const char *function, int line, char *fmtText, ...);
void sfDebugOutput(int debugMe, const char* file, const char *function, int line, char *fmtText, ...);
//sends a debug output with full stack over to the console
