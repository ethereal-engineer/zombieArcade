//
//  SFSound.m
//  ZombieArcade
//
//  Created by Adam Iredale on 6/02/10.
//  Copyright 2010 Stormforge Software. All rights reserved.
//

#import "SFSound.h"
#import "SFDefines.h"
#import "SFGameEngine.h"
#import "SFUtils.h"
#import "SFDebug.h"
#import "SFAL.h"

#define USE_NATIVE_STREAMING 0
#define THREAD_PRIORITY_BUFFER_AUDIO THREAD_PRIORITY_NORMAL
#define OP_PRIORITY_BUFFER_AUDIO NSOperationQueuePriorityNormal

@implementation SFSound

+(NSString*)fileExtension{
    return @"ogg";
}

+(NSString*)fileDirectory{
    return @"sound";
}

//quick methods (temporary, perhaps)
//if the sound is not loaded into a repository,
//these find it, load it from disk and play it
//using the repository (quicker the second time, obviously)
+(SFSound*)quickPlayFetch:(NSString*)filename{
    SFSound *gotSound = [[self rm] getItem:filename
                           itemClass:[SFSound class]
                             tryLoad:YES];
    return gotSound;
}

+(SFSound*)quickPlayAmbient:(NSString*)filename{
    //plays a sound effect as an ambient noise (good for clicks and pops etc - gui)
    SFSound *gotSound = [self quickPlayFetch:filename];
    [gotSound playAsAmbient:NO];
    return gotSound;
}

+(SFSound*)quickPlaySFX:(NSString*)filename position:(SFVec*)position{
    SFSound *gotSound = [self quickPlayFetch:filename];
    [gotSound playAsSFX:position repeat:NO];
    return gotSound;
}

+(SFSound*)newStreamFetch:(NSString*)filename{
    //returns a temporary item
    //straight from disk
    SFSound *gotSound = [[self rm] newOnceOffItemFromDisk:filename
                                                itemClass:[SFSound class]
                                               dictionary:[NSDictionary dictionaryWithObjectsAndKeys: 
                                 [NSNumber numberWithBool:YES], @"streaming",
#if USE_NATIVE_STREAMING
                                 [NSNumber numberWithBool:YES], @"nativeStreaming",
#endif
                                 nil]];
    //set this kind to ambient volume kind - for music etc
    [gotSound setVolumeCategory:SF_VOLUME_CATEGORY_AMBIENT];
    return gotSound;    
}

+(id)newStreamAmbient:(NSString*)filename{
    id gotSound = [self newStreamFetch:filename];
    [gotSound playAsAmbientStream:YES];
    return gotSound;
}

-(void)setVolumeCategory:(unsigned char)volumeCategory{
    _volumeCategory = volumeCategory;
}

-(void)initSound{
    int ovRet = ov_open_callbacks(_stream, &_oggVorbisFile, NULL, 0, SFAL::instance()->ovCallbacks());
    sfAssert(ovRet == 0, "ov_open_callbacks Error: %s", SFAL::instance()->decipherOggError(ovRet));
	_vorbisInfo = ov_info(&_oggVorbisFile, -1 );
    _size = ( ( unsigned int )ov_pcm_total(&_oggVorbisFile, -1 ) * _vorbisInfo->channels << 1 );
    const float BYTES_PER_SAMPLE = 2.0f;
    //stores length in seconds
    _length = _size / (float)_vorbisInfo->rate / (float)_vorbisInfo->channels / BYTES_PER_SAMPLE;
    if (_isStreaming) {
        alGenBuffers( SF_STREAMED_AUDIO_BUFFER_COUNT, _bid );
        for (int i = 0; i < SF_STREAMED_AUDIO_BUFFER_COUNT; ++i) {
            [self readPCMFromAudioStreamIntoALBuffer:_bid[ i ]];
        }
    } else {
        [self fullLoad];
    }
    [self setupSoundSource];
}

-(void)setPitch:(float)pitch{
    _currentPitch = pitch;
    alSourcef(_sid, AL_PITCH, pitch );
}

-(id)initWithSFStream:(SFStream*)stream dictionary:(NSDictionary*)dictionary{
    self = [super initWithSFStream:stream dictionary:dictionary];
    if (self != nil) {
        //default to SFX
        _volumeCategory = SF_VOLUME_CATEGORY_SFX;
        _pos = new SFVec(3);
        _dir = new SFVec(3);
        _vel = new SFVec(3);
        _currentPitch = 1.0f;
        id streaming = [self objectInfoForKey:@"streaming"];
        if (streaming) {
            _isStreaming = [streaming boolValue];
        }
        [self initSound];
    }
    return self;
}

-(NSString*)interpretALError{
    switch(_lastError)									
    {												
        case AL_INVALID_NAME:						
        {											
            return @"AL_INVALID_NAME";									
        }
            
        case AL_INVALID_ENUM:						
        {											
            return @"AL_INVALID_ENUM";								
        }	
            
        case AL_INVALID_VALUE:
        {
            return @"AL_INVALID_VALUE";
        }
			
        case AL_INVALID_OPERATION:
        {											
            return @"AL_INVALID_OPERATION";
        }
            
        case AL_OUT_OF_MEMORY:						
        {											
            return @"AL_OUT_OF_MEMORY";
        }	
        default:
        {
            return nil;
        }
    }
}

-(void)updateErrorValue:(const char*)file function:(const char*)function line:(unsigned int)line{
    unsigned int errorCheck = alGetError();
    if (errorCheck == AL_NO_ERROR) {
        return;
    }
    _lastError = errorCheck;
    _lastErrorString = [self interpretALError];
    sfDebug(TRUE, "AL_ERROR: %s @ %s:%u (%s)", [_lastErrorString UTF8String], file, line, function);
}

-(id)lastErrorString{
    return _lastErrorString;
}

-(float)lastError{
    return _lastError;
}
            
-(void)cleanUpAL{
    //delete buffers
    ALsizei bufferCount = 1;
    if (_isStreaming) {
        bufferCount = SF_STREAMED_AUDIO_BUFFER_COUNT;
        SFAL::instance()->waitForFinalBuffer(_sid);
    }
    alDeleteBuffers(bufferCount, _bid);
    //delete sources
    alDeleteSources(1, &_sid);
}

-(void)cleanUp{
    [self cleanUpAL];
    ov_clear(&_oggVorbisFile);
    [self closeFileStream];
    delete _pos;
    delete _vel;
    delete _dir;
    [super cleanUp];
}

-(SFStream*)filestream{
    return _stream;
}

-(void)closeFileStream{
    if (_isStreaming) {
        delete _stream;
        _stream = NULL;
    }
}

-(void)updateOpenALSoundInfo{
    
    alSource3f(_sid, AL_POSITION, _pos->x(), _pos->y(), _pos->z());
    
    alSource3f(_sid, AL_VELOCITY, _vel->x(), _vel->y(), _vel->z());
	
    alSource3f(_sid, AL_DIRECTION, _dir->x(), _dir->y(), _dir->z());
	
    alSourcef(_sid, AL_ROLLOFF_FACTOR, 1.0f );
	
    alSourcei(_sid, AL_SOURCE_RELATIVE, _isAmbient);
	
	alSourcef(_sid, AL_PITCH, _currentPitch ); 
    
    alSourcef(_sid, AL_REFERENCE_DISTANCE, 100.0f);
	
#if DEBUG_SFSOUND
    [self updateErrorValue:__FILE__ function:__FUNCTION__ line:__LINE__];
#endif
}

-(ALenum)getFormat{
    if (_vorbisInfo->channels == 1) {
        return AL_FORMAT_MONO16;
    } else {
        return AL_FORMAT_STEREO16;
    }
}

-(ALsizei)getRate{
    return _vorbisInfo->rate;
}

-(float)soundLength{
    return _length;
}

-(void)fullLoad{
    //we're not buffering this so we buffer the lot
    //at once then close the stream
    int iCount, iBit;
    
    char *ptr = (char *) malloc(_size);
    
    _data = ptr;
    
    do{
        iCount = ov_read( &_oggVorbisFile, ptr,
                         SF_STREAMED_AUDIO_BUFFER_SIZE,
                         0, 2, 1,
                         &iBit);
        if (iCount > 0) {
            ptr += iCount;
        }
    } while (iCount > 0);
    
    alGenBuffers( 1, _bid);
    
    alBufferData(_bid[ 0 ],
                 [self getFormat],
                 _data,
                 _size,
                 [self getRate]);
    
    free(_data );
    _data = NULL;
    
    ov_clear(&_oggVorbisFile);
    
    [self closeFileStream];
#if DEBUG_SFSOUND
    [self updateErrorValue:__FILE__ function:__FUNCTION__ line:__LINE__];
#endif		
}

-(BOOL)isStreaming{
    return _isStreaming;
}

-(void)resetPhysical{
    //sets dir, vel, pos to 0,0,0
    _pos->reset();
    _dir->reset();
    _vel->reset();
}

-(void)setupSoundSource{
	alGenSources(1, &_sid);
	
	[self resetPhysical];
    [self updateOpenALSoundInfo];
	
	if (_isStreaming){	
		alSourceQueueBuffers(_sid,
                             SF_STREAMED_AUDIO_BUFFER_COUNT,
                             _bid);
	}
	else
    { 
        alSourcei(_sid, AL_BUFFER, _bid[ 0 ]); 
    }
	
#if DEBUG_SFSOUND
    [self updateErrorValue:__FILE__ function:__FUNCTION__ line:__LINE__];
#endif		
}

//alternate static buffer procedure
ALvoid  alBufferDataStaticProc(const ALint bid, ALenum format, ALvoid* data, ALsizei size, ALsizei freq)
{
	static	alBufferDataStaticProcPtr	proc = NULL;
    
    if (proc == NULL) {
        proc = (alBufferDataStaticProcPtr) alcGetProcAddress(NULL, (const ALCchar*) "alBufferDataStatic");
    }
    
    if (proc)
        proc(bid, format, data, size, freq);
    
    return;
}

-(BOOL)rewind{
    //resets our stream so we can play it over again
    if (ov_pcm_seek(&_oggVorbisFile, 0) != 0){
        sfDebug(TRUE, "REWIND: unable to rewind!");
        return NO;
    }
    //rewind the source
    alSourceRewind(_sid);
#if DEBUG_SFSOUND
    [self updateErrorValue:__FILE__ function:__FUNCTION__ line:__LINE__];
#endif
    return YES;
}

-(BOOL)readPCMFromAudioStreamIntoALBuffer:(ALuint)bufferName{
    char pcm[ SF_STREAMED_AUDIO_BUFFER_SIZE ] = {""};
    
	int size = 0, iBit;
    
	while( size < SF_STREAMED_AUDIO_BUFFER_SIZE )
	{
		int readBytes = ov_read(&_oggVorbisFile,
                        pcm + size,
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
        if ((_repeat) and ([self rewind])) {
            //recurse after rewinding
            return [self readPCMFromAudioStreamIntoALBuffer:bufferName];
        }
        return NO; 
    }
    
	alBufferData(bufferName, 
                 [self getFormat],
                 pcm,
                 size,
                 [self getRate]);
    
#if DEBUG_SFSOUND
    [self updateErrorValue:__FILE__ function:__FUNCTION__ line:__LINE__];
#endif
	return YES;
}

-(id)getVolumeCategory{
    id volumeCategory = [self objectInfoForKey:@"volumeCategory"];
    if (!volumeCategory) {
        volumeCategory = SF_SOUND_DEFAULT_VOLUME_CATEGORY;
        [self setObjectInfo:volumeCategory forKey:@"volumeCategory"];
    }
    return volumeCategory;
}

-(void)setupVolumeChangeListener{
    id volumeCategory = [self getVolumeCategory];
    [self notifyMe:SF_NOTIFY_VOLUME_CHANGED selector:@selector(volumeSettingChanged:) object:volumeCategory];
}

-(void)startPlaying:(BOOL)repeat{
    _repeat = repeat;
	
	alSourcei(_sid, AL_LOOPING, (_repeat & !_isStreaming));  //repeat can't be set on streaming
	
    alSourcef(_sid, AL_GAIN, SFAL::instance()->volume(_volumeCategory));
    
	alSourcePlay(_sid);
    
    alGetSourcei(_sid, AL_SOURCE_STATE, &_sourceState);
    
#if DEBUG_SFSOUND
    [self updateErrorValue:__FILE__ function:__FUNCTION__ line:__LINE__];
#endif	
}

-(void)stopPlaying{

    alSourceStop(_sid);

    alGetSourcei(_sid, AL_SOURCE_STATE, &_sourceState);
    
#if DEBUG_SFSOUND
    [self updateErrorValue:__FILE__ function:__FUNCTION__ line:__LINE__];
#endif	
}

-(void)setAsAmbient{
    _isAmbient = YES;
    [self resetPhysical];
    [self updateOpenALSoundInfo];
}

-(void)playAsAmbient:(BOOL)repeat{
    [self setAsAmbient];
    [self startPlaying:repeat];
}

-(BOOL)isPlaying{
    return _sourceState == AL_PLAYING;
}

-(BOOL)isPlayingForceCheck{
    alGetSourcei(_sid, AL_SOURCE_STATE, &_sourceState);
    return [self isPlaying];
}

-(void)playAsAmbientStream:(BOOL)repeat{
    _repeat = repeat;
    [self setAsAmbient];
    [self startPlaying:repeat];
    SFAL::instance()->addBufferSource(_sid, 
                                      &_oggVorbisFile, 
                                      _vorbisInfo);
}

-(BOOL)isAmbient{
    return _isAmbient;
}

-(BOOL)isSFX{
    return !_isAmbient;
}


-(void)setAsSFX:(SFVec*)position{
    _isAmbient = NO;
    _pos->setVector(position);
    [self updateOpenALSoundInfo];
}

-(void)playAsSFX:(SFVec*)position repeat:(BOOL)repeat{
    [self setAsSFX:position];
    [self startPlaying:repeat];
}

@end
