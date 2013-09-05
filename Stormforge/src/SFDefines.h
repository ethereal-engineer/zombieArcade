/*
 *  SFDefines.h
 *  ZombieArcade
 *
 *  Created by Adam Iredale on 30/11/09.
 *  Copyright 2009 Stormforge Software. All rights reserved.
 *
 */

//#define SF_DEBUG 1 //override release mode


#define THREAD_PRIORITY_VERY_HIGH 0.9f
#define THREAD_PRIORITY_HIGH 0.8f
#define THREAD_PRIORITY_NORMAL 0.5f
#define THREAD_PRIORITY_LOW 0.2f
#define THREAD_PRIORITY_VERY_LOW 0.1f

//all defines here for build configuration (for now)....

//debugging font
#define DEFAULT_SF_FONT_NAME @"courier16x16.tga"

#define BLENDER_SCALE 1 //our scale in blender....

//image filters
// The default texture image filter mode
#define SF_GAME_TFILTER			SF_IMAGE_QUADLINEAR

// The default image anisotropic filter mode
#define SF_GAME_AFILTER			SF_IMAGE_ISOTROPIC

//notification names
#define SF_NOTIFY_SPLASH_MANAGER_DONE @"SFSplashManagerFinished"
#define SF_NOTIFY_THREAD_RESOURCE_PARSE @"SFNotifyThreadResourceParse"
#define SF_NOTIFY_RENDER_THREAD_UP @"SFNotifyRenderThreadUp"
#define SF_NOTIFY_WIDGET_EVENT @"SFNotifyWidgetEvent"
#define SF_NOTIFY_DISPATCH_OVER @"SFNotifyDispatchOver"
#define	SF_NOTIFY_SAVE_DATA @"SFNotifySaveData"
#define SF_NOTIFY_WIDGETS_PROCESS_TOUCH @"SFNotifyWidgetsProcessTouch"
#define SF_NOTIFY_SF_OBJECT_SPAWNED @"SFNotifySIO2ObjectSpawned"
#define SF_NOTIFY_RESOURCE_READY @"SFNotifyResourceReady"
#define SF_NOTIFY_INVALIDATE_MY_QUEUE_ITEMS @"SFNotifyInvalidateMyQueueItems"
#define SF_NOTIFY_IPO_END @"SFNotifyIPOEnd"
#define SF_NOTIFY_SCENE_BECAME_READY @"SFNotifySceneBecameReady"
#define SF_NOTIFY_SCENE_BECAME_UNREADY @"SFNotifySceneBecameUnReady"
#define SF_NOTIFY_SOUND_BECAME_READY @"SFNotifySoundBecameReady"
#define SF_NOTIFY_LEVEL_OVER @"SFNotifyLevelOver"
#define SF_NOTIFY_ACHIEVEMENT_UNLOCKED @"SFNotifyAchievementUnlocked"
#define SF_NOTIFY_GROUP_ACHIEVEMENT_UNLOCKED @"SFNotifyGroupAchievementUnlocked"
#define SF_NOTIFY_WEAPONS_CHANGED @"SFNotifyWeaponsChanged"
#define SF_NOTIFY_WEAPON_FIRED @"SFNotifyWeaponFired"
#define SF_NOTIFY_WEAPON_DRY_FIRED @"SFNotifyWeaponDryFired"
#define SF_NOTIFY_WEAPON_RELOAD_START @"SFNotifyWeaponReloadStart"
#define SF_NOTIFY_WEAPON_EQUIPPED @"SFNotifyWeaponEquipped"
#define SF_NOTIFY_WEAPON_BECAME_READY @"SFNotifyWeaponBecameReady"
#define SF_NOTIFY_WIDGET_BECAME_FOCUSED @"SFNotifyWidgetBecameFocused"
#define SF_NOTIFY_OBJECT_WAS_HURT @"SFNotifyObjectWasHurt"
#define SF_NOTIFY_LOW_MEMORY @"SFNotifyLowMemory"
#define SF_NOTIFY_DRAW_DEBUG_NOW @"SFNotifyDrawDebugNow"
#define SF_NOTIFY_RESOURCE_EXTRACTED @"SFNotifyResourceExtracted"
#define SF_NOTIFY_RESOURCE_FULL_LOAD_COMPLETE @"SFNotifyResourceFullLoadComplete"
#define SF_NOTIFY_COLLISION @"SFNotifyCollision"
#define SF_NOTIFY_CONSTRAINTS_PROCESSED @"SFNotifyConstraintsProcessed"

#define SF_PERSISTENT_ITEM_KEY @"persistantItem"

#define ALL_OBJECTS_VISIBLE 0

#define SF_CLAMP( x, low, high )( ( x > high ) ? high : ( ( x < low ) ? low : x ) )

#define SF_MAX_CHAR 64
#define SF_MAX_PATH 256

#define SF_PI						3.141593f
#define SF_DEG_TO_RAD				0.017453f
#define SF_RAD_TO_DEG				57.29577f

#define	SF_MAX_LAMPS                8

#define SF_USE_GL_VBOS 0

#if SF_USE_GL_VBOS
#define SF_BUFFER_OFFSET(i, buf)((char*)NULL + i) //ignore the buf
#else
#define SF_BUFFER_OFFSET(i, buf)((char*)buf + i) //use the buf
#endif

typedef enum
{
	SF_FOG					= ( 1 << 0  ),
	SF_BLEND					= ( 1 << 1  ),
	SF_ALPHA_TEST				= ( 1 << 2  ),
	SF_TEXTURE_2D0			= ( 1 << 3  ),
	SF_TEXTURE_2D1			= ( 1 << 4  ),
	SF_COLOR_MATERIAL			= ( 1 << 5  ),
	SF_LIGHTING				= ( 1 << 6  ),
	SF_NORMALIZE				= ( 1 << 7  ),
	SF_POINT_SPRITE			= ( 1 << 8  ),
	SF_POINT_SIZE_ARRAY		= ( 1 << 9  ),
	SF_VERTEX_ARRAY			= ( 1 << 10 ),
	SF_COLOR_ARRAY			= ( 1 << 11 ),
	SF_NORMAL_ARRAY			= ( 1 << 12 ),
	SF_TEXTURE_COORD_ARRAY0	= ( 1 << 13 ),
	SF_TEXTURE_COORD_ARRAY1	= ( 1 << 14 ),
	SF_DEPTH_TEST				= ( 1 << 15 ),
	SF_CULL_FACE				= ( 1 << 16 )
    
} SF_STATE_FLAGS;


typedef struct
{
	unsigned int	flags;
    
	int				a_texture;
	
	int				c_texture;
	
	unsigned char	blend;
	
	float			alpha_value;
	
	id        color;
	
} SFState;

typedef enum
{
	SF_OBJECT_ACTOR		 = ( 1 << 0  ), // 1
	SF_OBJECT_GHOST		 = ( 1 << 1  ),	// 2
	SF_OBJECT_DYNAMIC		 = ( 1 << 2  ), // 4
	SF_OBJECT_RIGIDBODY	 = ( 1 << 3  ), // 8
	SF_OBJECT_SOFTBODY	 = ( 1 << 4  ), // 16
	SF_OBJECT_BILLBOARD	 = ( 1 << 5  ), // 32
	SF_OBJECT_HALO		 = ( 1 << 6  ), // 64
	SF_OBJECT_TWOSIDE		 = ( 1 << 7  ), // 128
	SF_OBJECT_NOSLEEPING	 = ( 1 << 8  ), // 256
	SF_OBJECT_SHADOW		 = ( 1 << 9  ), // 512
	SF_OBJECT_DYNAMIC_DRAW = ( 1 << 10 ), // 1024
	SF_OBJECT_INVISIBLE	 = ( 1 << 11 )  // 2048
	
} SF_OBJECT_FLAGS;


typedef enum
{
	SF_OBJECT_SIZE = 0,
	SF_OBJECT_NORMALS,
	SF_OBJECT_VCOLOR,	
	SF_OBJECT_TEXUV0,
	SF_OBJECT_TEXUV1,
	
	SF_OBJECT_NVBO_OFFSET
	
} SF_OBJECT_VBO_OFFSET;

//third party imports

#import "btBulletDynamicsCommon.h"
#import "btBulletCollisionCommon.h"
#import "btSoftRigidDynamicsWorld.h"
#import "btSoftBodyRigidBodyCollisionConfiguration.h"

typedef struct
{
	unsigned int		frame;
	
	unsigned char		*buf;
	
	unsigned char		type;
    
} SFFrameStruct;

typedef struct
{
	unsigned char				loop;
	
	unsigned char				next_action;
	
	float						t_ratio;
	float						d_time;
	float						interp;
	float						fps;
	
	id                          _action;
	SFFrameStruct   			*_SIO2frame1;
	SFFrameStruct    			*_SIO2frame2;
    
	unsigned int				curr_frame;
	unsigned int				next_frame;
    
	unsigned char				state;
	
} SFObjectAnimationStruct;

//SF_string
int sio2StringScanf( char *, const char *, ... );

static inline unsigned int sio2StringLen( const char *_str )
{
	unsigned int i = 0;
	
	while( _str[ i ] )
	{ ++i; }
	
	return i;
}


static inline int sio2StringCmp( const char *_str1, const char *_str2 )
{
	unsigned int s = sio2StringLen( _str2 );
	
	if( *_str1 != *_str2 )
	{ return 1; }
	
	return memcmp( _str1, _str2, s + 1 );
}


static inline void sio2StringCpy( char *_str1, const char *_str2 )
{ memcpy( _str1, _str2, sio2StringLen( _str2 ) + 1 ); }


static inline char *sio2StringChr( char *_str1, char _str2 )
{
	while( *_str1 )
	{
		++_str1;
        
		if( *_str1 == _str2 )
		{ return _str1; }
	}
	
	return NULL;
}


static inline char *sio2StringTok( char *_str1, char *_str2 )
{
	unsigned int s = sio2StringLen( _str2 );
    
	while( *_str1 )
	{
		if( *_str1 == *_str2 )
		{
			if( s == 1 )
			{ return _str1; }
			
			if( !memcmp( _str1, _str2, s ) )
			{ return _str1; }
		}
		
		++_str1;		
	}
    
	return NULL;
}


static inline void sio2StringToUpper( char *_str )
{
	unsigned int i = 0,
    s = sio2StringLen( _str );
    
	while( i != s )
	{
		_str[ i ] = toupper( _str[ i ] );
		++i;
	}
}


static inline unsigned int sio2StringGetLines( char *_str )
{
	unsigned int i = 0,
    l = sio2StringLen( _str ),
    n = 1;
    
	while( i != l )
	{
		if( _str[ i ] == 10 )
		{ ++n; } 
        
		++i;
	}
    
	return n;
}

typedef enum
{
	SF_PHYSIC_BOX = 0,
	SF_PHYSIC_SPHERE,
	SF_PHYSIC_CYLINDER,
	SF_PHYSIC_CONE,
	SF_PHYSIC_TRIANGLEMESH,
	SF_PHYSIC_CONVEXHULL,
    SF_PHYSIC_CAPSULE
    
} SF_PHYSIC_BOUNDS;

//xiph
#import "ogg.h"
#import "vorbisfile.h"
#import "theora.h"

//opengl es
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>

//openal
#import <OpenAL/al.h>
#import <OpenAL/alc.h>