/*
 *  SFAL.mm
 *  ZombieArcade
 *
 *  Created by Adam Iredale on 9/04/10.
 *  Copyright 2010 Stormforge Software. All rights reserved.
 *
 */

#include "SFAL.h"
#include "SFStream.h"
#include "SFDebug.h"
#include "SFDefines.h"
#include "SFSettingManager.h"

#define BUFFER_THREAD_PRIORITY 46

#define updateALError() this->updateLastError(__FILE__, __FUNCTION__, __LINE__, alGetError())

static SFAL *gSFAL = NULL;

//interruption listener - redirect to sfal
void interruptionListener(void *inClientData, UInt32 inInterruptionState){
    
    SFAL *sfal = (SFAL*)inClientData;
	
    if (inInterruptionState == kAudioSessionBeginInterruption) {
        //this is where we have an incoming phone call
		//or other interruption
        sfal->suspendSound();
	} else if (inInterruptionState == kAudioSessionEndInterruption) {
		//the interruption went away
		sfal->resumeSound();
	}
}

//ogg<->stream functions
long SFOggTell(void *aStream){
	SFStream *input = (SFStream *)aStream;
	return input->tell();
}

int SFOggClose(void *aStream){
	if(aStream){ 
        return true; 
    } else { 
        return false; 
    }
}

size_t SFOggRead(void *ptr, size_t readSize, size_t readCount, void *aStream){
    SFStream *stream = (SFStream *)aStream;
    return stream->read((unsigned char*)ptr, readSize * readCount);
}


int SFOggSeek(void *aStream, ogg_int64_t offset, int stride){
	SFStream *stream = (SFStream *)aStream;
    stream->seek(offset, stride);
	return 0;
}


SFAL::SFAL(){
    //start up sound
    printf("Initialising sound...\n");
#if TARGET_IPHONE_SIMULATOR
#warning *** Simulator mode: not using audio session code (unsupported)
    // Execute subset of code that works in the Simulator
#else
    // Execute device-only code as well as the other code
	UInt32 iPodIsPlaying, audioCategory;
	
    _lastASError = AudioSessionInitialize(NULL, NULL, interruptionListener, this);
	if (_lastASError != kAudioSessionNoError) {
        printf("Error initialising audio\n");
    }
    UInt32 size = sizeof(iPodIsPlaying);
    _lastASError = AudioSessionGetProperty(kAudioSessionProperty_OtherAudioIsPlaying, &size, &iPodIsPlaying);
    if (_lastASError != kAudioSessionNoError){
        printf("Error getting audio session property");
       // sfAssert(false, "Error getting audio session property");
    }
    
    // if the iPod is playing, use the ambient category to mix with it
    // otherwise, use solo ambient to get the hardware for playing the app background track
    if (iPodIsPlaying) {
        //the iPod is playing
        audioCategory = kAudioSessionCategory_AmbientSound;
    } else {
        //the iPod is not playing (clever, huh? LOL)
        audioCategory = kAudioSessionCategory_SoloAmbientSound;
        // since no other audio is *supposedly* playing, then we will make darn sure by changing the audio session category temporarily
        // to kick any system remnants out of hardware (iTunes (or the iPod App, or whatever you wanna call it) sticks around)
        //UInt32   sessionCategory = kAudioSessionCategory_MediaPlayback;
        //			AudioSessionSetProperty(kAudioSessionProperty_AudioCategory, sizeof(sessionCategory), &sessionCategory);
        //			AudioSessionSetActive(YES);
        // now change back to ambient session category so our app honors the "silent switch"
        //sessionCategory = kAudioSessionCategory_AmbientSound;
        //AudioSessionSetProperty(kAudioSessionProperty_AudioCategory, sizeof(sessionCategory), &sessionCategory);
    }

    _lastASError = AudioSessionSetProperty(kAudioSessionProperty_AudioCategory, sizeof(audioCategory), &audioCategory);
    if (_lastASError != kAudioSessionNoError){
        printf("Error setting audio category\n");
    }

    _lastASError = AudioSessionSetActive(YES);
    if (_lastASError != kAudioSessionNoError){
        printf("Error setting audio session active\n");
    }
#endif    
	//normally start openal here
	
    //init the ogg callbacks
    this->_ovCallbacks.read_func  = SFOggRead;
	this->_ovCallbacks.seek_func  = SFOggSeek;
	this->_ovCallbacks.tell_func  = SFOggTell;
	this->_ovCallbacks.close_func = NULL;//SFOggClose;
    
    //set the volume to default levels
    this->_volumes[SF_VOLUME_CATEGORY_AMBIENT] = (float)[SFSettingManager loadFloat:@"ambientVolume"];
    this->_volumes[SF_VOLUME_CATEGORY_SFX] = (float)[SFSettingManager loadFloat:@"sfxVolume"];
    
    //load volumes
    
    //nullify the buffer source list
    this->_bufferSources = NULL;
    this->_oggVorbisFiles = NULL;
    this->_vorbisInfos = NULL;
    this->_bufferSourceCount = 0;
    
    printf("Sound initialised OK\n");
}

bool SFAL::getMuteState(){
#if TARGET_IPHONE_SIMULATOR
#warning *** Simulator mode: always returning false for mute switch state
    return false;
#endif
    CFStringRef audioRoute;
    UInt32 size = sizeof(audioRoute);
    //find out if the mute switch is on or off based on the audio route
    _lastASError = AudioSessionGetProperty(kAudioSessionProperty_AudioRoute, &size, &audioRoute);
    if (_lastASError != kAudioSessionNoError) {
        printf("Error determining audio route");
    } else {
        printf("AudioRoute: %s", [(NSString*)audioRoute UTF8String]);
        if ([(NSString*)audioRoute isEqualToString:@""]) {
            //mute IS on
            return true;
        }
    }    
    return false;
}

void SFAL::startOpenAL(){
    this->_ALCDevice = alcOpenDevice( NULL );
	
	if (this->_ALCDevice) {
		this->_ALCContext = alcCreateContext(this->_ALCDevice, NULL);
		alcMakeContextCurrent(this->_ALCContext);
	}
	
	printf("\nAL_VENDOR:          %s\n", ( char * )alGetString ( AL_VENDOR     ) );
	printf("AL_RENDERER:        %s\n"  , ( char * )alGetString ( AL_RENDERER   ) );
	printf("AL_VERSION:         %s\n"  , ( char * )alGetString ( AL_VERSION    ) );
	printf("AL_EXTENSIONS:      %s\n\n"  , ( char * )alGetString ( AL_EXTENSIONS ) );   
    
    //set the listener values to default
    this->updateListener(nil);
}

void SFAL::updateListener(SFTransform *transform){
    //set master volume to max
    alListenerf(AL_GAIN, 1.0f);
    //if we have a transform, also set position etc
    if (!transform) {
        return;
    }
    float orientation[6] = {0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 1.0f}; //latter 3 are UP
	memcpy(&orientation[0], transform->dir()->floatArray(), transform->dir()->size());
	alListener3f(AL_POSITION,
                 transform->loc()->x(),
                 transform->loc()->y(),
                 transform->loc()->z());
	alListenerfv(AL_ORIENTATION, orientation);
    updateALError();
}

SFAL *SFAL::instance(){
    if (!gSFAL) {
        gSFAL = new SFAL();
    }
    return gSFAL;
}

void SFAL::shutdown(){
    //deletes the instance
    if (gSFAL) {
        delete gSFAL;
        gSFAL = NULL;
    }
}

SFAL::~SFAL(){
    alcMakeContextCurrent(NULL);
    alcDestroyContext(this->_ALCContext);
    alcCloseDevice(this->_ALCDevice);
    //save the volume levels
    [SFSettingManager saveFloat:@"ambientVolume" settingValue:this->_volumes[SF_VOLUME_CATEGORY_AMBIENT]];
    [SFSettingManager saveFloat:@"sfxVolume" settingValue:this->_volumes[SF_VOLUME_CATEGORY_SFX]];
}

ov_callbacks SFAL::ovCallbacks(){
    return this->_ovCallbacks;
}

void SFAL::setVolume(unsigned char volumeCategory, ALfloat volume){
    this->_volumes[volumeCategory] = volume;
    if (volumeCategory == SF_VOLUME_CATEGORY_AMBIENT){
        //update any queues immediately
        if (!_musicPlayerState.mIsRunning) {
            return;
        }
        AudioQueueSetParameter (_musicPlayerState.mQueue,                                       
                                kAudioQueueParam_Volume,      
                                _volumes[SF_VOLUME_CATEGORY_AMBIENT]);
    }
}

ALfloat SFAL::volume(unsigned char volumeCategory){
    return this->_volumes[volumeCategory];
}

void SFAL::suspendSound(){
#if TARGET_IPHONE_SIMULATOR
#warning *** Simulator mode: not suspending sound (audiosession)
    return;
#endif
    //AudioSessionSetActive(NO);
    alcMakeContextCurrent(NULL); //get rid of our openAL sound
    alcSuspendContext(this->_ALCContext);    
}

void SFAL::resumeSound(){
#if TARGET_IPHONE_SIMULATOR
#warning *** Simulator mode: not resuming sound (audiosession)
    return;
#endif    
    if (AudioSessionSetActive(YES) == kAudioSessionNoError) {
        //success
        alcMakeContextCurrent(this->_ALCContext);
        alcProcessContext(this->_ALCContext);
    } else {
        printf("Error setting audio active after interruption...\n");
    }
    
    //may also want to re-start any music that was playing when we 
    //were interrupted
}

void SFAL::fillBuffer(ALuint buffer, OggVorbis_File *oggFile, ALenum pcmFormat, ALsizei frequency){
    //fill a single buffer from the vorbis file data
    char pcm[SF_STREAMED_AUDIO_BUFFER_SIZE] = {""};
    int size = 0,
    iBit = 0;
    
    //read a whole buffer's worth of data into our char buffer
    while( size < SF_STREAMED_AUDIO_BUFFER_SIZE )
    {
        int readBytes = ov_read(oggFile,
                                &pcm[size],
                                SF_STREAMED_AUDIO_BUFFER_SIZE - size,
                                0, 2, 1,
                                &iBit);
        if ( readBytes > 0 ){
            size += readBytes;
        } else {
            break;
        }
    }
    
    //no data?
    if(!size){
        //rewind and try again
        if (ov_pcm_seek(oggFile, 0) != 0){
            sfDebug(TRUE, "REWIND: unable to rewind!");
            return;
        }
        
        //rewind the source
        //alSourceRewind(source);
        //try again
        this->fillBuffer(buffer, oggFile, pcmFormat, frequency);
    }
    
    alBufferData(buffer, 
                 pcmFormat,
                 pcm,
                 size,
                 frequency); 
    updateALError();
    //printf("\nQueued buffer %d\n", buffer);
}

void SFAL::fillSourceBuffers(ALuint source, OggVorbis_File *oggFile, vorbis_info *vorbisInfo, ALuint *buffers, ALint bufferCount){
    //fill all the buffers given to us with PCM data
    ALenum pcmFormat;
    
    if (vorbisInfo->channels == 1) {
        pcmFormat = AL_FORMAT_MONO16;
    } else {
        pcmFormat = AL_FORMAT_STEREO16;
    }
    
    for (int i = 0; i < bufferCount; ++i) {
        this->fillBuffer(buffers[i], oggFile, pcmFormat, vorbisInfo->rate);
    }
}

bool SFAL::bufferSources(){
    
    ALint processed, queued, state;
    
    //clean up any stopped
    for (int i = this->_bufferSourceCount - 1; i > -1; --i) {
        ALuint source = this->_bufferSources[i];
        alGetSourcei(source, AL_SOURCE_STATE, &state);
        if (state == (AL_STOPPED)) {
            //as soon as a source stops, remove it from the
            //buffering system
            this->removeBufferSourceAtIndex(i);
            printf("Stopped source %d removed from buffering\n", source);
        }    
    }
    //kill the thread if empty of all buffers
    if (!_bufferSourceCount) {
        return false;
    }
    //refill all the processed buffers
    for (int i = 0; i < this->_bufferSourceCount; ++i) {
        ALuint source = this->_bufferSources[i];
        alGetSourcei(source, AL_BUFFERS_PROCESSED, &processed);
        //alGetSourcei(source, AL_BUFFERS_QUEUED   , &queued);
        if (!processed){
            continue; //skip if there is nothing to do
        }
        ALuint *buffersUnqueued;
        buffersUnqueued = (ALuint*)malloc(processed * sizeof(ALuint));
        alSourceUnqueueBuffers(source, processed, buffersUnqueued);
        updateALError();
        printf("\n\t(%d)\tUnqueued %d buffers\n", queued, processed);
        this->fillSourceBuffers(source, 
                                 this->_oggVorbisFiles[i], 
                                 this->_vorbisInfos[i], 
                                 buffersUnqueued, 
                                 processed);
        //now requeue the refilled buffers
        alSourceQueueBuffers(source, processed, buffersUnqueued);
        free(buffersUnqueued);
    }

    return true;
}

void SFAL::ensureContext(){
    //make sure this thread has the right AL context
    if (!alcGetCurrentContext()){
        alcMakeContextCurrent(this->_ALCContext);
    }
}

void* bufferRoutine(void* sfalPtr){
    //for all registered sources, ensure their buffers are up to date with
    //the latest sound bytes
    
    //set the priority
    sched_param bufferSchedParam;
    int scheduling;
    pthread_getschedparam(pthread_self(), &scheduling, &bufferSchedParam);
    printf("Buffer thread scheduling WAS (%u) at priority %d\n", scheduling, bufferSchedParam.sched_priority);
    bufferSchedParam.sched_priority = BUFFER_THREAD_PRIORITY;
    pthread_setschedparam(pthread_self(), scheduling, &bufferSchedParam);
    printf("Buffer thread started and scheduled as (%u) at priority %d...\n", scheduling, bufferSchedParam.sched_priority);
    
    //the main routine
    SFAL *sfal = (SFAL*)sfalPtr;
    sfal->ensureContext();
    while (sfal->bufferSources()){};
    printf("Buffer thread exiting...\n");
    return nil;
}

void SFAL::startBufferThread(){
    printf("Starting audio buffer thread...\n");
    this->_bufferThread = (pthread_t*) malloc(sizeof(pthread_t));
    if (pthread_create(this->_bufferThread, NULL, bufferRoutine, this) != 0){
        sfAssert(false, "Buffer thread create failed");
        return;
    }
}

void SFAL::removeBufferSourceAtIndex(int index){
    if (index == this->_bufferSourceCount - 1) {
        //this is the last buffer in the array - we can just shrink it
        this->_bufferSources = (ALuint*)realloc(this->_bufferSources, (this->_bufferSourceCount - 1) * sizeof(ALuint));
        this->_oggVorbisFiles = (OggVorbis_File**)realloc(this->_oggVorbisFiles, (this->_bufferSourceCount - 1) * sizeof(OggVorbis_File*));
        this->_vorbisInfos = (vorbis_info**)realloc(this->_vorbisInfos, (this->_bufferSourceCount - 1) * sizeof(vorbis_info*));
        --this->_bufferSourceCount;          
    } else {
        //not the last one - some rearranging needs to happen
        sfAssert(false, "non-last buffer remove - not implemented!");
    }  
}

void SFAL::waitForFinalBuffer(ALuint source){
    //wait until the given source is not in the buffer list
    //so we can destroy it, probably
    //FOR NOW - because we only use one at a time, we will just wait for the thread to die
  //  pthread_join(*this->_bufferThread, NULL);
}

void SFAL::addBufferSource(ALuint source, OggVorbis_File *oggFile, vorbis_info *vorbisInfo){
    //add a sound source to a list of sound sources that need buffering
    //on a regular basis and start a background process to do so
    this->_bufferSources = (ALuint*)realloc(this->_bufferSources, (this->_bufferSourceCount + 1) * sizeof(ALuint));
    this->_bufferSources[this->_bufferSourceCount] = source;
    this->_oggVorbisFiles = (OggVorbis_File**)realloc(this->_oggVorbisFiles, (this->_bufferSourceCount + 1) * sizeof(OggVorbis_File*));
    this->_oggVorbisFiles[this->_bufferSourceCount] = oggFile;
    this->_vorbisInfos = (vorbis_info**)realloc(this->_vorbisInfos, (this->_bufferSourceCount + 1) * sizeof(vorbis_info*));
    this->_vorbisInfos[this->_bufferSourceCount] = vorbisInfo;
    ++this->_bufferSourceCount;
    
    if (this->_bufferSourceCount == 1) {
        //this is the first source, start the buffer thread!
  //      this->startBufferThread();
    }
}

char* SFAL::decipherOggError(int ovRet){
    switch (ovRet) {
        case OV_EREAD:
            return "A read from media returned an error.";
            break;
        case OV_ENOTVORBIS:
            return "Bitstream does not contain any Vorbis data.";
            break;
        case OV_EVERSION:
            return "Vorbis version mismatch.";
            break;
        case OV_EBADHEADER:
            return "Invalid Vorbis bitstream header.";
            break;
        case OV_EFAULT:
            return "Internal logic fault; indicates a bug or heap/stack corruption.";
            break;
        default:
            return nil; //no error
            break;
    }
}

char* SFAL::decipherALError(ALenum errorValue){
    switch(errorValue)									
    {												
        case AL_INVALID_NAME:						
        {											
            return "AL_INVALID_NAME";									
        }
            
        case AL_INVALID_ENUM:						
        {											
            return "AL_INVALID_ENUM";								
        }	
            
        case AL_INVALID_VALUE:
        {
            return "AL_INVALID_VALUE";
        }
            
        case AL_INVALID_OPERATION:
        {											
            return "AL_INVALID_OPERATION";
        }
            
        case AL_OUT_OF_MEMORY:						
        {											
            return "AL_OUT_OF_MEMORY";
        }	
        default:
        {
            return nil;
        }
    }  
}

void SFAL::updateLastError(const char *file, const char *function, int line, ALenum errorValue){
    this->_lastALError = errorValue;
    if (errorValue) {
        printf("SFAL Error: %s, %s:%d - %s\n", file, function, line, this->decipherALError(errorValue));
    }
}

void DeriveBufferSize (
                       AudioStreamBasicDescription &ASBDesc,                            // 1
                       UInt32                      maxPacketSize,                       // 2
                       Float64                     seconds,                             // 3
                       UInt32                      *outBufferSize,                      // 4
                       UInt32                      *outNumPacketsToRead                 // 5
                       ) {
    static const int maxBufferSize = 0x50000;                        // 6
    static const int minBufferSize = 0x4000;                         // 7
    
    if (ASBDesc.mFramesPerPacket != 0) {                             // 8
        Float64 numPacketsForTime =
        ASBDesc.mSampleRate / ASBDesc.mFramesPerPacket * seconds;
        *outBufferSize = numPacketsForTime * maxPacketSize;
    } else {                                                         // 9
        *outBufferSize =
        maxBufferSize > maxPacketSize ?
        maxBufferSize : maxPacketSize;
    }
    
    if (                                                             // 10
        *outBufferSize > maxBufferSize &&
        *outBufferSize > maxPacketSize
        )
        *outBufferSize = maxBufferSize;
    else {                                                           // 11
        if (*outBufferSize < minBufferSize)
            *outBufferSize = minBufferSize;
    }
    
    *outNumPacketsToRead = *outBufferSize / maxPacketSize;           // 12
}

static void HandleOutputBuffer (
                                void                *aqData,
                                AudioQueueRef       inAQ,
                                AudioQueueBufferRef inBuffer
                                ) {
    AQPlayerState *pAqData = (AQPlayerState *) aqData;        // 1
    if (pAqData->mIsRunning == 0) {
        AudioQueueStop (
                        pAqData->mQueue,
                        false
                        );
        return;                     // 2
    }
    UInt32 numBytesReadFromFile;                              // 3
    UInt32 numPackets = pAqData->mNumPacketsToRead;           // 4
    AudioFileReadPackets(pAqData->mAudioFile,
                         false,
                         &numBytesReadFromFile,
                         pAqData->mPacketDescs, 
                         pAqData->mCurrentPacket,
                         &numPackets,
                         inBuffer->mAudioData);
//    AudioFileReadPacketData(pAqData->mAudioFile,
//                            false,
//                            &numBytesReadFromFile,
//                            pAqData->mPacketDescs,
//                            pAqData->mCurrentPacket,
//                            &numPackets, inBuffer->mAudioData);
    if (numPackets > 0) {                                     // 5
        inBuffer->mAudioDataByteSize = numBytesReadFromFile;  // 6
        AudioQueueEnqueueBuffer ( 
                                 pAqData->mQueue,
                                 inBuffer,
                                 (pAqData->mPacketDescs ? numPackets : 0),
                                 pAqData->mPacketDescs
                                 );
        pAqData->mCurrentPacket += numPackets;                // 7 
    } else {
        //rewind
        //stop immediately
        AudioQueueStop (pAqData->mQueue,
                        true);
        //set packet pos to 0
        pAqData->mCurrentPacket = 0;
        //start the queue and feed it the first buffer again
        AudioQueueStart(pAqData->mQueue, NULL);
        HandleOutputBuffer(pAqData, pAqData->mQueue, pAqData->mBuffers[0]);
    }
}

void SFAL::stopStreamedMusic(){
    _musicPlayerState.mIsRunning = false;
}

void SFAL::playStreamedMusic(const char *filePath){
    
    _musicPlayerState.mIsRunning = true;
    _musicPlayerState.mFlushed = false;
    _musicPlayerState.mCurrentPacket = 0;
    
    // get the source file
    CFURLRef srcFile = CFURLCreateFromFileSystemRepresentation (NULL, (const UInt8 *)filePath, strlen(filePath), false);
    
    OSStatus result = AudioFileOpenURL(srcFile, kAudioFileReadPermission ,kAudioFileMP3Type , &_musicPlayerState.mAudioFile);
    CFRelease (srcFile);
    
    UInt32 size = sizeof(_musicPlayerState.mDataFormat);
    AudioFileGetProperty(_musicPlayerState.mAudioFile, kAudioFilePropertyDataFormat, &size, &_musicPlayerState.mDataFormat);
    
    // create a new audio queue output
    AudioQueueNewOutput(&_musicPlayerState.mDataFormat,      // The data format of the audio to play. For linear PCM, only interleaved formats are supported.
                        HandleOutputBuffer,     // A callback function to use with the playback audio queue.
                        &_musicPlayerState,                  // A custom data structure for use with the callback function.
                        NULL,//CFRunLoopGetCurrent(),    // The event loop on which the callback function pointed to by the inCallbackProc parameter is to be called.
                        // If you specify NULL, the callback is invoked on one of the audio queue’s internal threads.
                        kCFRunLoopCommonModes,    // The run loop mode in which to invoke the callback function specified in the inCallbackProc parameter. 
                        0,                        // Reserved for future use. Must be 0.
                        &_musicPlayerState.mQueue);          // On output, the newly created playback audio queue object.
    
    // we need to calculate how many packets we read at a time and how big a buffer we need
    // we base this on the size of the packets in the file and an approximate duration for each buffer
    
    bool isFormatVBR = (_musicPlayerState.mDataFormat.mBytesPerPacket == 0 || _musicPlayerState.mDataFormat.mFramesPerPacket == 0);
    
    // first check to see what the max size of a packet is - if it is bigger
    // than our allocation default size, that needs to become larger
    UInt32 maxPacketSize;
    size = sizeof(maxPacketSize);
    AudioFileGetProperty(_musicPlayerState.mAudioFile, kAudioFilePropertyPacketSizeUpperBound, &size, &maxPacketSize);
    
    // adjust buffer size to represent about a second of audio based on this format
    DeriveBufferSize(_musicPlayerState.mDataFormat, maxPacketSize, 1.0/*seconds*/, &_musicPlayerState.bufferByteSize, &_musicPlayerState.mNumPacketsToRead);
    
    if (isFormatVBR) {
        _musicPlayerState.mPacketDescs = new AudioStreamPacketDescription [_musicPlayerState.mNumPacketsToRead];
    } else {
        _musicPlayerState.mPacketDescs = NULL; // we don't provide packet descriptions for constant bit rate formats (like linear PCM)
    }
    
    // if the file has a magic cookie, we should get it and set it on the AQ
    size = sizeof(UInt32);
    result = AudioFileGetPropertyInfo (_musicPlayerState.mAudioFile, kAudioFilePropertyMagicCookieData, &size, NULL);
    
    if (!result && size) {
        char* cookie = new char [size];		
        AudioFileGetProperty (_musicPlayerState.mAudioFile, kAudioFilePropertyMagicCookieData, &size, cookie);
        AudioQueueSetProperty(_musicPlayerState.mQueue, kAudioQueueProperty_MagicCookie, cookie, size);
        delete [] cookie;
    }
    
    // channel layout?
    OSStatus err = AudioFileGetPropertyInfo(_musicPlayerState.mAudioFile, kAudioFilePropertyChannelLayout, &size, NULL);
    AudioChannelLayout *acl = NULL;
    if (err == noErr && size > 0) {
        acl = (AudioChannelLayout *)malloc(size);
        AudioFileGetProperty(_musicPlayerState.mAudioFile, kAudioFilePropertyChannelLayout, &size, acl);
        AudioQueueSetProperty(_musicPlayerState.mQueue, kAudioQueueProperty_ChannelLayout, acl, size);
    }
    
    _musicPlayerState.mCurrentPacket = 0;                                
    
    for (int i = 0; i < kNumberBuffers; ++i) {                
        AudioQueueAllocateBuffer (                            
                                  _musicPlayerState.mQueue,                                    
                                  _musicPlayerState.bufferByteSize,                           
                                  &_musicPlayerState.mBuffers[i]                               
                                  );
    }
    
    //set the gain
    AudioQueueSetParameter(_musicPlayerState.mQueue,                                       
                           kAudioQueueParam_Volume,             
                           _volumes[SF_VOLUME_CATEGORY_AMBIENT]);
    
    // lets start playing now - stop is called in the AQTestBufferCallback when there's
    // no more to read from the file
    AudioQueueStart(_musicPlayerState.mQueue, NULL);
    
    // we need to enqueue a buffer after the queue has started
    HandleOutputBuffer(&_musicPlayerState, _musicPlayerState.mQueue, _musicPlayerState.mBuffers[0]);
    free(acl);
}
