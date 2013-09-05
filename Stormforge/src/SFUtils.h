/*
 *  SFUtils.h
 *  ZombieArcade
 *
 *  Created by Adam Iredale on 9/11/09.
 *  Copyright 2009 Stormforge Software. All rights reserved.
 *
 */

#import "SFDefines.h"
#import "SFObject.h"
#import "SFRect.h"
#import "SFColour.h"

@interface SFUtils : SFObject
{
}
+(id)appKeyWindow;
+(void)assert:(BOOL)condition failText:(NSString*)failText;
+(void)sleep:(int)milliseconds;
+(void)debugFloatMatrix:(float*)matrix width:(int)width height:(int)height;
+(void)debugIntMatrix:(GLint*)matrix width:(int)width height:(int)height;
+(void)drawGlBox:(CGRect)boxRect colour:(vec4)colour;
+(int)getRandomPositiveInt:(int)maxRand;
+(id)getRandomFromArray:(NSArray*)src;
+(void)mark:(NSString*)mark;
+(BOOL)fileExistsInBundle:(NSString*)fileName;
+(NSString*)getFilePathFromBundle:(NSString*)fileName;
+(int64_t)getAppTime;
+(void)setAppTime;
+(int64_t)getMSTime;
+(int64_t)getAppTimeDiff:(int64_t)prevTime;
+(id)getNamedClassFromBundle:(NSString*)className;
+(id)getAppendedFilename:(id)filename appendWith:(id)appendWith;
+(void)assertGlContext;
+(void)printOSStatus:(OSStatus)status;
@end

float getAppSecs();
float getAppSecDiff(float priorAppSecs);

//use relative paths (always - just for clarity)
#define SF_SIO2_USE_RELATIVE_PATHS 1

NSAutoreleasePool* sfInitThread(NSString* threadName);
//once a new thread is spawned, this gives the
//new thread a debug name and sets the eagl context

BOOL isDebuggingFile(const char *file);

void sfNotifyProgress(int itemsDone, int maxItems, NSString *statusText);
//notifies any progress windows of the progress of whatever
char* getSFResourcePath(unsigned char itemType);
//btVector3 sfSFVecTobtVector3(SFVec* vecin);
//convert between the oft used things

NSString* sfSIO2cleanString(char* inSIO2str);
//when importing sio2 property strings, they come in 
//with extra quotes - clean them

id sfGetRandomFromArray(NSArray* src);

unsigned char sio2Project( float objx,
                          float objy,
                          float objz,
                          float model   [ 16 ],
                          float proj    [ 16 ],
                          int   viewport[ 4  ],
                          float *winx,
                          float *winy,
                          float *winz );

unsigned char sio2UnProject( float winx,
                            float winy,
                            float winz,
                            float model   [ 16 ],
                            float proj    [ 16 ],
                            int   viewport[ 4  ],
                            float *objx,
                            float *objy,
                            float *objz );
