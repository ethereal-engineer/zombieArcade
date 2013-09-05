//
//  SFSound.h
//  ZombieArcade
//
//  Created by Adam Iredale on 6/02/10.
//  Copyright 2010 Stormforge Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SFLoadableGameObject.h"
#import "SFDefines.h"
#import "SFStream.h"
#import "SFVec.h"
#import "SFAL.h"

#define DEBUG_SFSOUND 0

#define SF_NOTIFY_AUDIO_BUFFERED @"SFNotifyAudioBuffered"
#define SF_NOTIFY_VOLUME_CHANGED @"SFNotifyVolumeChanged"
#define SF_SFX_VOLUME @"SFSFXVolume"
#define SF_AMBIENT_VOLUME @"SFAmbientVolume"
#define SF_SOUND_DEFAULT_VOLUME_CATEGORY SF_SFX_VOLUME
#define SF_SOUND_VOLUME_CATEGORY_KEY @"volumeCategory"
#define SF_NOTIFY_BUFFER_PASS_FINISHED @"SFNotifyBufferPassFinished"
#define SF_NOTIFY_BUFFER_SOUND @"SFNotifyBufferSound"

typedef ALvoid	AL_APIENTRY	(*alBufferDataStaticProcPtr) (const ALint bid, ALenum format, ALvoid* data, ALsizei size, ALsizei freq);

@interface SFSound : SFLoadableGameObject {
    
    SFVec *_pos, *_dir, *_vel;
    
	unsigned int	_bid[ SF_STREAMED_AUDIO_BUFFER_COUNT ];
	unsigned int	_curr;
	size_t	_size;
	unsigned int	_rate;
    unsigned char   _volumeCategory;
    float           _length;
	char			*_data;
	OggVorbis_File  _oggVorbisFile;
    vorbis_info     *_vorbisInfo;
    unsigned int	_sid;
    BOOL _isStreaming;
    BOOL _isAmbient;
    BOOL _repeat;
    BOOL _isReady;
    ALint _buffersQueued;
    ALint _buffersProcessed;
    NSString *_lastErrorString;
    unsigned int _lastError;
    ALint _sourceState;
    BOOL _bufferAckFinished;
    float   _currentPitch;
}
-(void)setupSoundSource;
-(void)fullLoad;
-(float)soundLength;
+(SFSound*)quickPlayAmbient:(NSString*)filename;
+(SFSound*)quickPlaySFX:(NSString*)filename position:(SFVec*)position;
+(SFSound*)newStreamAmbient:(NSString*)filename;
+(SFSound*)quickPlayFetch:(NSString*)filename;
-(void)playAsSFX:(SFVec*)position repeat:(BOOL)repeat;
-(void)stopPlaying;
-(void)startPlaying:(BOOL)repeat;
-(void)playAsAmbient:(BOOL)repeat;
-(void)playAsAmbientStream:(BOOL)repeat;
-(void)setVolumeCategory:(unsigned char)volumeCategory;
-(BOOL)readPCMFromAudioStreamIntoALBuffer:(ALuint)bufferName;
-(void)closeFileStream;
-(BOOL)isPlaying;
-(BOOL)isPlayingForceCheck;
-(void)setPitch:(float)pitch;
@end
