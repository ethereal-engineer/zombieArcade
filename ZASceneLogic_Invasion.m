//
//  ZASceneLogic_Invasion.m
//  ZombieArcade
//
//  Created by Adam Iredale on 30/12/09.
//  Copyright 2009 Stormforge Software. All rights reserved.
//

#import "ZASceneLogic_Invasion.h"
#import "SFConst.h"
#import "SFUtils.h"
#import "ZASceneLogic_MainMenu.h"
#import "SFGameEngine.h"
#import "SFColour.h"
#import "SFSound.h"

#define MAX_SCORE_SIZE 8 //how many digits max? default is enough for 99,999,999
#define GAME_OVER_DISPLAY_MIN_MS 3000
#define GRADE_UP_LABEL_SOLID_TIME 2.0f
#define GRADE_UP_LABEL_FADE_TIME 0.5f
#define PLAYER_HURT_FLASH_ON 0.25f
#define PLAYER_HURT_FLASH_OFF 0.1f
#define PLAYER_HURT_FLASH_DURATION 2.0f
#define HEALTH_BAR_FLASH_AT_LESS_THAN 10.0f
#define DEBUG_OVERHEAD_CAMERA 0

@implementation ZASceneLogic_Invasion

-(id)initCopyWithDictionary:(NSDictionary *)dictionary{
    self = [super initCopyWithDictionary:dictionary];
    if (self != nil) {
        _autoSaveScene = YES;
    }
    return self;
}

-(NSString*)getActiveCameraName{
#if DEBUG_OVERHEAD_CAMERA
    return @"Camera.Side";
#endif
	return @"Camera.Invasion";
}

-(id)quitPrompt{
    if (!_dialog) {
        _dialog = [[SFWidgetDialog alloc] initDialog:@"Would you like to save your game for later?"];
    }
    return _dialog;
}

-(void)cleanUp{
    [_dialog release];
    [_healthBar release];
    [super cleanUp];
}

-(void)quitRequested{
    [_ui addMenu:[self quitPrompt]];
}

-(void)showGradeScreen{
	//show what grade we have aspired to...
	[super showGradeScreen];
    [self pause:YES];
    int currentGrade = lroundf(_lastKnownGrade);
    [_ui addSubWidget:_gradeLabel];
    [_gradeLabel setCaption:[NSString stringWithFormat:@"Grade %d:\n%s", 
                             currentGrade, 
                             [[_gradePhrases objectAtIndex:currentGrade - 1] UTF8String]]];
	[_gradeLabel setFadeOut:GRADE_UP_LABEL_SOLID_TIME
                    fadeOut:GRADE_UP_LABEL_FADE_TIME];
    //if this isn't the first grade, play a "ding"
    if (currentGrade > 1) {
        [SFSound quickPlayAmbient:@"boxingBellRing.ogg"];
    }
}

-(void)loadWidgets{
	[super loadWidgets];
    
    //hud bar
    [_ui setTopBarOffset:CGPointMake(0, 1)];
    
    //health bar
    _healthBar = [[SFHealthWidget alloc] initHealthWidget:_mainAtlasName
                                                atlasItem:@"healthBar"
                                                 maxValue:100.0f                                                                   
                                                 minValue:0.0f 
                                                 position:Vec2Make(79, 8)
                                                  visible:YES];
	[_healthBar flashAtLessThan:HEALTH_BAR_FLASH_AT_LESS_THAN];
    [[_ui topBar] addSubWidget:_healthBar];
    
    //game over widget
	_gameOver = [[SFWidget alloc] initWidget:_mainAtlasName
								   atlasItem:@"gameOver"
									position:Vec2Make(240, 150)
									centered:YES
							   visibleOnShow:YES
                                enableOnShow:YES];
	
    //phrases for the grade label
	_gradePhrases = [[self gi] getGameTextArray:@"grades"];
    
    //the grade label
	_gradeLabel = [[SFWidgetLabel alloc] initLabel:@"bloodScrawl32"
                                                   initialCaption:@"-"
                                                         position:Vec2Make(240, 170)
                                                         centered:YES
                                                    visibleOnShow:YES
                                                updateViaCallback:NO];
    [_gradeLabel setJustification:ljCenter];
    
    //the score counter
	_score = [[SFWidgetLabel alloc] initLabel:@"appleCasual16"
                               initialCaption:@"0"
                                     position:Vec2Make(397.0, 2.0)
                                     centered:NO
                                visibleOnShow:YES
                            updateViaCallback:NO];
    [[_ui topBar] addSubWidget:_score];
    
    //the perfect counter
	_perfectCount = [[SFWidgetLabel alloc] initLabel:@"appleCasual16"
                               initialCaption:@"0"
                                     position:Vec2Make(262.0, 2.0)
                                     centered:NO
                                visibleOnShow:YES
                            updateViaCallback:NO];
    [[_ui topBar] addSubWidget:_perfectCount];
    
    //add help for the in-game menu
    [_btnHelp addHelp:@"helpInGame1" helpName:@"default" helpOffset:Vec4Make(0, 0, 1, 1)];
    [_btnHelp addHelp:@"helpInGame2" helpName:@"default" helpOffset:Vec4Make(0, 0, 1, 1)];
    [_btnHelp addHelp:@"helpInGame1" helpName:@"default" helpOffset:Vec4Make(0, 2, 1, 2)];
}

-(void)precacheSounds:(NSMutableArray *)sounds{
    [super precacheSounds:sounds];
    [sounds addObject:@"unlock.ogg"];
}

-(void)checkFirstHelp{
    id localPlayer = [SFGameEngine getLocalPlayer];
    if ([localPlayer hasSeenHelp:@"invasionGame"]) {
        return;
    }
    [self showHelp];
    [localPlayer setHasSeenHelp:@"invasionGame"];
}

////////////////
//widgetDelegate
////////////////

-(void)widgetWasTouched:(id)widget touchKind:(unsigned char)touchKind dragRect:(CGRect)dragRect{
    [super widgetWasTouched:widget touchKind:touchKind dragRect:dragRect];
    switch (touchKind) {
        case CR_WIDGET_PRESSED:
            if ((widget == _gameOver) and ([SFUtils getAppTimeDiff:_gameOverTime] > GAME_OVER_DISPLAY_MIN_MS)) {
                [self doQuit];
            }
            break;
        default:
            break;
    }
}

-(void)widgetCallback:(id)widget reason:(unsigned char)reason{
    [super widgetCallback:widget reason:reason];
    if (widget == _dialog) {
        switch (reason) {
            case CR_CANCEL:
                [_ui popMenu];
                break;
            case CR_YES:
                [[self scom] compileAndSave:NO];
            case CR_NO:
                [self doQuit];
                break;
            default:
                break;
        }
    } else {
        switch (reason) {
            case CR_FADE_COMPLETE:
                if (widget == _gradeLabel) {
                    [_ui removeSubWidget:_gradeLabel];
                    //unpause - but only if we aren't in the
                    //in-game menu or showing help
                    [self checkFirstHelp];
                    [self pause:(_showingInGameMenu or _showingHelp)];
                }
                break;
            default:
                break;
        }
    }
}

////////////////////////
//SFScoreDisplayDelegate
////////////////////////

-(void)scoreDidChange:(float)newScore oldScore:(float)oldScore{
    char score[MAX_SCORE_SIZE + 1] = {""};
    sprintf((char*)&score, "%d", (int)lroundf(newScore));
    [_score setCaption:[NSString stringWithUTF8String:score]];
}

-(void)perfectStreakDidChange:(float)newStreak oldStreak:(float)oldStreak topStreak:(float)topStreak{
    [super perfectStreakDidChange:newStreak oldStreak:oldStreak topStreak:topStreak];
    //if this is the top streak, add a bit of colour to the label, otherwise just let it be
    //that is, if we are going upwards...
    if ((newStreak > oldStreak) and (newStreak >= topStreak)){
        [[_perfectCount material] fadeColour:COLOUR_GOLD fadeTime:2.0f];
        //[[_perfectCount material] setDefaultDiffuse:COLOUR_GOLD];
    } else {
        [[_perfectCount material] setDefaultDiffuse:COLOUR_SOLID_WHITE];
    }

    char perfect[MAX_SCORE_SIZE + 1] = {""};
    sprintf((char*)&perfect, "%d", (int)lroundf(newStreak));
    [_perfectCount setCaption:[NSString stringWithUTF8String:perfect]];
}

//////////////////////
//SFLevelGradeDelegate
//////////////////////

-(void)gradeDidChange:(float)newGrade oldGrade:(float)oldGrade{
    _lastKnownGrade = newGrade;
    [super gradeDidChange:newGrade oldGrade:oldGrade];
    [self pause:YES];
}

/////////////////////
//SFPlayerHudDelegate
/////////////////////

-(void)playerHealthDidChange:(float)newHealth oldHealth:(float)oldHealth{
    [super playerHealthDidChange:newHealth oldHealth:oldHealth];
	[_healthBar setHealthValue:newHealth];
    if (newHealth < oldHealth) {
        //red flash for damage
        [[[_ui topBar] material] flash:COLOUR_SOLID_RED 
                               flashOn:PLAYER_HURT_FLASH_ON
                              flashOff:PLAYER_HURT_FLASH_OFF
                              offAfter:PLAYER_HURT_FLASH_DURATION];
    }
}

-(void)playerDidDie{
    [super playerDidDie];
	[_healthBar setHealthValue:0];
	//then die, game over etc
	
	//stop game logic
	[self pause:YES];
	
	//show the game over screen
	_gameIsOver = YES;
	_gameOverTime = [SFUtils getAppTime];
	[_ui addSubWidget:_gameOver];
	[_fknRun hide];
	[_weaponHud hide];    
}

@end
