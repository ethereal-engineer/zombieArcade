//
//  SFWeaponHud.m
//  ZombieArcade
//
//  Created by Adam Iredale on 22/02/10.
//  Copyright 2010 Stormforge Software. All rights reserved.
//

#import "SFWeaponHud.h"
#import "SFGameEngine.h"
#import "SFConst.h"
#import "SFWeapon.h"

@implementation SFWeaponHud

-(void)updateFromPlayerWeapons{
    [self removeAllSubWidgets];
    NSDictionary *weapons = [[SFGameEngine getLocalPlayer] weapons];
    //we do it this way so the weapons are arranged in their slots properly
    for (int i = 0; i < _maxWeaponCount; ++i) {
        SFWeapon *weapon = [weapons objectForKey:[NSNumber numberWithInt:i]];
        if (!weapon) {
            continue;
        }
        SFWidget *newWidget = [[SFWidget alloc] initWidget:@"weaponTray"
                                                 atlasItem:@"icon"
                                                  position:Vec2Zero
                                                  centered:YES
                                             visibleOnShow:YES
                                              enableOnShow:YES];
        [newWidget setObjectInfo:weapon forKey:@"weapon"];
        [newWidget setImageOffset:[weapon hudIconOffset]];
        [self addSubWidget:newWidget];
        [newWidget release];
    }
    [self arrangeSubWidgets];
    [self weaponDidFire:[[SFGameEngine getLocalPlayer] currentWeapon]];
}

-(id)initWeaponHud:(NSString*)atlasName{
    self = [self initSlideTray:atlasName];
    if (self != nil){
        //set the max number of possible weapons
        _maxWeaponCount = [[[self gi] getWeaponsDictionary] count];
        [self updateFromPlayerWeapons];
    }
    return self;
}

//////////////////
//SFWidgetDelegate
//////////////////

-(void)widgetWasTouched:(id)widget touchKind:(unsigned char)touchKind dragRect:(CGRect)dragRect{
    [super widgetWasTouched:widget touchKind:touchKind dragRect:dragRect];
    if (widget == self) {
        switch (touchKind) {
            case CR_WIDGET_PRESSED:
                [[[SFGameEngine getLocalPlayer] currentWeapon] reload];
                break;
        }
    } else if (widget == _tray) {
        //nothing to do, really
    } else {
        //the only other things are the tray items
        //kinda dodgy... (relying on exclusion)
        switch (touchKind) {
            case CR_TOUCH_TAP_UP:
            case CR_WIDGET_PRESSED:
                [[SFGameEngine getLocalPlayer] equipWeapon:[widget objectInfoForKey:@"weapon"]];
                [self close];
                break;
            case CR_TOUCH_DRAG:
                [self setOverlayOffset:[[widget objectInfoForKey:@"weapon"] statusIconOffset]];
                break;
        }
    }
}

//////////////////
//SFWeaponDelegate
//////////////////

-(void)weaponDidFire:(id)weapon{
    [self setOverlayOffset:[weapon statusIconOffset]];
}

-(void)weaponDidDryFire:(id)weapon{
    [[self material] setDefaultDiffuse:COLOUR_SOLID_RED];
}

-(void)weaponDidStartReloading:(id)weapon reloadTime:(float)reloadTime{
    //reset the diffuse colour to WHITE
    [[self material] setDefaultDiffuse:COLOUR_SOLID_WHITE];
    //set the diffuse colour to an amber that fades to 
    //white after the time period that we get in userinfo
    [[self material] fadeColour:COLOUR_SOLID_AMBER fadeTime:reloadTime];
}
-(void)weaponDidFinishReloading:(id)weapon{
    [[self material] fadeColour:COLOUR_SOLID_GREEN fadeTime:0.5f];
    [self weaponDidFire:weapon];
}

//////////////////
//SFPlayerDelegate
//////////////////

-(void)playerHealthWillChange:(float)oldHealth newHealth:(float)newHealth{
    
}

-(void)playerHealthDidChange:(float)newHealth oldHealth:(float)oldHealth{
    
}

-(void)playerWillDie{
    
}

-(void)playerDidDie{
    
}

-(void)playerWillChangeWeapons:(id)player currentWeapon:(id)currentWeapon newWeapon:(id)newWeapon{}

-(void)playerDidChangeWeapons:(id)player currentWeapon:(id)currentWeapon oldWeapon:(id)oldWeapon{
    [[self material] setDefaultDiffuse:COLOUR_SOLID_WHITE];
    [self weaponDidFire:currentWeapon];
}

-(void)playerGotWeapon:(id)player weapon:(id)weapon{
    //add this weapon to the hud if not already there
    [self updateFromPlayerWeapons];
}

-(void)playerUnlockedAchievement:(NSString *)resourceId achievementInfo:(NSDictionary *)achievementInfo{
    
}

@end
