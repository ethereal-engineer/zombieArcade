/*
 *  SFAL.h
 *  ZombieArcade
 *
 *  Created by Adam Iredale on 9/04/10.
 *  Copyright 2010 Stormforge Software. All rights reserved.
 *
 */

//sound manager for ES EF!!! :)

#ifndef SFAL_H

#include <AudioToolbox/AudioServices.h>
#include <AudioToolbox/AudioToolbox.h>
#include <OpenAL/alc.h>
#include <OpenAL/al.h>
#include "ogg.h"
#include "vorbisfile.h"
#include "SFTransform.h"
#include "SFObj.h"
#include <pthread.h>

#define DEBUG_SFAL 0
#define SF_STREAMED_AUDIO_BUFFER_SIZE 8196
#define SF_STREAMED_AUDIO_BUFFER_COUNT 16

typedef enum {
    SF_VOLUME_CATEGORY_SFX,
    SF_VOLUME_CATEGORY_AMBIENT,
    SF_VOLUME_CATEGORY_ALL
} SF_VOLUME_CATEGORY;

#include <AudioToolbox/AudioQueue.h>
#include <AudioToolbox/AudioFile.h>
#include <AudioToolbox/ExtendedAudioFile.h>

static const int kNumberBuffers = 3;                              

struct AQPlayerState {
    AudioStreamBasicDescription   mDataFormat;                    
    AudioQueueRef                 mQueue;                        
    AudioQueueBufferRef           mBuffers[kNumberBuffers];       
    AudioFileID                   mAudioFile;                     
    UInt32                        bufferByteSize;                 
    SInt64                        mCurrentPacket;                 
    UInt32                        mNumPacketsToRead;              
    AudioStreamPacketDescription  *mPacketDescs;                 
    bool                          mIsRunning;                     
    bool                          mFlushed;
};

class SFAL : SFObj {
    AQPlayerState       _musicPlayerState;
    ALCdevice			*_ALCDevice;
    ALCcontext			*_ALCContext;
    ov_callbacks		 _ovCallbacks;    
    ALfloat             _volumes[SF_VOLUME_CATEGORY_ALL];
    pthread_t           *_bufferThread;
    ALuint              *_bufferSources;
    OggVorbis_File      **_oggVorbisFiles;
    vorbis_info         **_vorbisInfos;
    int                 _bufferSourceCount;
    ALenum              _lastALError;       //the last openal error
    OSStatus            _lastASError;         //the last audio session error
public:
    SFAL();
    ~SFAL();
    
    ov_callbacks ovCallbacks();
    
    void updateListener(SFTransform *transform);
    
    void suspendSound();
    void resumeSound();
    
    ALfloat volume(unsigned char volumeCategory);
    void setVolume(unsigned char volumeCategory, ALfloat volume);
    
    void addBufferSource(ALuint source, 
                         OggVorbis_File *oggFile, 
                         vorbis_info *vorbisInfo);
    void removeBufferSourceAtIndex(int index);
    void startBufferThread();
    void resumeBufferThread();
    void pauseBufferThread();
    void finishBufferThread();
    
    bool getMuteState();
    
    bool bufferSources();
    void fillSourceBuffers(ALuint source, 
                            OggVorbis_File *oggFile,
                            vorbis_info *vorbisInfo, 
                            ALuint *buffers, 
                            ALint bufferCount);
    void fillBuffer(ALuint buffer, 
                    OggVorbis_File *oggFile,
                    ALenum pcmFormat, 
                    ALsizei frequency);
    
    void ensureContext();
    void waitForFinalBuffer(ALuint source);
    void updateLastError(const char *file, const char *function, int line, ALenum errorValue);
    char* decipherALError(ALenum errorValue);
    char* decipherOggError(int ovRet);
    void playStreamedMusic(const char *filePath);
    void stopStreamedMusic();
    void startOpenAL();
    static SFAL *instance();
    static void shutdown();
};

#define SFAL_H
#endif