/*
 *  SFDebug.mm
 *  ZombieArcade
 *
 *  Created by Adam Iredale on 5/04/10.
 *  Copyright 2010 Stormforge Software. All rights reserved.
 *
 */

#include "SFUtils.h"
#include "SFDebug.h"
#include "pthread.h"

static unsigned char *gCompareData = nil;

void sfPrintThreadStats(){
    sched_param bufferSchedParam;
    int scheduling;
    pthread_t threadId = pthread_self();
    pthread_getschedparam(threadId, &scheduling, &bufferSchedParam);
    printf("\nThreadStats:\tId=%u, Sched=%u, Priority=%u\n", (unsigned int)threadId, scheduling, bufferSchedParam.sched_priority);
}

void sfSleep(int milliseconds){
    //don't hold up the thread....
    usleep(1000 * milliseconds);
}

void sfCheckData(unsigned char *data, int len){
    //check against data we have previously snapped
    int mRet = memcmp(data, gCompareData, len);
    if (mRet == 0) {
        printf("\nCheck data: %dB OK\n", len);
    } else {
        printf("\nCheck data: BAD - differs at %dB\n", mRet);
    }

}

void sfSnapData(unsigned char *data, int len){
    //take samples of data so we can compare them for corruption
    gCompareData = (unsigned char*)realloc(gCompareData, len);
    memcpy(gCompareData, data, len);
}

void sfAssertOutput(bool checkCondition, const char* file, const char *function, int line, char *fmtText, ...){
    if (!checkCondition) {
        va_list args;
        va_start(args, fmtText);
        sfDebugOutput(true, file, function, line, fmtText, va_pass(args));
        va_end(args);
        pthread_kill(pthread_self(), SIGINT);
    }
}

void sfDebugOutput(int debugMe, const char* file, const char *function, int line, char *fmtText, ...){
    if (!debugMe) {
        return;
    }
    NSString *fileName = [[NSString stringWithUTF8String:file] lastPathComponent];
    const char *fileNameUTF = [fileName UTF8String];
    va_list args;
    va_start(args, fmtText); 
    fprintf(stderr, "[Th:%x|t=%07u]%s(%s:%d): ", (unsigned int)[NSThread currentThread], (unsigned int)[SFUtils getAppTime], fileNameUTF, function, line);
    fprintf(stderr, fmtText, va_pass(args));
    fprintf(stderr, "\n");
    va_end(args);
}

void sfThrow(char *fmtText, ...){
	va_list args;
	va_start(args, fmtText);
	fprintf(stderr, "**SF EXCEPTION**");
	fprintf(stderr, fmtText,va_pass(args));
	throw [NSException exceptionWithName:@"_sfException" reason:[NSString stringWithFormat:[NSString stringWithUTF8String:fmtText], va_pass(args)] userInfo:nil];
	va_end(args);
}