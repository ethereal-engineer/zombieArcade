//
//  SFCreditsMenu.m
//  ZombieArcade
//
//  Created by Adam Iredale on 26/02/10.
//  Copyright 2010 Stormforge Software. All rights reserved.
//

#import "SFCreditsMenu.h"
#import "SFGameEngine.h"
#import "SFScene.h"
#import "SFDebug.h"

#define SINGLE_CREDIT_TIME 5.0f

@implementation SFCreditsMenu

-(NSString*)getNextCredit{
    //get the credits from the GI
    _creditIndex = (_creditIndex + 1) % _creditCount;
    return [[self gi] getCreditString:_creditIndex];
    
}

-(void)startRollingCredits{
    //every few renders, the label changes caption
    _creditIndex = -1;
    _creditCount = [[self gi] getCreditCount];
    [[[[self sm] currentScene] camera] setIpoName:@"creditTour"];
}

-(id)initMenu:(NSString *)atlasName{
    self = [super initMenu:atlasName];
    if (self != nil) {
        _subWidgetArrangeStyle = wasNone;
        _credit = [[SFWidgetLabel alloc] initLabel:@"bloodScrawl32"
                                    initialCaption:@"-"
                                          position:Vec2Make(252.0f, 158.0f) 
                                          centered:YES
                                     visibleOnShow:YES
                                 updateViaCallback:YES];
        [_credit setJustification:ljCenter];
        [self addSubWidget:_credit];
    }
    return self;
}

-(void)cleanUp{
    [_credit release];
    [super cleanUp];
}

//////////////////
//SFWidgetDelegate
//////////////////

-(void)widgetCallback:(id)widget reason:(unsigned char)reason{
    [super widgetCallback:widget reason:reason];
    switch (reason) {
        case CR_UPDATE_LABEL:
            if (widget == _credit) {
                if (_creditRendersRemaining <= 0) {
                    [_credit setCaption:[self getNextCredit]];
                    _creditRendersRemaining = [[self scene] timeToRenderPasses:SINGLE_CREDIT_TIME];
                } else {
                    --_creditRendersRemaining;
                }
            }
            break;
        default:
            break;
    }
}

@end
