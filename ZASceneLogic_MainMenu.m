//
//  ZASceneLogic_MainMenu.m
//  ZombieArcade
//
//  Created by Adam Iredale on 24/11/09.
//  Copyright 2009 Stormforge Software. All rights reserved.
//

#import "ZASceneLogic_MainMenu.h"
#import "SFWidgetLabel.h"
#import "SFDefines.h"
#import "SFListingWidget.h"
#import "ZASceneLogic_Pit.h"
#import "ZASceneLogic_Invasion.h"
#import "SFScene.h"
#import "ZASettingsMenu.h"
#import "SFSound.h"
#import "SFUtils.h"
#import "SFDebug.h"
#import "SFCreditsMenu.h"
#import "SFGameEngine.h"
#import "SFPlayer.h"

#define DEBUG_TROPHIES 0

#define APARTMENT_ZOMBIE 0

#define SOUND_BUTTON_CLICK @"camera2.ogg"
#define SOUND_CONFIRM @"shotgunPump.ogg"
#define SOUND_CONFIRM_FAST @"shotgunPumpFast.ogg"
#define SOUND_SOFT_PRESS @"softPop.ogg"
#define SOUND_CREAK @"creak.ogg"

#define TROPHY_MOVE_TIME 0.5f

#define MINIMUM_SHIRT_DRAG_DISTANCE 50.0f

@interface ZASceneLogic_MainMenu () <GKLeaderboardViewControllerDelegate>

@end

@implementation ZASceneLogic_MainMenu

-(id)shirtFrame{
    if (!_shirtFrame) {
        _shirtFrame = [[self scene] getItem:@"shirtFrame" itemClass:[SF3DObject class]];
    }
    return _shirtFrame;
}

-(void)setFrameShirt:(NSString*)resourceId{
    //a shirt achievement id will be passed to us - look it up and
    //set it as our shirt texture - also, save it as the player favourite
    SFPlayer *player = [SFGameEngine getLocalPlayer];
    NSString *shirtName;
    if (resourceId) {
        shirtName = [[[self gi] getAchievementInfo:resourceId] objectForKey:@"objectName"];
    } else {
        [player removeObjectInfoForKey:@"apartmentShirt"];
        shirtName = @"shirt0.tga";
    }
    if (!shirtName) {
        sfDebug(TRUE, "Bad shirt name");
        return;
    }
    SFImage *texture = [[self rm] getItem:shirtName itemClass:[SFImage class] tryLoad:YES];
    if (!texture) {
        sfDebug(TRUE, "Bad shirt texture");
        return;
    }
    [texture setFlagState:SF_IMAGE_MIPMAP value:YES]; //mipmap the clothes
    [texture prepare];
    SFVertexGroup *shirtVerts = [[self shirtFrame] vertexGroupByName:@"wallShirt"];
    [[shirtVerts material] setTexture:SF_MATERIAL_CHANNEL0 texture:texture];
    //now set it as the player favourite
    if (resourceId) {
        [player setObjectInfo:resourceId forKey:@"apartmentShirt"];
    }
}

-(NSString*)apartmentShirtId{
    //check if the player has a specific shirt they like in the frame
    return [[SFGameEngine getLocalPlayer] objectInfoForKey:@"apartmentShirt"];
}

-(void)setApartmentShirt{
    //check if the player has a specific shirt they like in the frame
    NSString *shirtResourceId = [self apartmentShirtId];
    if (shirtResourceId) {
        if (![[SFGameEngine getLocalPlayer] achievementIsUnlocked:shirtResourceId]) {
            //somehow perhaps another player has logged in?
            //if they didn't earn the shirt, they can't have it up
            [self setFrameShirt:nil];
        } else {
            //put this shirt on the wall
            [self setFrameShirt:shirtResourceId];
        }
    }
}

-(void)returnTrophy{
    _trophyState = tsPutting;
    _currentTrophyPath = [[SFIpo alloc] initSimpleIpo:[_currentTrophy transform] to:_currentTrophyTransform seconds:TROPHY_MOVE_TIME];
    [_currentTrophy setIpo:_currentTrophyPath];
    [_currentTrophyPath play:self];
    delete _currentTrophyTransform;
    _currentTrophyTransform = nil;
}

-(void)spinTrophy{
    _trophyState = tsSpinning;
    _currentTrophyPath = [[[self scene] getItem:@"spinTrophy" itemClass:[SFIpo class]] retain];
    [_currentTrophyPath clampRotation];
    [_currentTrophy setIpo:_currentTrophyPath];
    [_currentTrophyPath play:self];
}


-(void)ipoStopped:(id)ipo{
    //ipo stopped switchboard
    if (ipo == _currentTrophyPath) {
        //get rid of the link to this one
        [_currentTrophyPath release];
        _currentTrophyPath = nil;
        //depending on the trophy state, take the next action
        switch (_trophyState) {
            case tsGetting:
                [self spinTrophy];
                break;
            case tsSpinning:
                [self returnTrophy];
                break;
            case tsPutting:
                //play the trophy put sound and nil the trophy
                _trophyState = tsNone;
                [_currentTrophy playPutSound];
                [_currentTrophy release];
                _currentTrophy = nil;
                break;
            default:
                break;
        }
    } else if (ipo == _shirtFrameIpo) {
        if ([[ipo name] isEqualToString:@"getShirtFrame"]) {
            //the shirt is off the wall, change it and put it back
            [self shirtOffWall];
        } else if ([[ipo name] isEqualToString:@"putShirtFrame"]){
            [self shirtOnWall];
        } else {
            //we have just straightened the shirt - for comic value
            //now we're done
            [[self shirtFrame] playFXSound:SOUND_CREAK];
            [_shirtFrameIpo release];
            _shirtFrameIpo = nil;
        }

    }
}

-(SFTransform*)trophyViewPos{
    if (!_trophyViewPos) {
        _trophyViewPos = [[[self scene] getItem:@"trophyViewPos" itemClass:[SF3DObject class]] retain];
    }
    return [_trophyViewPos transform];
}

-(void)showTrophy:(SF3DObject*)trophy{
    _trophyState = tsGetting;
    _currentTrophyTransform = [trophy transform]->copy();
#if DEBUG_TROPHIES
    printf("Trophy transform:\n");
    [trophy transform]->print();
#endif
    _currentTrophyPath = [[SFIpo alloc] initSimpleIpo:[trophy transform] to:[self trophyViewPos] seconds:TROPHY_MOVE_TIME];
    [trophy setIpo:_currentTrophyPath];
    [_currentTrophyPath play:self];
    _currentTrophy = [trophy retain];
    [trophy playGetSound];
}

-(void)pickTrophy:(SF3DObject*)pickObject{
	if (_currentTrophy) {
		//when looking at a trophy, touching anywhere returns the trophy
		[self returnTrophy];
		return;
	}
	if ([pickObject getBlenderTag] != SF_OBJECT_TAG_INVALID) {
		switch ([pickObject getBlenderTag]) {
			case MENU_3D_PICK_TROPHY_CASE:
				break;
			case MENU_3D_PICK_TROPHY:
				[self showTrophy:pickObject];
				break;
			case MENU_3D_PICK_GREE:
                [SFSound quickPlayAmbient:SOUND_SOFT_PRESS];
				[self showGameCenterMenu];
				break;
			case MENU_3D_PICK_CLIPBOARD:
                [self zoomPush:pickObject];
				break;
			default:
				break;
		}
	}
}

-(void)getNextUnlockedShirt{
    //depending on the direction of the drag, we may actually return
    //the PREVIOUS unlocked shirt
    //this is such crap code... replace when possible
    
    NSDictionary *achievements = [[self gi] getAchievementDictionary];
    SFPlayer *player = [SFGameEngine getLocalPlayer];
    NSArray *achievementIds = [achievements allKeys];
    
    int countStart, countEnd;

    if (_shirtMoveDirection > 0) {
        countStart = 0;
        countEnd = [achievementIds count] - 1;
    } else {
        countStart = [achievementIds count] - 1;
        countEnd = -1;
    }

    NSString *apartmentShirtId = [self apartmentShirtId];
    if (apartmentShirtId) {
        countStart = [achievementIds indexOfObject:apartmentShirtId];
    }    
    
    BOOL shirtFound = NO;
    
    for (int i = countStart; i != countEnd; i += _shirtMoveDirection) {
        NSString *resourceId = [achievementIds objectAtIndex:i];
        if ([apartmentShirtId isEqualToString:resourceId]) {
            continue;
        }
        if ([player achievementIsUnlocked:resourceId]) {
            //ok, this is unlocked - is it a shirt?
            NSDictionary *achievement = [achievements objectForKey:resourceId];
            if ([[achievement objectForKey:@"kind"] isEqualToString:@"shirt"]) {
                //this is a shirt! let's use it!
                [self setFrameShirt:resourceId];
                shirtFound = YES;
                break;
            }
        }
    }
    
    if (!shirtFound) {
        [self setFrameShirt:nil];
    }
    
}

-(void)shirtOnWall{
    //the shirt is on the wall, - play the noise 
    [[self shirtFrame] playPutSound]; 
    //then straighten - for a laugh
    [_shirtFrameIpo release];
    _shirtFrameIpo = [[[self scene] getItem:@"straightenShirtFrame" itemClass:[SFIpo class]] retain];
    [[self shirtFrame] setIpo:_shirtFrameIpo];
    [_shirtFrameIpo play:self];
}

-(void)shirtOffWall{
    id shirtFrame = [self shirtFrame];
	//now we change the shirt in the frame and put it back on the wall
    [self getNextUnlockedShirt];
    [_shirtFrameIpo release];
    _shirtFrameIpo = [[[self scene] getItem:@"putShirtFrame" itemClass:[SFIpo class]] retain];
    [shirtFrame setIpo:_shirtFrameIpo];
    [_shirtFrameIpo play:self];
}

-(void)handleShirtDrag:(CGRect)dragRect{
    if (_shirtFrameIpo) {
        return; //still dragging
    }
    if (ABS(dragRect.size.width) < MINIMUM_SHIRT_DRAG_DISTANCE) {
        return;
    }
    //if the drag was to the right then set that we are moving "next"
    _shirtMoveDirection = (dragRect.size.width / ABS(dragRect.size.width));
    SF3DObject *shirtFrame = [self shirtFrame];
    _shirtFrameIpo = [[[self scene] getItem:@"getShirtFrame" itemClass:[SFIpo class]] retain];
    [shirtFrame setIpo:_shirtFrameIpo];
    [_shirtFrameIpo play:self];
    [shirtFrame playGetSound];
}

-(void)showGameCenterMenu{
    GKLeaderboardViewController *leaderboardController = [[GKLeaderboardViewController alloc] init];
    if (leaderboardController != nil)
    {
        leaderboardController.leaderboardDelegate = self;
        [[SFGameEngine mainViewController] stopGLAnimation];
        [[SFGameEngine mainViewController] presentModalViewController: leaderboardController animated: YES];
    }
}

-(void)zoomPop{
    //pops an object from the stack and zooms out from it
    NSString *zoomUndo = [[_zoomUndo peek] retain];
    [_zoomUndo pop];
    [SFSound quickPlayAmbient:SOUND_SOFT_PRESS];
    [[[self scene] camera] setIpoName:zoomUndo];
    [zoomUndo release];
}

-(void)cameraWillMove:(id)camera{
    [super cameraWillMove:camera];
    if (_zoomingIn) {
        _zoomingIn = NO;
    } else {
        //pop the current menu object
        id popped = [[_zoomObject peek] retain];
        [_zoomObject pop];
        sfDebug(TRUE, "Popped from zoom objects: %s", [popped UTF8Description]);
        [popped release];
    }
}

-(void)cameraDidMove:(id)camera{
#if APARTMENT_ZOMBIE
    SFTarget *zom;
#endif
    [super cameraDidMove:camera];
    //open the current menu
    SF3DObject *zoomObject = [[_zoomObject peek] retain];
    if (!zoomObject) {
        return; //nothing to do
    }
	if ([zoomObject getBlenderTag] != SF_OBJECT_TAG_INVALID) {
		//tags are used as indicators in this case as to which
		//menu should be launched etc
		switch ([zoomObject getBlenderTag]) {
			case MENU_3D_PICK_WEAPON_CASE:
				[_ui addMenu:[self gameMenuWidget]];
				break;
			case MENU_3D_PICK_HIFI:
			case MENU_3D_PICK_HIFI_CABINET:
				[_ui addMenu:[self settingsMenuWidget]];
				break;
			case MENU_3D_PICK_TROPHY_CASE:
			case MENU_3D_PICK_GREE:
				[_ui addMenu:[self trophyMenuWidget]];
				break;
            case MENU_3D_PICK_CLIPBOARD:
                [_ui addMenu:[self creditTourWidget]];
                _zoomingIn = YES;  //compensate for the camera movement of the credits (otherwise it removes menus early)
                [_menuCredits startRollingCredits];
#if APARTMENT_ZOMBIE
                zom = [[self rm] getItem:@"targetZombie" itemClass:[SFTarget class] tryLoad:YES];
                [zom setScene:[self scene]];
                [[self scene] appendSceneObject:zom];
                [[self scene] spawnObject:zom withTransform:[(SF3DObject*)[_startPoints objectAtIndex:0] transform] adjustZAxis:NO];
                [_targets addObject:zom];
#endif
                break;
			case MENU_3D_PICK_SHIRT_FRAME:
				[_ui addMenu:[self shirtMenuWidget]];
				break;
			default:
				break;
		}
	}
    [zoomObject release];
}

-(void)zoomPush:(id)object{
    //zoom to an object, basically
    if (_zoomingIn) {
        return;
    }
    if (![object getBlenderInfo:@"pathSuffix"]) {
        return;
    }
    NSString *zoomDo = [@"to" stringByAppendingString:[object getBlenderInfo:@"pathSuffix"]];
    [_zoomObject push:object];
    [_zoomUndo push:[[NSString stringWithString:@"from"] stringByAppendingString:[object getBlenderInfo:@"pathSuffix"]]];
    [SFSound quickPlayAmbient:SOUND_SOFT_PRESS];
    _zoomingIn = YES;
    [[[self scene] camera] setIpoName:zoomDo];
}

-(id)initWithDrone:(id)drone dictionary:(NSDictionary*)dictionary{
	self = [super initWithDrone:drone dictionary:dictionary];
	if (self != nil) {
        _gameModes = [[NSMutableDictionary alloc] init];
        _zoomObject = [[SFStack alloc] initStack:YES useFifo:NO];
        _zoomUndo = [[SFStack alloc] initStack:YES useFifo:NO];
        //little waiting dude for right bottom corner
        _waiting = [[SFWidget alloc] initWidget:@"main"
                                      atlasItem:@"waiting"
                                       position:Vec2Make(441, 0)
                                       centered:NO
                                  visibleOnShow:YES
                                   enableOnShow:NO];
	}
	return self;
}

-(void)loadTrophyForPlaceholder:(SF3DObject*)trophyPos{
    //spawn the achievement in the same spot
    SF3DObject *trophy = [[self rm] getItem:[trophyPos getBlenderInfo:@"trophyMesh"]
                                  itemClass:[SF3DObject class] tryLoad:YES];
    sfAssert(trophy != nil, "Can't find trophy mesh %s", [[trophyPos getBlenderInfo:@"trophyMesh"] UTF8String]);
    [[self scene] appendSceneObject:trophy];
    [[self scene] spawnObject:trophy withTransform:[trophyPos transform] adjustZAxis:YES];     
}

-(NSArray*)trophyPlaceholders{
    if (!_trophyPos) {
        _trophyPos = [[[self scene] getItemGroup:@"trophyPos" itemClass:[SF3DObject class]] retain];
    }
    return _trophyPos;
}

-(void)appendTrophyByAchievementId:(NSString*)resourceId{
    for (SF3DObject *trophyPos in [self trophyPlaceholders]) {
        if ([[trophyPos getBlenderInfo:@"trophyId"] isEqualToString:resourceId]) {
            [self loadTrophyForPlaceholder:trophyPos];
            break;
        }
    }
}

-(void)loadTrophies{
    //for each trophy, see if it has been achieved - if so, load the trophy model etc
    for (SF3DObject *trophyPos in [self trophyPlaceholders]) {
#if DEBUG_TROPHIES
        printf("Trophy Pos %s transform:\n", [trophyPos UTF8Description]);
        [trophyPos transform]->print();
#endif
        if ([[SFGameEngine getLocalPlayer] achievementIsUnlocked:[trophyPos getBlenderInfo:@"trophyId"]]) {
            //spawn the achievement in the same spot
            [self loadTrophyForPlaceholder:trophyPos];
        }
    }
}

- (void)achievementsSynchronised
{
    [self loadTrophies];
    [self setApartmentShirt];
}

-(void)loadPlayerData{
	[super loadPlayerData];
    [self loadTrophies];
    [self setApartmentShirt];
}

-(void)precacheSounds:(NSMutableArray *)sounds{
    [super precacheSounds:sounds];
    [sounds addObject:SOUND_BUTTON_CLICK];
    [sounds addObject:SOUND_CONFIRM];
    [sounds addObject:SOUND_CONFIRM_FAST];
    [sounds addObject:SOUND_SOFT_PRESS];
    [sounds addObject:SOUND_CREAK];
}

-(void)soundPrecachingComplete{
    [super soundPrecachingComplete];
    [_ui setPopMenuSound:SOUND_SOFT_PRESS];
    [_ui setHelpSound:SOUND_SOFT_PRESS];
}

-(void)cleanUp{
    [_menuShirts release];
    [_menuCredits release];
    [_menuTrophies release];
    [_menuSettings release];
    [_menuGame release];
    [_gameStyle release];
    [_resumeGameWidget release];
    [_dialog release];
    [_gameModes release];
    [_zoomUndo release];
    [_zoomObject release];
    [_waiting release];
    [_trophyPos release];
    [_trophyViewPos release];
    [_levelSelect release];
    [super cleanUp];
}

-(void)showWaiting:(BOOL)show{
    if (show) {
        [_ui addSubWidget:_waiting];
    } else {
        [_ui removeSubWidget:_waiting];
    }

}

-(void)buildLevelSelectControl:(id)destinationControl gameMode:(id)gameMode sceneInfo:(id)sceneInfo{
    //infuse the scene dictionary with the game mode info here
    //only if it is enabled for this kind of logic
    id logicIdentifier = [gameMode objectForKey:@"identifier"];
    if (![[sceneInfo objectForKey:@"enabledForType"] containsObject:logicIdentifier]) {
        return;
    }
    NSMutableDictionary *logicInfusedScene = [NSMutableDictionary dictionaryWithDictionary:sceneInfo];
    [logicInfusedScene setObject:gameMode forKey:@"gameMode"];
    //and set the description to use the correct one for this game mode
    [logicInfusedScene setObject:[[logicInfusedScene objectForKey:@"descriptions"] objectForKey:logicIdentifier] forKey:@"description"];
    //sfDebug(TRUE, "Adding %s level %s...", [logicIdentifier UTF8String], [[sceneInfo objectForKey:@"title"] UTF8String]);
    [destinationControl addListingItem:logicInfusedScene];
}

-(void)buildLevelSelectControlsForGameMode:(id)gameMode{
	//first build the widget for it then populate it
    SFListingWidget *listingWidget = [[SFListingWidget alloc] initListingWidget:@"icons"
                                                                       iconItem:@"gameIcons" blankCaption:@"No Levels"];
    [listingWidget setTitle:@"SELECT LEVEL"];
    [listingWidget addHelp:@"helpShirtTrophyLvl" helpName:@"default" helpOffset:Vec4Make(1, 0, 1, 0)];
    NSEnumerator *enumerator = [[[self gi] getLevelArray] objectEnumerator];
	for (NSDictionary *sceneInfo in enumerator){
		[self buildLevelSelectControl:listingWidget gameMode:gameMode sceneInfo:sceneInfo];
	}
    [_gameModes setObject:listingWidget forKey:[gameMode objectForKey:@"identifier"]]; //keep a ref somewhere neat
    [listingWidget release]; //release when gamemodes is emptied
}

-(void)loadGameModes{
	NSArray *gameModeArray = [[self gi] getGameModeArray];
	NSEnumerator *gameModes = [gameModeArray objectEnumerator];
	for (NSDictionary *gameMode in gameModes) {
		[_gameStyle addListingItem:gameMode];
        [self buildLevelSelectControlsForGameMode:gameMode];
	}
}

-(void)loadWidgets{
    [super loadWidgets];
    [_ui addHelp:@"helpMain" 
        helpName:@"default" 
      helpOffset:Vec4Make(0, 0, 1, 2)];
    [_ui enableLogo:YES];
}

-(void)play{
    [super play];
    //if this is the first run of the game, show the main help
    
    id localPlayer = [SFGameEngine getLocalPlayer];
    if ([localPlayer hasSeenHelp:@"mainMenu"]) {
        return;
    }
    [_ui invokeHelp];
    [localPlayer setHasSeenHelp:@"mainMenu"];
}

//lazy-load widgets!

-(id)trophyMenuWidget{
    if (!_menuTrophies) {
        _menuTrophies = [[SFWidgetMenu alloc] initMenu:_mainAtlasName];
        [_menuTrophies setEnabled:NO];
        [_menuTrophies setWantsScenePick:YES];
        [_menuTrophies setClearBackground];
        [_menuTrophies setTitle:@"TROPHY CABINET"];
        [_menuTrophies addHelp:@"helpShirtTrophyLvl" helpName:@"default" helpOffset:Vec4Make(0, 0, 0, 2)];
    }
    return _menuTrophies;
}

-(id)creditTourWidget{
    if (!_menuCredits) {
        _menuCredits = [[SFCreditsMenu alloc] initMenu:_mainAtlasName];
        [_menuCredits setClearBackground];
        [_menuCredits setTitle:@"CREDITS"];
        [_menuCredits setScene:[self scene]];
        [_menuCredits setBackPassthrough]; //allows us to zoom back when done
    }
    return _menuCredits;
}

-(id)settingsMenuWidget{
    if (!_menuSettings) {
        _menuSettings = [[ZASettingsMenu alloc] initSettingsMenu:_mainAtlasName];
        [_menuSettings setTitle:@"SETTINGS"];
    }
    return _menuSettings;
}

-(id)shirtMenuWidget{
    if (!_menuShirts) {
        _menuShirts = [[SFWidgetMenu alloc] initMenu:_mainAtlasName];
        [_menuShirts setClearBackground];
        [_menuShirts setTitle:@"ZOMBIE SHIRT COLLECTION"];
        [_menuShirts addHelp:@"helpShirtTrophyLvl" helpName:@"default" helpOffset:Vec4Make(1, 1, 1, 2)];
    }
    return _menuShirts;
}

-(id)gameMenuWidget{
    if (!_menuGame) {
        _menuGame = [[SFWidgetMenu alloc] initMenu:_mainAtlasName];
        [_menuGame setMargins:0 top:30 right:0 bottom:50];
        _btnNewGame = [_menuGame addButton:CGPointMake(0, 2) largeButton:YES];
        _btnResumeGame = [_menuGame addButton:CGPointMake(0, 6) largeButton:YES];
        [_menuGame setTitle:@"PLAY"];
    }
    return _menuGame;
}

-(id)gameStyleWidget{
    if (!_gameStyle) {
        _gameStyle = [[SFListingWidget alloc] initListingWidget:@"icons"
                                                       iconItem:@"gameIcons" 
                                                   blankCaption:@"No Game Modes"];
        [_gameStyle setTitle:@"GAME MODE"];
        [_gameStyle addHelp:@"helpGameMode" helpName:@"default" helpOffset:Vec4Make(0, 0, 0, 2)];
        [self loadGameModes];
    }
    return _gameStyle;
}

-(void)populateResume{
    //for each saved game in a player profile, add an entry
    NSEnumerator *savedGames = [[[SFGameEngine getLocalPlayer] savedGames] objectEnumerator];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    [dateFormatter setTimeStyle:NSDateFormatterMediumStyle];
    for (NSDictionary *savedGame in savedGames) {
        NSMutableDictionary *listingItem = [[NSMutableDictionary alloc] initWithDictionary:savedGame];
        NSDictionary *savedScom = [savedGame objectForKey:@"savedScom"];
        NSMutableArray *description = [[NSMutableArray alloc] init];
        [description addObject:[NSString stringWithFormat:@"Last played: %s", [[dateFormatter stringFromDate:[savedGame objectForKey:@"timestamp"]] UTF8String]]];
        [description addObject:@"Game Mode:   INVASION (Challenge)"];
        [description addObject:[@"Grade:       " stringByAppendingString:[[savedScom objectForKey:@"gradeNumber"] stringValue]]];
        [description addObject:[NSString stringWithFormat:@"Health:      %.f %%", [[savedGame objectForKey:@"playerHealth"] floatValue]]];
        [description addObject:[@"Score:       " stringByAppendingString:[[savedScom objectForKey:@"score"] stringValue]]];
        if ([[savedGame objectForKey:@"autoSaved"] boolValue]){
            [description addObject:@"(autosaved)"];
        }
        [listingItem setObject:[description componentsJoinedByString:@"\n"] forKey:@"description"];
        [description release];
        [_resumeGameWidget addListingItem:listingItem];
        [listingItem release];
    }
    [dateFormatter release];
}

-(id)resumeGameWidget{
    if (!_resumeGameWidget){
        _resumeGameWidget = [[SFListingWidget alloc] initListingWidget:@"icons"
                                                              iconItem:@"gameIcons"
                                                          blankCaption:@"No Saved Games"];
        [_resumeGameWidget setTitle:@"RESUME GAME"];
        [_resumeGameWidget showListingNumbers:YES];
        [_resumeGameWidget showDeleteButton:YES];
        [_resumeGameWidget addHelp:@"helpGameMode" helpName:@"default" helpOffset:Vec4Make(1, 0, 1, 2)];
        [self populateResume];
    }
    return _resumeGameWidget;
}

-(void)deleteSavedGame{
    //delete the selected save file from
    //the resume listing widget
    [[SFGameEngine getLocalPlayer] deleteSavedGame:[[_resumeGameWidget getSelectedItem] objectForKey:@"timestamp"]];
    [_resumeGameWidget deleteSelectedItem];
}

////////////////
//widgetDelegate
////////////////

-(void)widgetGotScenePick:(id)widget pickObject:(id)pickObject pickVector:(vec3)pickVector{
    [super widgetGotScenePick:widget pickObject:pickObject pickVector:pickVector];
    if (widget == _ui) {
        //we have picked with no menu showing - just do the basic apartment pick
        if ([[pickObject name] isEqualToString:@"clipboard"]) {
            //zoom to the trophy cabinet instead
            [self zoomPush:[[self scene] get3DObject:@"displayCaseBox1"]];
        } else {
            [self zoomPush:pickObject];
        }
    } else if (widget == _menuTrophies) {
        //ahhh, we are picking trophies etc
        [self pickTrophy:pickObject];
    }
}

-(void)widgetWasTouched:(id)widget touchKind:(unsigned char)touchKind dragRect:(CGRect)dragRect{
    [super widgetWasTouched:widget touchKind:touchKind dragRect:dragRect];
    switch (touchKind) {
        case CR_WIDGET_PRESSED:
            if (widget == _btnNewGame) {
                [SFSound quickPlayAmbient:SOUND_BUTTON_CLICK];
                [_ui addMenu:[self gameStyleWidget]];
            } else if (widget == _btnResumeGame) {
                [SFSound quickPlayAmbient:SOUND_BUTTON_CLICK];
                [_ui addMenu:[self resumeGameWidget]];
            }
        case CR_TOUCH_TAP_UP:
            if (widget == _menuShirts) {
                [self handleShirtDrag:dragRect];
            }
            break;

            break;
        default:
            break;
    }    
}

-(void)widgetCallback:(id)widget reason:(unsigned char)reason{
    [super widgetCallback:widget reason:reason];
    if (widget == _dialog) {
        switch (reason) {
            case CR_YES:
                [self deleteSavedGame];
            default:
                [_ui popMenu];
                break;
        }
        [SFSound quickPlayAmbient:SOUND_BUTTON_CLICK];
    } else {
        switch (reason) {
            case CR_MENU_HELP:
                //a menu of ours - the top most one, actually, needs help shown
                break;
            case CR_MENU_BACK:
                //it's debatable how far we should let this go....
                if (_currentTrophy) {
                    //there is a trophy out - put it back
                    [self returnTrophy];
                }
                [self zoomPop];
                break;
            case CR_MENU_ITEM_TOUCHED_AUX:
                if (widget == _gameStyle) {
                    [_levelSelect release];
                    _levelSelect = [[_gameModes objectForKey:[[_gameStyle getSelectedItem] objectForKey:@"identifier"]] retain];
                    [SFSound quickPlayAmbient:SOUND_BUTTON_CLICK];
                    [_ui addMenu:_levelSelect];
                } else if ((widget == _levelSelect) or (widget == _resumeGameWidget)) {
                    //the level has been chosen - launch it
                    NSDictionary *sceneInfo = [[widget getSelectedItem] retain];
                    [SFSound quickPlayAmbient:SOUND_CONFIRM];
                    [[self sm] changeScene:sceneInfo];
                    [sceneInfo release];
                }
                break;
            case CR_MENU_DELETE:
                if (widget == _resumeGameWidget) {
                    [SFSound quickPlayAmbient:SOUND_BUTTON_CLICK];
                    [_dialog release];
                    _dialog = [[SFWidgetDialog alloc] initDialog:@"Delete this saved game? Are you sure?"];
                    [_ui addMenu:_dialog];
                }
                break;
            default:
                break;
        }
    }
}

//////////////////
//SFPlayerDelegate
//////////////////

-(void)playerUnlockedAchievement:(NSString*)resourceId achievementInfo:(NSDictionary*)achievementInfo{
    //trophies are already loaded at this stage so we just append if there is sync change
    [super playerUnlockedAchievement:resourceId achievementInfo:achievementInfo];
    NSString *kind = [achievementInfo objectForKey:@"kind"];
    if ([kind isEqualToString:@"trophy"]) {
        [self appendTrophyByAchievementId:resourceId];
    }
}

#pragma mark - Leaderboard Delegate

- (void)leaderboardViewControllerDidFinish:(GKLeaderboardViewController *)viewController
{
    [viewController dismissViewControllerAnimated:YES
                                       completion:^{
                                           [[SFGameEngine mainViewController] startGLAnimation];
                                       }];
}

@end
