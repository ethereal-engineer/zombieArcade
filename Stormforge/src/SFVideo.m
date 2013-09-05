//
//  SFVideo.m
//  ZombieArcade
//
//  Created by Adam Iredale on 24/02/10.
//  Copyright 2010 Stormforge Software. All rights reserved.
//

#import "SFVideo.h"
#import "SFOggStream.h"
#import "SFUtils.h"
#import "SFGameEngine.h"
#import "ocintrin.h"
#import "SFDebug.h"

#define OP_PRIORITY_BUFFER_VIDEO NSOperationQueuePriorityHigh
#define SOME_VIDEO_BUFFER_COUNT 256

@implementation SFVideo

+(NSString*)fileExtension{
    return @"ogv";
}

-(void)setupBuffers:(id)decoder{
    
    theora_info *theoraInfo = [decoder theoraInfo];
    
    for (int i = 0; i < SOME_VIDEO_BUFFER_COUNT; ++i) {
        _b0[ i ] = ( 113443 * ( i - 128 ) + 32768 ) >> 16;
		_b1[ i ] = (  45744 * ( i - 128 ) + 32768 ) >> 16;
		_b2[ i ] = (  22020 * ( i - 128 ) + 32768 ) >> 16;
		_b3[ i ] = ( 113508 * ( i - 128 ) + 32768 ) >> 16;
    }
    
    _d_time  = 0.0f;
    
    _t_ratio = 1.0f / [decoder frameRate];
    
    _u_time  = 0.0f;
    _u_ratio = _t_ratio / SF_VIDEO_BUFFER;
    
    for (int i = 0; i < SF_VIDEO_BUFFER; ++i) {
        _buf[i] = ( unsigned char * ) malloc(theoraInfo->width  *
                                             theoraInfo->height * 
                                             SF_VIDEO_BUFFER_BITS);
    }
    
    _currentFrame = [[SFImage alloc] initWithName:@"video_frame" dictionary:nil];
    [_currentFrame setDimensions:theoraInfo->width height:theoraInfo->height depth:SF_VIDEO_BUFFER_BITS];
    [_currentFrame allocTexBuffer];
    _videoDecoder = [decoder retain];
}

-(void)cleanUp{
    [_videoDecoder release];
    for (int i = 0; i < SF_VIDEO_BUFFER; ++i) {
        free(_buf[i]);
        _buf[i] = nil;
    }
    [_decoders release];
    [super cleanUp];
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    //here we will be notified as soon as a decoder's headers are complete
    //and considering there is only one right now....
    [object removeObserver:self forKeyPath:@"headersComplete"];
    [self setupBuffers:object];
}

-(id)decoderForStream:(id)stream{
    if ([stream objectInfoForKey:@"nonTheora"]) {
        return nil;
    }
    id streamSerial = [stream serial];
    id decoder = [_decoders objectForKey:streamSerial];
    if (!decoder) {
        decoder = [[SFTheoraDecoder alloc] initWithOggStream:stream dictionary:nil];
        //register for "headers complete" 
        [decoder addObserver:self
                  forKeyPath:@"headersComplete"
                     options:NSKeyValueObservingOptionNew
                     context:NULL];
        [_decoders setObject:decoder forKey:streamSerial];
        [decoder release];
    }
    return decoder;
}

-(void)setupDecoders{
    _decoders = [[NSMutableDictionary alloc] init];
}

-(BOOL)nextFrame{
    if (!_isPlaying) {
        return NO;
    }

    if (!_videoDecoder) {
        //we haven't been set up yet - pass...
        return NO;
    }
    
	_d_time += [[SFGameEngine sfWindow] deltaTime];
	
  //  //if we have missed the boat we drop this frame
//    if (_d_time > (_t_ratio * 1.9) ) {
//        if(_buf[ 0 ] )
//		{
//            sfDebug(TRUE, "Dropped frame!");
//            _buf[0] = NULL;
//            _d_time = 0.0f;
//            return NO;
//        }
//    }
    
	if ( _d_time >= _t_ratio )
	{
        _needFrame = YES; // lets the buffering know to cycle the buffers
		if(_hasFrame) //is there data ready to be used?
		{
            _hasFrame = NO;
            sfDebug(TRUE, "New frame discovered in live buf!");
            if(![_currentFrame tid])
			{
				[_currentFrame setDimensions:[_videoDecoder theoraInfo]->width 
                                      height:[_videoDecoder theoraInfo]->height 
                                       depth:SF_VIDEO_BUFFER_BITS];
			}
            [_currentFrame setFilter:SF_IMAGE_ISOTROPIC];
            [_currentFrame setData:_buf[0]];
            [_currentFrame forcePrepare]; //we want the frame overwritten each time
        
			_d_time = 0.0f;
            
			return YES;			
		} else {
            sfDebug(TRUE, "Time to draw but no new frame!");
        }

	}
	return NO;
}

-(SFImage*)currentFrame{
    return _currentFrame;
}

-(BOOL)isPlaying{
    return _isPlaying;
}

-(void)bufferStreams{
    //buffer streams as they are paged in
    //a NO means EOF
    if (![self isPlaying]) {
        return;
    }
    
    do {
        
        if (!_needFrame and (_videoDecoder != nil)) /*or (_u_time < _u_ratio)*/ {
            //don't buffer unless our buffer is marked as depleted (NULL)
            //and it is time to show a frame...?
            return;
        }
        
        //fill the last buffer chunk
        if (!_lastPage) {
            if (![self readManyOggPages:SF_VIDEO_BUFFER_SIZE]){
                _lastPage = YES;
            }
            
        }
        
        NSEnumerator *streams = [_oggStreams objectEnumerator];
        for (id stream in streams){
            _streamBuffered = [self bufferStream:stream] or _streamBuffered;
        }
    } while (!_videoDecoder);
    

    if (_streamBuffered) { //don't bother cycling unless there's something to cycle
        
        //shuffle the filled buffers downwards
        unsigned char *bufferHead = _buf[0];
        sfDebug(TRUE, "Saved original buffer head");
        for (int i = 0; i < SF_VIDEO_BUFFER; ++i) {
            _buf[i] = _buf[i+1];
            sfDebug(TRUE, "_buf %d moved to _buf %d", i + 1, i);
        }
        _buf[SF_VIDEO_BUFFER - 1] = bufferHead; //circle it
        sfDebug(TRUE, "Moved original head to last");
        _needFrame = NO;
        _hasFrame = YES;
    }
    
}


-(BOOL)bufferStream:(id)stream{
    
    //fill in the last chunk of buffer
    
    int y_shift, uv_shift,
    ny, nu, nv,
    r, g, b,
    w, h = 0;
    
    yuv_buffer yuv;
      
    id decoder = [self decoderForStream:stream];
    if (!decoder) {
        return NO;
    }
    
    //if (_videoDecoder == nil) {
//        return NO; //nothing to do yet...
//    }
    
    if (![decoder decodeStream:&yuv]){
        if (_lastPage) {
            //all buffered and nothing more
            //to process - stop
            [self stop];
        }
        return NO;
    }
    
    unsigned char *ptr = _buf[SF_VIDEO_BUFFER - 1];
    
	while( h != yuv.y_height )
	{
		y_shift  = yuv.y_stride * h;
		uv_shift = yuv.uv_stride * ( h >> 1 );
        
		w = 0;
		while( w != yuv.y_width )
		{
			ny = *( yuv.y + y_shift  +   w  );
			nu = *( yuv.u + uv_shift + ( w >> 1 ) );
			nv = *( yuv.v + uv_shift + ( w >> 1 ) );
            
			r = ny + _b0[ nv ];
			g = ny - _b1[ nv ] - _b2[ nu ];
			b = ny + _b3[ nu ];
            
			ptr[ 0 ] = OC_CLAMP255( r - 16 );
			ptr[ 1 ] = OC_CLAMP255( g - 16 );
			ptr[ 2 ] = OC_CLAMP255( b - 16 );
			
			ptr += SF_VIDEO_BUFFER_BITS;
            
			++w;
		}
        
		++h;
	}
    return YES;
}

-(void)reachedEndOfFile{
    if (_repeat) {
        //rewind, play again....
    }
    [self stop];
}

-(void)startBuffering{
    //starts a buffering job that continually queues a new buffering job
    //until the sound stops playing
    
    if (![self isPlaying]){
        return;
    }
    
    //the buffering op
    SFOperation *opBuffer = [[SFOperation alloc] initWithTarget:self
                                                        selector:@selector(bufferStreams)
                                                          object:nil];
    
    //the repeat op
    SFOperation *opRepeatBuf = [[SFOperation alloc] initWithTarget:self
                                                           selector:@selector(startBuffering)
                                                             object:nil];
    
    [opRepeatBuf addDependency:opBuffer];
    //[opBuffer setQueuePriority:OP_PRIORITY_BUFFER_VIDEO];
    //[opBuffer setRequiresAL:YES];
    //[opRepeatBuf setQueuePriority:OP_PRIORITY_BUFFER_VIDEO];
    [[SFGameEngine defaultQueue] addOperation:opBuffer];
    [opBuffer release];
    [[SFGameEngine defaultQueue] addOperation:opRepeatBuf];
    [opRepeatBuf release];
}

-(void)play:(BOOL)repeat{
    _repeat = repeat;
    _isPlaying = YES;
    //start buffering
    [self startBuffering];
}

-(void)stop{
    //also rewind
    sfDebug(TRUE, "Video stopped %s", [self UTF8Description]);
    _isPlaying = NO;
}

@end
