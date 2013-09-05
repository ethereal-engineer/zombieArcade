//
//  ZASceneLogic_Pit.m
//  ZombieArcade
//
//  Created by Adam Iredale on 16/11/09.
//  Copyright 2009 Stormforge Software. All rights reserved.
//

#import "ZASceneLogic_Pit.h"
#import "ZASceneLogic_MainMenu.h"
#import "SFTarget.h"
#import "SFUtils.h"
#import "SF3DObject.h"
#import "SFWidgetLabel.h"
#import "SFConst.h"
#import "ZASettingsMenu.h"
#import "SFGameEngine.h"
#import "SFWeaponHud.h"
#import "SFWidgetDialog.h"
#import "SFColour.h"
#import "SFDebug.h"
#import "SFScene.h"

#define SINGLE_ZOMBIE_MODE 0
#define DEFAULT_MINIMUM_TARGETS 4

@implementation ZASceneLogic_Base

-(void)freezeAllTargets:(BOOL)freeze{
	NSEnumerator *enumerator = [_targets objectEnumerator];
	for (SFTarget *target in enumerator) {
        [target pauseAnimation:freeze];
	}
}

-(void)showInGameMenu:(BOOL)show{
	if (show) {
        _showingInGameMenu = YES;
		[self pause:YES];
		[self freezeAllTargets:YES];
		[_ui addMenu:_inGameMenu];
	} else {
		[_ui popMenu];
		[self freezeAllTargets:NO];
		[self pause:NO];
        _showingInGameMenu = NO;
	}
}

-(void)doQuit{
    [[self sm] changeScene:[[self gi] getMainMenuDictionary]];
}

-(void)quitRequested{
    [self doQuit];
}

-(void)loadWidgets{
	//load the widgets for this scene (overridden)
	//could do an array again for this
	//remember that the order makes the z-order
	[super loadWidgets];
    
	//fucken run!!!! :)
    _fknRun = [[SFWidget alloc] initWidget:@"weaponTray"
                                 atlasItem:@"fknrun" 
                                  position:Vec2Make(440,0)
                                  centered:NO
                             visibleOnShow:YES
                              enableOnShow:YES];
	[_ui addSubWidget:_fknRun];
    [_fknRun release];
	
	//weapon tray
	
	_weaponHud = [_ui addSubWidget:[[SFWeaponHud alloc] initWeaponHud:@"weaponTray"]];

	//in game menu (after pressing fknrun man)
	
	_inGameMenu = [[SFWidgetMenu alloc] initMenu:_mainAtlasName];
	_inGameMenu._hideBackButton = YES;
	
    _btnResume = [_inGameMenu addButton:CGPointMake(0, 6) largeButton:YES];
    _btnHelp   = [_inGameMenu addButton:CGPointMake(0, 7) largeButton:YES];
	_btnOptions = [_inGameMenu addButton:CGPointMake(0, 4) largeButton:YES];
	_btnQuit = [_inGameMenu addButton:CGPointMake(0, 3) largeButton:YES];
}

-(void)precacheImages:(NSMutableArray *)images{
    [super precacheImages:images];
    NSArray *groupShirts = [[self rm] getItemGroup:@"shirt" itemClass:[SFImage class]];
    for (id shirt in groupShirts) {
        [shirt setFlagState:SF_IMAGE_MIPMAP value:YES];
        [shirt prepare];
    }
    NSArray *groupPants = [[self rm] getItemGroup:@"pants" itemClass:[SFImage class]];
    for (id pants in groupPants) {
        [pants setFlagState:SF_IMAGE_MIPMAP value:YES];
        [pants prepare];
    }
}

-(SFTarget*)getSpawnableTarget{
    return (SFTarget*)[_masterZombie findSpawnableObject];
}

-(BOOL)activateTarget:(SF3DObject*)spawnPoint{
    if ([super activateTarget:spawnPoint]) {
        //also spawn the spawn effect if any
        if (_spawnEffect) {
            SF3DObject *availableEffect = [_spawnEffect findSpawnableObject];
            [[self scene] spawnObject:availableEffect withTransform:[spawnPoint transform] adjustZAxis:YES];
            [availableEffect removeAfter:1.0f];
        }
        return YES;
    }
    return NO;
}

-(void)loadTargets{
	[super loadTargets];
	
	//let's load some zombies!!!
	
    int spawnPointCount = [_startPoints count]; 
    
    //create and replicate ragdolls
    _masterRagdoll = [[[self rm] getItem:@"ragdollZombie" itemClass:[SFRagdoll class] tryLoad:YES] retain];
    [_masterRagdoll buildRagdoll];
    [_masterRagdoll setScene:[self scene]];
#if SINGLE_ZOMBIE_MODE == 0
    [_masterRagdoll replicate:spawnPointCount + 2];
#endif
    [[self scene] appendSceneObject:_masterRagdoll];
    
    //create and replicate zombies
    _masterZombie = [[[self rm] getItem:@"targetZombie" itemClass:[SFTarget class] tryLoad:YES] retain];
    [_masterZombie setScene:[self scene]];
    _zombieSearchRadius = MAX([_masterZombie dimensions]->x(), [_masterZombie dimensions]->y()) * 3;
#if SINGLE_ZOMBIE_MODE == 0
    [_masterZombie replicate:spawnPointCount];
#endif
    [[self scene] appendSceneObject:_masterZombie];
    
    //remove them from the resource manager so that we have to recreate them each time
    [[self rm] removeItem:_masterRagdoll];
    [[self rm] removeItem:_masterZombie];
    
	for (int i = 0; i < spawnPointCount; ++i) {
		[self addTarget];
        [self activateTarget:[_startPoints objectAtIndex:i]];
#if SINGLE_ZOMBIE_MODE
        break;
#endif
	}
    
    //if this scene uses a spawn effect then we should load it here
    NSString *spawnEffect = [[self scene] objectInfoForKey:@"spawnEffect"];
    if (spawnEffect) {
        _spawnEffect = [[[self rm] getItem:spawnEffect itemClass:[SF3DObject class] tryLoad:YES] retain];
        [_spawnEffect setScene:[self scene]];
        [_spawnEffect replicate:spawnPointCount];
        [[self scene] appendSceneObject:_spawnEffect];
    }
}

-(void)playFirst{
    [super playFirst];
    [[SFGameEngine getLocalPlayer] equipWeapon:nil];
    //reload silent the default
    [[[SFGameEngine getLocalPlayer] currentWeapon] reload:YES];
    [[self scom] setWeaponDelegate:_weaponHud];
}

-(void)cleanUp{
    [_inGameMenu release];
    [[self scom] setWeaponDelegate:nil];
    [_masterZombie release];
    [_masterRagdoll release];
    [super cleanUp];
}

-(void)updateWeaponHud{
	if ([[[SFGameEngine getLocalPlayer] currentWeapon] isDry]) {
		[[_weaponHud material] setDiffuse:COLOUR_SOLID_RED];
	} else {
		[[_weaponHud material] setDiffuse:COLOUR_SOLID_WHITE];
	}
}

-(void)timeUpEvent{

}

-(void)spawnRandomTarget{
    SF3DObject *spawnPoint = [self selectRandomUnusedSpawnPoint];
    if (![[self scene] countObjectsInAreaXY:[spawnPoint transform]->loc() radius:_zombieSearchRadius filterClass:[_masterZombie class]]) {
        [self activateTarget:spawnPoint];
    }
}

-(BOOL)showHelp{
    //we have made a bit of a workaround for now - we store the help information in
    //the help button.  we loop around until there is no more help to show as in
    //the ui code
    _showingHelp = YES;
    if (_gameHelp){
        if ([_gameHelp nextImage]) {
            return YES; //we have just moved to the next help image
        } else {
            [_ui popOverlay];
            _gameHelp = nil;
        }

    }
    
    SFMenuHelp *menuHelp = nil;
    menuHelp = [_btnHelp getHelp:_currentHelpIndex];
    if (!menuHelp) {
        _currentHelpIndex = 0;
        _showingHelp = NO;
        return NO;
    } else {
        ++_currentHelpIndex;
    }
    
    //display the help
    
    NSString *helpAtlas = [NSString stringWithUTF8String:menuHelp->atlasName];
    NSString *helpName = [NSString stringWithUTF8String:menuHelp->helpName];
    vec4 helpOffset = menuHelp->helpOffset;
    
    _gameHelp = [_ui addOverlay:helpAtlas atlasItem:helpName position:Vec2Zero];
    //don't keep this in memory!
    [[self atlm] unloadAtlas:helpAtlas];  
    [_gameHelp startImageSequence:CGPointMake(helpOffset.x, helpOffset.y)
                        endOffset:CGPointMake(helpOffset.z, helpOffset.w) loop:NO];
    return YES;
}

////////////////
//widgetDelegate
////////////////

-(void)widgetGotScenePick:(id)widget pickObject:(id)pickObject pickVector:(vec3)pickVector{
    [super widgetGotScenePick:widget pickObject:pickObject pickVector:pickVector];
    if ((widget == _ui) and (_logicState == LOGIC_PLAYING)) {
        [[[SFGameEngine getLocalPlayer] currentWeapon] fire:pickVector atTarget:pickObject];
        [self updateWeaponHud];
    }
}

-(void)widgetWasTouched:(id)widget touchKind:(unsigned char)touchKind dragRect:(CGRect)dragRect{
    [super widgetWasTouched:widget touchKind:touchKind dragRect:dragRect];
    switch (touchKind) {
        case CR_WIDGET_PRESSED:
            if (widget == _fknRun) {
                [self showInGameMenu:YES];
            } else if (widget == _btnQuit) {
                [self quitRequested];
            } else if (widget == _btnOptions){
                _inGameSettings = [[ZASettingsMenu alloc] initSettingsMenu:_mainAtlasName];
                [_ui addMenu:_inGameSettings];
                [_inGameSettings release]; //will be released when popped
            } else if (widget == _btnResume){
                [self showInGameMenu:NO];
            } else if (widget == _btnHelp) {
                [_ui popMenu];
                [self showHelp];
            } else if (widget == _gameHelp) {
                if (![self showHelp]) {
                    if (_showingInGameMenu) {
                        //restore the in-game menu if we took it away
                        [_ui addMenu:_inGameMenu];
                    } else {
                        //otherwise just resume play
                        [self pause:NO];
                    }
                }
            }
            break;
        default:
            break;
    }
}

//////////////////
//SFPlayerDelegate
//////////////////

-(void)playerDidChangeWeapons:(id)player currentWeapon:(id)currentWeapon oldWeapon:(id)oldWeapon{
    [super playerDidChangeWeapons:player currentWeapon:currentWeapon oldWeapon:oldWeapon];
    [_weaponHud playerDidChangeWeapons:player currentWeapon:currentWeapon oldWeapon:oldWeapon];
}

-(void)playerGotWeapon:(id)player weapon:(id)weapon{
    [super playerGotWeapon:player weapon:weapon];
    //if the player got this weapon then we need to prep it in the context of this scene!
    [_weaponHud playerGotWeapon:player weapon:weapon];
}

+(int)getMinimumTargetCount{
	//how many zombies to auto-spawn (ie keep in-game) at a time
#if SINGLE_ZOMBIE_MODE
    return 1;
#else
	return DEFAULT_MINIMUM_TARGETS; //normally 4
#endif
}

@end
