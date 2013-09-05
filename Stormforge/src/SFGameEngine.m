//
//  SFGameEngine.m
//  ZombieArcade
//
//  Created by Adam Iredale on 11/11/09.
//  Copyright 2009 Stormforge Software. All rights reserved.
//

#import "AllSingletons.h"

#import "SFUtils.h"
#import "SFScoreManager.h"
#import "SFSceneManager.h"
#import "SFLoadingScreen.h"
#import "SFSettingManager.h"
#import "SFGLManager.h"
#import "SFResourceManager.h"
#import "SFSceneLogic_Debug.h"
#import "SFMovieView.h"
#import "SFDebug.h"
#import "SFAL.h"
#import "SFSettingManager.h"

#define DEBUG_FINAL_MEMORY_LEAKS 0
#define OP_PRIORITY_RENDER NSOperationQueuePriorityVeryHigh
#define OP_PRIORITY_RENDER_WHILE_LOADING NSOperationQueuePriorityVeryHigh
#define THREAD_PRIORITY_RENDER THREAD_PRIORITY_HIGH

#define PLAY_VIDEOS 1

#define DEBUG_SCENE 0

#define DEBUG_RENDER_DELAY 0

#define NO_SOUND 0

#if DEBUG_SCENE
#ifdef NO_SOUND
#undef NO_SOUND
#endif
#define NO_SOUND 1
#endif

//init the global to null
static SFGameEngine *gSFGameEngine = nil;

@implementation SFGameEngine

@synthesize window;
@synthesize mainViewController;

-(SFOperationQueue*)defaultQueue{
    return _defaultQueue;
}

+(SFOperationQueue*)defaultQueue{
    return [[self alloc] defaultQueue];
}

-(SFOperationQueue*)serialQueue{
    return _serialQueue;
}

+(SFOperationQueue*)serialQueue{
    return [[self alloc] serialQueue];
}

-(void)applicationDidReceiveMemoryWarning:(UIApplication *)application{
    //ah crap
    printf("\n\n###### LOW MEMORY WARNING!!! ######\n\n");
    [self postGeneralNote:SF_NOTIFY_LOW_MEMORY userInfo:nil];
}

+(void)addOperation:(NSOperation *)operation{
	[[SFGameEngine alloc] addOperation:operation];
}

+(void)addOperations:(NSArray *)opArray{
	[[SFGameEngine alloc] addOperations:opArray];
}

-(void)dashboardDidDisappear{
    //the dash will disappear
    //[[SFUtils appKeyWindow] bringSubviewToFront:glView];
   // [glView startAnimation];
    [mainViewController startGLAnimation];
}

-(void)dashboardWillAppear{
    //the dashboard will appear
    [mainViewController stopGLAnimation];
    //[glView stopAnimation];
   // [[SFUtils appKeyWindow] sendSubviewToBack:glView];
}

//-(BOOL)isGREENotificationAllowed:(OFNotificationData*)notificationData{
//    //This method will be invoked when a pop-up needs to know if it should display or not. 
//    //Developers can return YES to allow the notification, or NO to disallow it.
//    switch (notificationData.notificationCategory) {
//        case kNotificationCategoryHighScore:
//        case kNotificationCategoryAchievement:    
//            return NO;
//            break;
//        case kNotificationCategoryLogin:
//            if (![GREE isOnline]){
//                [self userLoggedIn:nil];
//            }
//        default:
//            return YES;
//            break;
//    }
//    
//    sfDebug(TRUE, "Disallowing OF notification: %s", [[notificationData notificationText] UTF8String]);
//    return NO;
//}

//-(void)handleDisallowedNotification:(OFNotificationData*)notificationData{
//    //This method will be invoked when isGREENotificationAllowed returns NO. 
//    //We recommend developers display a custom notification here using the data provided in the 
//    //OFNotificationData object. Please see the section on OFNotificationData below for more information.
//    
//    switch (notificationData.notificationCategory) {
//        case kNotificationCategoryHighScore:
//        case kNotificationCategoryAchievement:
//            [_gameCenterNotifications push:notificationData];
//            break;
//        default:
//            //don't care about the rest
//            break;
//    }    
//    //OFUnlockedAchievementNotificationData
//    //This is a special type of OFNotificationData that also includes the OFAchievement that was unlocked.
//}
//
//-(void)notificationWillShow:(OFNotificationData*)notificationData{
//    //This method will be invoked when a default GREE notification is about to be displayed.
//}

-(void)iPodNowPlayingChanged:(NSNotification*)notify{
}

-(void)iPodPlayStateChanged:(NSNotification*)notify{
}

-(void)setupiPodMusic{
//	_musicPlayer = [MPMusicPlayerController applicationMusicPlayer];
//	//register for notifications so we can control the iPod (part)
//	NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
//	
//	[notificationCenter
//	 addObserver: self
//	 selector:    @selector(iPodNowPlayingChanged:)
//	 name:        MPMusicPlayerControllerNowPlayingItemDidChangeNotification
//	 object:      _musicPlayer];
//	
//	[notificationCenter
//	 addObserver: self
//	 selector:    @selector(iPodPlayStateChanged:)
//	 name:        MPMusicPlayerControllerPlaybackStateDidChangeNotification
//	 object:      _musicPlayer];
//	
//	[_musicPlayer beginGeneratingPlaybackNotifications];
//	
//	[_musicPlayer setShuffleMode: MPMusicShuffleModeOff];
//	[_musicPlayer setRepeatMode: MPMusicRepeatModeNone];
//	
	//if the user is playing music, stop it
	//if ([_musicPlayer nowPlayingItem]) {
//		//stop or pause
//		[_musicPlayer stop];
//	}
}

-(SFPlayer*)getLocalPlayer{
    if (!_localPlayer) {
        _localPlayer = [self createPlayer];
    }
    return _localPlayer;
}

+(SFPlayer*)getLocalPlayer{
    return [[self alloc] getLocalPlayer];
}

-(void)sfInitSound{
    //prod the sound manager
    SFAL::instance()->startOpenAL();
    _soundIsReady = YES;
}

-(void)introMoviesFinished:(id)notify{
    [self stopNotifyObject:SF_NOTIFY_VIEW_CONTROLLER_EVENT object:mainViewController];
    [self start];
}

-(void)playIntroVideos{
#if PLAY_VIDEOS == 0
    [self startSoundJob];
    return;
#endif
    //[glView stopAnimation];
    printf("\n\nVideos NOT overlaying loading!!!\n\n");
    [self notifyMe:SF_NOTIFY_VIEW_CONTROLLER_EVENT
          selector:@selector(introMoviesFinished:)
            object:mainViewController];
    //check here to see if the mute switch is on - if so, play the silent intro
    //ugh - terrible workaround :( Oh well
    if (SFAL::instance()->getMuteState()) {
        [mainViewController playMovieList:[[self gi] getMovieList:@"introSilent"]];
       // [SFMovieView viewWithMovieList:[[self gi] getMovieList:@"introSilent"]];
    } else {
        [mainViewController playMovieList:[[self gi] getMovieList:@"intro"]];
    }
}

-(int64_t)currTime{
    return [mainViewController currentTime];
}

-(int64_t)lastSync{
    return [mainViewController lastSyncTime];
}

+(int64_t)currTime{
    return [[self alloc] currTime];
}

+(int64_t)lastSync{
    return [[self alloc] lastSync];
}

+(void)render{
    [(SFGameEngine*)[self alloc] render];
}

-(u_int64_t)renderId{
    return _renderId;
}

+(u_int64_t)renderId{
    return [[self alloc] renderId];
}

-(void)render{
    NSAutoreleasePool *aPool = [[NSAutoreleasePool alloc] init];
    if (!_sceneManager) {
        _sceneManager = [self sm];
    }
    if ([_sceneManager render:_soundIsReady 
       allowLoadDelta:YES 
          touchEvents:[_touchEvents dump]
                  otherEvents:nil] == rrRenderedOk){
        [_sceneManager processOtherEvents:[_gameCenterNotifications dump]];
    }
    [aPool drain];
    ++_renderId;
}

-(void)sceneBecameReady:(NSNotification*)notify{
}

-(void)sceneBecameUnReady:(NSNotification*)notify{
}

-(void)userLoggedIn:(NSString*)userId{
    //GREE is online!
    //get our achievements
    [[self scom] userLoggedIn:userId];
}

-(void)userLoggedOut:(NSString *)userId{
    [[self scom] userLoggedOut:userId];
}

-(void)applicationWillTerminate:(UIApplication *)application{
	//ok, so we're going down - make sure we tidy up and save
	//all our data
	printf("H.S.W. (app) going down!");
	sfDebug(TRUE, "Stopping animation...");
    //[[self glView] stopAnimation];
	[mainViewController stopGLAnimation];
    sfDebug(TRUE, "Telling everyone to save their data...");
	[[[self sm] currentLogic] autoSaveScene];
    [[NSNotificationCenter defaultCenter] postNotificationName:SF_NOTIFY_SAVE_DATA object:nil];
	[self cleanUp];    
}

-(void)outputDeviceInfo{
    //print the device info out to the console
    UIDevice *currentDevice = [UIDevice currentDevice];
    NSProcessInfo *procInfo = [NSProcessInfo processInfo];
    printf("Device Information:\n");
    printf("Name: %s\n", [[currentDevice name] UTF8String]);
    printf("UID: %s\n", [[currentDevice uniqueIdentifier] UTF8String]);
    printf("System Name: %s\n", [[currentDevice systemName] UTF8String]);
    printf("System Version: %s\n", [[currentDevice systemVersion] UTF8String]);
    printf("Model: %s\n", [[currentDevice model] UTF8String]);
    printf("Battery Level: %.2f\n", [currentDevice batteryLevel]);
    printf("Real Memory Available: %.2fMB\n", NSRealMemoryAvailable() / 1048576.0f);
    printf("Processor Count: %d\n", [procInfo processorCount]);
}

- (void)applicationDidFinishLaunching:(UIApplication *)application {
    [window addSubview:[mainViewController view]];
    [window makeKeyAndVisible];
    _appVersion = [[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"] retain];
    NSLog(@"AppVersion is %s", [_appVersion UTF8String]);
    [SFUtils setAppTime];
    
    sfPrintThreadStats();    
    
    [SFSettingManager registerDefaults]; //load from SFSettings.plist
    
	[ [UIApplication sharedApplication] setIdleTimerDisabled:NO ]; //later - set this before running a level!!
    
	// Flip the simulator to the right
	[[UIApplication sharedApplication] setStatusBarOrientation: UIInterfaceOrientationLandscapeRight animated: NO];
	
    //[EAGLContext setCurrentContext:[glView context]];
    _defaultQueue = [[SFOperationQueue alloc] initQueue:NO];
    _serialQueue = [[SFOperationQueue alloc] initQueue:YES];
#if DEBUG_SFOPERATIONQUEUE
    [_defaultQueue setName:@"defaultQ"];
    [_serialQueue setName:@"serialQ"];
#endif
    [_defaultQueue setGlContext:[EAGLContext currentContext]];
    [_serialQueue setGlContext:[EAGLContext currentContext]];
    //start our GL engine
    //SFGL::startUp();
	//[glView destroyFramebuffer];
	//[glView createFramebuffer];
    _touchEvents = [[SFStack alloc] initStack:NO useFifo:YES];
    _gameCenterNotifications = [[SFStack alloc] initStack:NO useFifo:YES];
    _afilter = SF_GAME_AFILTER;
    _tfilter = SF_GAME_TFILTER;

    [self outputDeviceInfo];
    [self playIntroVideos];
}

+(void)swapBuffers:(BOOL)performGlSwap{
    [[self alloc] swapBuffers:performGlSwap];
}

-(void)startSoundJob{
#if NO_SOUND == 0
	[_defaultQueue addOperation:self selector:@selector(sfInitSound) object:nil];
#endif
}

-(id)glContext{
    return [[mainViewController glView] context];
}

+(id)glContext{
    return [[self alloc] glContext];
}

-(void)start{
    _engineStarted = YES;
    [mainViewController startGLAnimation];
    [self startSoundJob];
#if DEBUG_SCENE
    [SFSceneLogic_Debug debugScenes];
#endif
    //load the main menu
    [[self sm] changeScene:[[self gi] getMainMenuDictionary]];
}

-(void)applicationWillResignActive:(UIApplication *)application{
    //this happens when (e.g.) a phone call comes in - but you haven't
    //answered it yet.  If you answer, the app will terminate and
    //launch again after the call is over.  If you deny,
    //the app will become active again
    [mainViewController stopGLAnimation];
    //[GREE applicationWillResignActive];
}

-(unsigned char)afilter{
    return _afilter;
}

+(unsigned char)afilter{
    return [[self alloc] afilter];
}

-(unsigned char)tfilter{
    return _tfilter;
}

+(unsigned char)tfilter{
    return [[self alloc] tfilter];
}

-(void)swapAllBuffers{
    [mainViewController doSwapBuffersAccounting];
    [[mainViewController glView] swapBuffers];
}

-(void)swapBuffers:(BOOL)performGlSwap{
    [mainViewController doSwapBuffersAccounting];
    if (performGlSwap) {
        [[mainViewController glView] swapBuffers];
    }
}

-(void)applicationDidBecomeActive:(UIApplication *)application{
    sfDebug(TRUE, "Application became active!");
    if (_engineStarted) {
        [mainViewController startGLAnimation];
        //[GREE applicationDidBecomeActive];
    }
}

-(void)pushTouchEvent:(SFTouchEvent *)touchEvent{
    [_touchEvents push:touchEvent];
}

+(void)pushTouchEvent:(SFTouchEvent *)touchEvent{
    [[self alloc] pushTouchEvent:touchEvent];
}

-(void)cleanUp{
	[mainViewController stopGLAnimation];
    [_defaultQueue cleanUp];
    [_serialQueue cleanUp];
	[SFSceneManager cleanUp];
	[_loadingScreen cleanUp];
	[_localPlayer cleanUp];
    if (_GREEStarted) {
        //[GREE shutdown];
    }
    [SFResourceManager cleanUp];
    [SFScoreManager cleanUp];
    [SFGameInfo cleanUp];
    [_localPlayer release];
    [_loadingScreen release];
	[_defaultQueue release];
    [_serialQueue release];
    [window release];
    SFAL::shutdown();
    SFGL::shutdown();
    [_touchEvents release];
    [_gameCenterNotifications release];
    [_appVersion release];
    [super cleanUp];
#if DEBUG_FINAL_MEMORY_LEAKS
    [SFUtils sleep:5000];
#endif
}

-(BOOL)gameIsInLandscapeMode{
	return (([[UIApplication sharedApplication] statusBarOrientation] == UIInterfaceOrientationLandscapeLeft)
	or ([[UIApplication sharedApplication] statusBarOrientation] == UIInterfaceOrientationLandscapeRight));
}

+(BOOL)gameIsInLandscapeMode{
	return [[self alloc] gameIsInLandscapeMode];
}

+ (SFGameSingleton**)getGameSingletonPointer{
	//unique pointer for this class
	return &gSFGameEngine;
}

-(SFPlayer*)createPlayer{
	//later on we can use the plists to customise this
	return [[SFPlayer alloc] initWithDictionary:nil];
}

+(SFViewController*)mainViewController{
    return [[self alloc] mainViewController];
}

@end
