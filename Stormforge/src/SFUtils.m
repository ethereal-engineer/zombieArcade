/*
 *  SFUtils.m
 *  ZombieArcade
 *
 *  Created by Adam Iredale on 9/11/09.
 *  Copyright 2009 Stormforge Software. All rights reserved.
 *
 */

#include "SFUtils.h"
#include "SFSceneManager.h"
#import "EAGLView.h"
#import "SFGameEngine.h"
#import "SFDebug.h"
#include <sys/time.h>

//the time that we can safely write off as having been
//passed since before our app started
// - 1/1/2010 - (current choice)
//note that leap seconds aren't counted (it's approximate)
// i.e. 9 * 356 * 1440 * 60
#define SF_SECONDS_SINCE_2001 283824000.0
#define SF_APP_BASE_TIME NSTimeIntervalSince1970 + SF_SECONDS_SINCE_2001
#define sfRandom() (arc4random() % ((unsigned)RAND_MAX + 1))

static int64_t _gAppStartms = 0;

@implementation SFUtils

+(void)debugFloatMatrix:(float*)matrix width:(int)width height:(int)height{
    //print the matrix out so we can see wtf is the matter...
    for (int y = 0; y < height; ++y) {
        printf("[\t");
        for (int x = 0; x < width; ++x) {
            printf("%.2f\t", matrix[x+(y*width)]);
        }
        printf("]\n");
    }
    printf("\n");
}

+(void)debugIntMatrix:(GLint*)matrix width:(int)width height:(int)height{
    //print the matrix out so we can see wtf is the matter...
    for (int y = 0; y < height; ++y) {
        printf("[\t");
        for (int x = 0; x < width; ++x) {
            printf("%d\t", matrix[x+(y*width)]);
        }
        printf("]\n");
    }
    printf("\n");
}

+(void)sleep:(int)milliseconds{
    //don't hold up the thread....
    //ten seperate instructions of 1/10 ms sleep
    usleep(100 * milliseconds);
    usleep(100 * milliseconds);
    usleep(100 * milliseconds);
    usleep(100 * milliseconds);
    usleep(100 * milliseconds);
    usleep(100 * milliseconds);
    usleep(100 * milliseconds);
    usleep(100 * milliseconds);
    usleep(100 * milliseconds);
    usleep(100 * milliseconds);
}

+(void)drawGlLine:(SFRect*)lineVec colour:(SFColour*)colour{
//    [self assertGlContext];
//    float line[4] = {[lineVec getW], [lineVec getX], [lineVec getY], [lineVec getZ]};
//    
//    SFGL::instance()->glColor4f([colour getGlArray]);
//    
//    SFGL::instance()->glVertexPointer(2, GL_FLOAT, 0, &line);
//    SFGL::instance()->glDrawArrays(GL_LINE_STRIP, 0, 2);	
}

+(void)drawGlBox:(CGRect)boxRect colour:(vec4)colour{
    [self assertGlContext];
    float box[8] = {0, 0,
        boxRect.size.width, 0,
        boxRect.size.width, boxRect.size.height,
        0, boxRect.size.height};
   // SFGL::instance()->glPushMatrix();
    glTranslatef(boxRect.origin.x, boxRect.origin.y, 0);
    
    SFGL::instance()->glColor4f(colour);
    
    SFGL::instance()->glVertexPointer(2, GL_FLOAT, 0, &box);
    SFGL::instance()->glDrawArrays(GL_LINE_LOOP, 0, 4);	
   // SFGL::instance()->glPopMatrix();
                                  
}

+(void)printOSStatus:(OSStatus)status{
    NSError *error = [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:nil];
    printf("\nOS Status: %s\n", [[error localizedDescription] UTF8String]);
}

+(void)assertGlContext{
    [SFUtils assert:[EAGLContext currentContext] != nil 
           failText:@"MISSING GL CONTEXT"];
}

+(int)getRandomPositiveInt:(int)maxRand{
	if (maxRand == 0) {
		return 0;
	}
	int modRes = (sfRandom()%maxRand);
	return modRes;
}

+(id)appKeyWindow{
    return [[UIApplication sharedApplication] keyWindow];
}

+(id)getRandomFromArray:(NSArray*)src{
	int maxId = [src count];
	if (maxId == 0) {
		sfDebug(TRUE, "WARNING - NO Elements in array (asked for random)");
		return nil;
	}
	double modRes = (sfRandom()%maxId);
	return [src objectAtIndex:modRes];
}

+(void)mark:(NSString*)mark{
	static unsigned int iLastTime = [SFUtils getAppTime];
	sfDebug(TRUE, "%d %s", [SFUtils getAppTime] - iLastTime, [mark UTF8String]);
	iLastTime = [SFUtils getAppTime];
}

+(BOOL)fileExistsInBundle:(NSString*)fileName{
	return [SFUtils getFilePathFromBundle:fileName] != nil;
}

+(NSString*)getFilePathFromBundle:(NSString*)fileName{
	NSBundle *bundle = [NSBundle mainBundle];
	return [bundle pathForResource:[fileName stringByDeletingPathExtension] ofType:[fileName pathExtension]];
}

+(int64_t)getMSTime{
	uint64_t time_base = 0;
	struct timeval t;
	gettimeofday( &t, NULL );
	time_base =  ((t.tv_sec - SF_APP_BASE_TIME) * 1000.0) + (t.tv_usec / 1000.0); 
	return time_base;
}

+(void)setAppTime{
	if (!_gAppStartms) {
		_gAppStartms = [self getMSTime];
		sfDebug(TRUE, "App start time set at %u", _gAppStartms);
	}
}

+(int64_t)getAppTime{
	//returns the number of ms since the app was started
	//allows for at least 49 days of play from app start (32 bit)
	return (unsigned int)([self getMSTime] - _gAppStartms);
}

+(int64_t)getAppTimeDiff:(int64_t)prevTime{
	return [self getAppTime] - prevTime;
}

+(id)getNamedClassFromBundle:(NSString*)className{
	//get the class from the class name
	NSBundle *bundle = [NSBundle mainBundle];
	return [bundle classNamed:className];
}

+(id)getAppendedFilename:(id)filename appendWith:(id)appendWith{
    //adds a string into the filename (between the end of the name and the extension)
    //e.g. textfile.txt -> textfileinserted.txt
    id extension = [filename pathExtension];
    id newFilename = [filename stringByDeletingPathExtension];
    newFilename = [newFilename stringByAppendingString:appendWith];
    return [newFilename stringByAppendingPathExtension:extension];
}

+(void)assert:(BOOL)condition failText:(NSString*)failText{
    //I don't like assertions that don't allow me to break on them
    //this one will stop the thread immediately and allow full backtrace
    if (!condition) {
        if (failText) {
            printf("\n%s\n",[failText UTF8String]);
        }
        pthread_kill(pthread_self(), SIGINT);
    }
}

@end

float getAppSecs(){
    uint64_t time_base = 0;
	struct timeval t;
	gettimeofday( &t, NULL );
	time_base =  ((t.tv_sec - SF_APP_BASE_TIME) * 1000.0) + (t.tv_usec / 1000.0); 
	return (time_base - _gAppStartms) / 1000.0f;    
}

float getAppSecDiff(float priorAppSecs){
    return getAppSecs() - priorAppSecs;
}

//helper routines

void sfNotifyProgress(int itemsDone, int maxItems, NSString *statusText){
	NSArray *array = [NSArray arrayWithObjects:[NSNumber numberWithInt:itemsDone], [NSNumber numberWithInt:maxItems], [NSString stringWithString:statusText], nil];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:@"sfProgressNotification" object:array];
}

//
//btVector3 sio2GetRayTo( SIO2camera *_SIO2camera,
//					   float		_x,
//					   float		_y )
//{
//	SFVec w1, w2;
//	
//	// Do a 2D to 3D conversion evaluating a point of
//	// intersection between the near clipping plane
//	// and the far clipping plane.
//	sio2UnProject( _x,
//				  _y,
//				  0.0f,
//				  _SIO2camera->mat_modelview,
//				  _SIO2camera->mat_projection,
//				  [SFGameEngine sfWindow]->mat_viewport,
//				  &w1.x,
//				  &w1.y,
//				  &w1.z );
//	
//	sio2UnProject( _x,
//				  _y,
//				  1.0f,
//				  _SIO2camera->mat_modelview,
//				  _SIO2camera->mat_projection,
//				  [SFGameEngine sfWindow]->mat_viewport,
//				  &w2.x,
//				  &w2.y,
//				  &w2.z );
//	
//	return btVector3( _SIO2camera->_SIO2transform->loc->x + ( w2.x - w1.x ),
//					 _SIO2camera->_SIO2transform->loc->y + ( w2.y - w1.y ),
//					 _SIO2camera->_SIO2transform->loc->z + ( w2.z - w1.z ) );
//}

NSString* sfSIO2cleanString(char* inSIO2str) {
	return [[[NSString stringWithUTF8String:inSIO2str] stringByReplacingOccurrencesOfString:@"\"" withString:@""] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" "]];
}

//NSString* sfSIO2ResTypeToPath(unsigned char resType){
//	//NSString *prefix;
//	switch (resType) {
//		case SF_IMAGE:
//		case SF_FONT:
//		case SF_MUSIC:
//		case SF_VIDEO:
//		case SF_SOUND:
//			return @"";
//			break;
//		case SF_ACTION:
//			return @"action/";
//			break;
//		default:
//			return [NSString stringWithUTF8String:SF_RESOURCE_PATH[resType]];
//			break;
//	}
//	
//	//switch (resType) {
////		case SIO2_ACTION:
////			prefix = @"action/";
////			break;
////		case SIO2_OBJECT:
////			prefix = @"object/";
////			break;
////		case SIO2_IMAGE:
////			prefix = @"";
////			break;
////		case SIO2_FONT:
////			prefix = @"";
////			break;
////		case SIO2_IPO:
////			prefix = @"ipo/";
////			break;
////
////		default:
////			sfThrow("Unknown resource type!");
////			break;
////	}	
////	return prefix;
//}

id sfGetRandomFromArray(NSArray* src){
	double modRes = (sfRandom()%[src count]);
	return [src objectAtIndex:modRes];
}


//legacy routines

void sio2ExtractPath( char *_fname,
                     char *_ppath,
                     char *_aname )
{
	unsigned int s = sio2StringLen( _fname );
    
	char *curr_pos = strrchr( _fname, '/' );
	
	if( curr_pos )
	{
		memcpy( _ppath, _fname, s - sio2StringLen( curr_pos ) + 1 );
		
		if( _aname )
		{ memcpy( _aname, ( curr_pos + 1 ), sio2StringLen( curr_pos ) ); }
	}
}


float sio2RoundAngle( float _a )
{
	if( _a < 0.0f )
	{ _a = 360.0f + fmodf( _a, 360.0f ); }
    
	_a = fmodf( _a, 360.0f );
    
	return _a;
}


unsigned char sio2Project( float objx,
                          float objy,
                          float objz,
                          float model   [ 16 ],
                          float proj    [ 16 ],
                          int   viewport[ 4  ],
                          float *winx,
                          float *winy,
                          float *winz )
{
	float tin [ 4 ],
    tout[ 4 ];
    
	tin[ 0 ] = objx;
	tin[ 1 ] = objy;
	tin[ 2 ] = objz;
	tin[ 3 ] = 1.0f;
	
	// Get rid of theses lousy macro...
#define M( row, col ) model[ col * 4 + row ]
	
    tout[ 0 ] = M( 0, 0 ) * tin[ 0 ] + M( 0, 1 ) * tin[ 1 ] + M( 0, 2 ) * tin[ 2 ] + M( 0, 3 ) * tin[ 3 ];
    tout[ 1 ] = M( 1, 0 ) * tin[ 0 ] + M( 1, 1 ) * tin[ 1 ] + M( 1, 2 ) * tin[ 2 ] + M( 1, 3 ) * tin[ 3 ];
    tout[ 2 ] = M( 2, 0 ) * tin[ 0 ] + M( 2, 1 ) * tin[ 1 ] + M( 2, 2 ) * tin[ 2 ] + M( 2, 3 ) * tin[ 3 ];
    tout[ 3 ] = M( 3, 0 ) * tin[ 0 ] + M( 3, 1 ) * tin[ 1 ] + M( 3, 2 ) * tin[ 2 ] + M( 3, 3 ) * tin[ 3 ];
#undef M
    
    
#define M( row, col ) proj[ col * 4 + row ]
	
    tin[ 0 ] = M( 0, 0 ) * tout[ 0 ] + M( 0, 1 ) * tout[ 1 ] + M( 0, 2 ) * tout[ 2 ] + M( 0, 3 ) * tout[ 3 ];
    tin[ 1 ] = M( 1, 0 ) * tout[ 0 ] + M( 1, 1 ) * tout[ 1 ] + M( 1, 2 ) * tout[ 2 ] + M( 1, 3 ) * tout[ 3 ];
    tin[ 2 ] = M( 2, 0 ) * tout[ 0 ] + M( 2, 1 ) * tout[ 1 ] + M( 2, 2 ) * tout[ 2 ] + M( 2, 3 ) * tout[ 3 ];
    tin[ 3 ] = M( 3, 0 ) * tout[ 0 ] + M( 3, 1 ) * tout[ 1 ] + M( 3, 2 ) * tout[ 2 ] + M( 3, 3 ) * tout[ 3 ];
#undef M
    
	if( !tin[ 3 ] )
	{ return 0; }
    
	tin[ 0 ] /= tin[ 3 ];
	tin[ 1 ] /= tin[ 3 ];
	tin[ 2 ] /= tin[ 3 ];
    
	*winx = viewport[ 0 ] + ( 1.0f + tin[ 0 ] ) * viewport[ 2 ] * 0.5f;
	*winy = viewport[ 1 ] + ( 1.0f + tin[ 1 ] ) * viewport[ 3 ] * 0.5f;
	*winz = ( 1.0f + tin[ 2 ] ) * 0.5f;
	
	return 1;
}


unsigned char sio2UnProject( float winx,
                            float winy,
                            float winz,
                            float model   [ 16 ],
                            float proj    [ 16 ],
                            int   viewport[ 4  ],
                            float *objx,
                            float *objy,
                            float *objz )
{
	int i = 0;
	
	float m   [ 16 ],
    a   [ 16 ],
    tin  [ 4  ],
    tout [ 4  ],
    temp[ 16 ],
    wtmp[ 4  ][ 8 ],
    m0,
    m1,
    m2,
    m3,
    s,
    *r0,
    *r1,
    *r2,
    *r3;
    
	tin[ 0 ] = ( winx - viewport[ 0 ] ) * 2.0f / viewport[ 2 ] - 1.0f;
	tin[ 1 ] = ( winy - viewport[ 1 ] ) * 2.0f / viewport[ 3 ] - 1.0f;
	tin[ 2 ] = 2.0f * winz - 1.0f;
	tin[ 3 ] = 1.0f;
	
	// TODO: Get rid of theses lousy macro...
#define A(row,col) proj[ ( col << 2 ) + row ]
	
#define B(row,col) model[ ( col << 2 ) + row ]
	
#define T(row,col) temp[ ( col << 2 ) + row ]
    
    while( i != 4 )
    {
        T( i, 0 ) = A( i , 0 ) *B( 0, 0 ) + A( i, 1 ) * B( 1,0 ) + A( i, 2 ) *B( 2, 0 ) + A( i, 3) *B( 3, 0 );
        T( i, 1 ) = A( i , 0 ) *B( 0, 1 ) + A( i, 1 ) * B( 1,1 ) + A( i, 2 ) *B( 2, 1 ) + A( i, 3) *B( 3, 1 );
        T( i, 2 ) = A( i , 0 ) *B( 0, 2 ) + A( i, 1 ) * B( 1,2 ) + A( i, 2 ) *B( 2, 2 ) + A( i, 3) *B( 3, 2 );
        T( i, 3 ) = A( i , 0 ) *B( 0, 3 ) + A( i, 1 ) * B( 1,3 ) + A( i, 2 ) *B( 2, 3 ) + A( i, 3) *B( 3, 3 );
        
        ++i;
    }
	
#undef A
#undef B
#undef T
	
	
	memcpy( ( void * )a, ( void * )temp, sizeof( float ) << 4 );
    
    
#define SWAP_ROWS( a, b ) { float *_tmp = a; ( a ) = ( b ); ( b ) = _tmp; }
	
#define MAT( a, r, c ) ( a )[ ( c << 2 ) + ( r ) ]
    
    r0 = wtmp[ 0 ], r1 = wtmp[ 1 ], r2 = wtmp[ 2 ], r3 = wtmp[ 3 ];
    
    r0[ 0 ] = MAT( a, 0, 0 ), r0[ 1 ] = MAT( a, 0, 1 ),
    r0[ 2 ] = MAT( a, 0, 2 ), r0[ 3 ] = MAT( a, 0, 3 ),
    r0[ 4 ] = 1.0f          , r0[ 5 ] = r0[ 6 ] = r0[ 7 ] = 0.0f,
    r1[ 0 ] = MAT( a, 1, 0 ), r1[ 1 ] = MAT( a, 1, 1 ),
    r1[ 2 ] = MAT( a, 1, 2 ), r1[ 3 ] = MAT( a, 1, 3 ),
    r1[ 5 ] = 1.0f, r1[ 4 ] = r1[ 6 ] = r1[ 7 ] = 0.0f,
    r2[ 0 ] = MAT( a, 2, 0 ), r2[ 1 ] = MAT( a, 2, 1 ),
    r2[ 2 ] = MAT( a, 2, 2 ), r2[ 3 ] = MAT( a, 2, 3 ),
    r2[ 6 ] = 1.0f          , r2[ 4 ] = r2[ 5 ] = r2[ 7 ] = 0.0f,
    r3[ 0 ] = MAT( a, 3, 0 ), r3[ 1 ] = MAT( a, 3, 1 ),
    r3[ 2 ] = MAT( a, 3, 2 ), r3[ 3 ] = MAT( a, 3, 3 ),
    r3[ 7 ] = 1.0f          , r3[ 4 ] = r3[ 5 ] = r3[ 6 ] = 0.0f;
    
    if( fabs( r3[ 0 ] ) > fabs( r2[ 0 ] ) )
    { SWAP_ROWS( r3, r2 ); }
    
    if( fabs( r2[ 0 ] ) > fabs( r1[ 0 ] ) )
    { SWAP_ROWS( r2, r1 ); }
    
    if( fabs( r1[ 0 ] ) > fabs( r0[ 0 ] ) )
    { SWAP_ROWS( r1, r0 ); }
    
    if( !r0[0] )
    { return 0; }
    
    
    m1 = r1[ 0 ] / r0[ 0 ];
    m2 = r2[ 0 ] / r0[ 0 ];
    m3 = r3[ 0 ] / r0[ 0 ];
    s  = r0[ 1 ];
    
    r1[ 1 ] -= m1 * s;
    r2[ 1 ] -= m2 * s;
    r3[ 1 ] -= m3 * s;
    s = r0[ 2 ];
    
    r1[ 2 ] -= m1 * s;
    r2[ 2 ] -= m2 * s;
    r3[ 2 ] -= m3 * s;
    s = r0[ 3 ];
    
    r1[ 3 ] -= m1 * s;
    r2[ 3 ] -= m2 * s;
    r3[ 3 ] -= m3 * s;
    s = r0[ 4 ];
    
    if( s )
    {
        r1[ 4 ] -= m1 * s;
        r2[ 4 ] -= m2 * s;
        r3[ 4 ] -= m3 * s;
    }
    s = r0[ 5 ];
    
    if( s )
    {
        r1[ 5 ] -= m1 * s;
        r2[ 5 ] -= m2 * s;
        r3[ 5 ] -= m3 * s;
    }
    s = r0[ 6 ];
    
    if( s )
    {
        r1[ 6 ] -= m1 * s;
        r2[ 6 ] -= m2 * s;
        r3[ 6 ] -= m3 * s;
    }
    s = r0[ 7 ];
    
    if (s != 0.0)
    {
        r1[ 7 ] -= m1 * s;
        r2[ 7 ] -= m2 * s;
        r3[ 7 ] -= m3 * s;
    }
    
    if( fabs( r3[ 1 ] ) > fabs( r2[ 1 ] ) )
    { SWAP_ROWS( r3, r2 ); }
    
    if( fabs( r2[ 1 ] ) > fabs( r1[ 1 ] ) )
    { SWAP_ROWS( r2, r1 ); }
    
    if( !r1[ 1 ] )
    { return 0; }
    
    m2 = r2[ 1 ] / r1[ 1 ];
    m3 = r3[ 1 ] / r1[ 1 ];
    
    r2[ 2 ] -= m2 * r1[ 2 ];
    r3[ 2 ] -= m3 * r1[ 2 ];
    r2[ 3 ] -= m2 * r1[ 3 ];
    r3[ 3 ] -= m3 * r1[ 3 ];
    s = r1[ 4 ];
    
    if( s )
    {
        r2[ 4 ] -= m2 * s;
        r3[ 4 ] -= m3 * s;
    }
    s = r1[ 5 ];
    
    if( s )
    {
        r2[ 5 ] -= m2 * s;
        r3[ 5 ] -= m3 * s;
    }
    s = r1[ 6 ];
    
    if( s )
    {
        r2[ 6 ] -= m2 * s;
        r3[ 6 ] -= m3 * s;
    }
    s = r1[ 7 ];
    
    if( s )
    {
        r2[ 7 ] -= m2 * s;
        r3[ 7 ] -= m3 * s;
    }
    
    if( fabs( r3[ 2 ] ) > fabs( r2[ 2 ] ) )
    { SWAP_ROWS( r3, r2 ); }
    
    if( !r2[ 2 ] )
    { return 0; }
    
    m3 = r3[ 2 ] / r2[ 2 ];
    r3[ 3 ] -= m3 * r2[ 3 ], r3[ 4 ] -= m3 * r2[ 4 ],
    r3[ 5 ] -= m3 * r2[ 5 ], r3[ 6 ] -= m3 * r2[ 6 ], r3[ 7 ] -= m3 * r2[ 7 ];
    
    
    if( !r3[ 3 ] )
    { return 0; }
    
    s = 1.0f / r3[ 3 ];
    r3[ 4 ] *= s;
    r3[ 5 ] *= s;
    r3[ 6 ] *= s;
    r3[ 7 ] *= s;
    
    m2 = r2[ 3 ];
    s = 1.0f / r2[ 2 ];
    r2[ 4 ] = s * ( r2[ 4 ] - r3[ 4 ] * m2 ), r2[ 5 ] = s * ( r2[ 5 ] - r3[ 5 ] * m2 ),
    r2[ 6 ] = s * ( r2[ 6 ] - r3[ 6 ] * m2 ), r2[ 7 ] = s * ( r2[ 7 ] - r3[ 7 ] * m2 );
    
    m1 = r1[ 3 ];
    r1[ 4 ] -= r3[ 4 ] * m1, r1[ 5 ] -= r3[ 5 ] * m1,
    r1[ 6 ] -= r3[ 6 ] * m1, r1[ 7 ] -= r3[ 7 ] * m1;
    
    m0 = r0[3];
    r0[ 4 ] -= r3[ 4 ] * m0, r0[ 5 ] -= r3[ 5 ] * m0,
    r0[ 6 ] -= r3[ 6 ] * m0, r0[ 7 ] -= r3[ 7 ] * m0;
    
    m1 = r1[ 2 ];
    s = 1.0f / r1[ 1 ];
    r1[ 4 ] = s * ( r1[ 4 ] - r2[ 4 ] * m1 ), r1[ 5 ] = s * ( r1[ 5 ] - r2[ 5 ] * m1 ),
    r1[ 6 ] = s * ( r1[ 6 ] - r2[ 6 ] * m1 ), r1[ 7 ] = s * ( r1[ 7 ] - r2[ 7 ] * m1 );
    
    m0 = r0[ 2 ];
    r0[ 4 ] -= r2[ 4 ] * m0, r0[ 5 ] -= r2[ 5 ] * m0,
    r0[ 6 ] -= r2[ 6 ] * m0, r0[ 7 ] -= r2[ 7 ] * m0;
    
    m0 = r0[ 1 ];
    s = 1.0f / r0[ 0 ];
    r0[ 4 ] = s * ( r0[ 4 ] - r1[ 4 ] * m0 ), r0[ 5 ] = s * ( r0[ 5 ] - r1[ 5 ] * m0 ),
    r0[ 6 ] = s * ( r0[ 6 ] - r1[ 6 ] * m0 ), r0[ 7 ] = s * ( r0[ 7 ] - r1[ 7 ] * m0 );
    
    MAT( m, 0, 0 ) = r0[ 4 ];
    MAT( m, 0, 1 ) = r0[ 5 ], MAT( m, 0, 2 ) = r0[ 6 ];
    MAT( m, 0, 3 ) = r0[ 7 ], MAT( m, 1, 0 ) = r1[ 4 ];
    MAT( m, 1, 1 ) = r1[ 5 ], MAT( m, 1, 2 ) = r1[ 6 ];
    MAT( m, 1, 3 ) = r1[ 7 ], MAT( m, 2, 0 ) = r2[ 4 ];
    MAT( m, 2, 1 ) = r2[ 5 ], MAT( m, 2, 2 ) = r2[ 6 ];
    MAT( m, 2, 3 ) = r2[ 7 ], MAT( m, 3, 0 ) = r3[ 4 ];
    MAT( m, 3, 1 ) = r3[ 5 ], MAT( m, 3, 2 ) = r3[ 6 ];
    MAT( m, 3, 3 ) = r3[ 7 ];
    
#undef MAT
#undef SWAP_ROWS
    
    
#define M(row,col) m[ col * 4 + row ]
	
    tout[ 0 ] = M( 0, 0 ) * tin[ 0 ] + M( 0, 1 ) * tin[ 1 ] + M( 0, 2 ) * tin[ 2 ] + M( 0, 3 ) * tin[ 3 ];
    tout[ 1 ] = M( 1, 0 ) * tin[ 0 ] + M( 1, 1 ) * tin[ 1 ] + M( 1, 2 ) * tin[ 2 ] + M( 1, 3 ) * tin[ 3 ];
    tout[ 2 ] = M( 2, 0 ) * tin[ 0 ] + M( 2, 1 ) * tin[ 1 ] + M( 2, 2 ) * tin[ 2 ] + M( 2, 3 ) * tin[ 3 ];
    tout[ 3 ] = M( 3, 0 ) * tin[ 0 ] + M( 3, 1 ) * tin[ 1 ] + M( 3, 2 ) * tin[ 2 ] + M( 3, 3 ) * tin[ 3 ];
#undef M
    
    
	if( !tout[ 3 ] )
	{ return 0; }
    
	*objx = tout[ 0 ] / tout[ 3 ];
	*objy = tout[ 1 ] / tout[ 3 ];
	*objz = tout[ 2 ] / tout[ 3 ];
    
	return 1;
}


unsigned char sio2IsPow2( int _size )
{
	switch( _size )
	{
		case 2	 : return 1;
		case 4	 : return 1;		
		case 8	 : return 1;
		case 16	 : return 1;
		case 32	 : return 1;
		case 64  : return 1;
		case 128 : return 1;
		case 256 : return 1;
		case 512 : return 1;
		case 1024: return 1;
	}
	
	return 0;	
}


void sio2Sleep( unsigned int _ms )
{
	int microsecs;
    
	struct timeval tv;
    
	microsecs = _ms * 1000;
    
	tv.tv_sec  = microsecs / 1000000;
	tv.tv_usec = microsecs % 1000000;
    
	select( 0, NULL, NULL, NULL, &tv );	
}


unsigned int sio2Randomui( unsigned int _max )
{
	return ( random() % _max ) + 1;
}


//void sio2GenColorIndex( unsigned int  _index,
//                       col4		 *_col )
//{
//	unsigned int i = _index >> 16;
//	
//	_col->r =
//	_col->g =
//	_col->b = 0;
//	_col->a = 255;
//	
//	memcpy( &_col->r, &i, 1 );
//    
//	i = _index >> 8;
//	memcpy( &_col->g, &i, 1 );
//    
//	memcpy( &_col->b, &_index, 1 );	
//    
//	glColor4ub( _col->r,
//               _col->g,
//               _col->b,
//               _col->a );
//}


unsigned int sio2GetNextPow2( unsigned int _s )
{ return ( unsigned int )( powf( 2, ceilf( logf( ( float )_s ) / logf( 2 ) ) ) ); }


float sio2CubicBezier( float t, float a, float b, float c, float d )
{
	float i  = 1.0f - t,
    t2 = t * t,
    i2 = i * i;
	
	return i2 * i * a +  3.0f * t * i2 * b  +  3.0f * t2  * i * c + t2 * t * d;
}



//void sio2LookAt( SFVec *_e,
//                SFVec *_c,
//                SFVec *_u )
//{
//	SFVec f,
//    s,
//    u;
//	
//    float m[ 16 ];
//	
//	memset( m, 0, 64 );
//	
//	sio2SFVecDiff( _c, _e, &f );
//	
//	sio2Normalize( &f, &f );
//    
//	sio2CrossProduct( &f, _u, &s );
//    
//	sio2Normalize( &s, &s );
//    
//	sio2CrossProduct( &s, &f, &u );
//    
//    m[ 0  ] = s.x;
//    m[ 4  ] = s.y;
//    m[ 8  ] = s.z;
//	
//    m[ 1  ] = u.x;
//    m[ 5  ] = u.y;
//    m[ 9  ] = u.z;
//	
//    m[ 2  ] = -f.x;
//    m[ 6  ] = -f.y;
//    m[ 10 ] = -f.z;
//    
//	m[ 15 ] = 1.0f;
//    
//    glMultMatrixf( m );
//	
//	glTranslatef( -_e->x, -_e->y, -_e->z );
//}


float sio2RGBtoFloat( unsigned char _c )
{ return ( float )_c / 255.0f; }


//float sio2GetAngleX( SFVec *_v )
//{ return asinf( _v->z / hypotf( hypotf( _v->x, _v->y ), _v->z ) ) * SF_RAD_TO_DEG; }
//
//
//float sio2GetAngleZ( SFVec *_v )
//{
//	float a = asinf( _v->x / hypotf( _v->x, _v->y ) ) * SF_RAD_TO_DEG;
//    
//	if( _v->y < 0.0f )
//	{ a += 180.0f; }
//	else
//	{ a = 360.0f - a; }
//	
//	return a;
//}


//void sio2Rotate3D( SFVec  *_v1,
//                  float  _ax,
//                  float  _az,
//                  float  _d,
//                  SFVec  *_v2 )
//{ 
//	float cos_a_x = cosf( _ax * SF_DEG_TO_RAD );
//	
//	_v2->x = _v1->x + _d * cos_a_x * sinf( _az * SF_DEG_TO_RAD );
//	_v2->y = _v1->y - _d * cos_a_x * cosf( _az * SF_DEG_TO_RAD );
//	_v2->z = _v1->z + _d * sinf( _ax * SF_DEG_TO_RAD );
//}


void sio2Perspective( float _fovy,
                     float _aspect,
                     float	_zNear,
                     float _zFar )
{
	SFGL::instance()->glMatrixMode(GL_PROJECTION);
	glLoadIdentity();
	{
		float m[ 16 ],
        s,
        c,
        d = _zFar - _zNear,
        r = _fovy * 0.5f * SF_DEG_TO_RAD;
        
		s = sinf( r );
        
		c = cosf( r ) / s;
        
		memset( &m[ 0 ], 0, 64 );
        
		m[ 0  ] = c / _aspect;
		m[ 5  ] = c;
		m[ 10 ] = -( _zFar + _zNear ) / d;
		m[ 11 ] = -1.0f;
		m[ 14 ] = -2.0f * _zFar * _zNear / d;
		
		glMultMatrixf( &m[ 0 ] );
	}
	SFGL::instance()->glMatrixMode(GL_MODELVIEW);
	
}