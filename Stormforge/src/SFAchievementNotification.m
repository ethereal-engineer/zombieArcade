//
//  SFAchievementNotification.m
//  ZombieArcade
//
//  Created by Adam Iredale on 3/05/10.
//  Copyright 2010 Stormforge Software. All rights reserved.
//

#import "SFAchievementNotification.h"

#define TITLE_ACHIEVEMENT @"UNLOCKED!"
#define TITLE_HIGHSCORE @"HIGH SCORE!"

@implementation SFAchievementNotification

-(id)initNotification{
    self = [super initWidget:@"achievements"
                   atlasItem:@"dialog"
                    position:Vec2Make(240, 165)
                    centered:YES
               visibleOnShow:YES
                enableOnShow:YES];
    if (self != nil) {
        //setup our label (description) as blank for now
        _text = [[SFWidgetLabel alloc] initLabel:@"appleCasual16"
                                                  initialCaption:@"<blank>"
                                                        position:Vec2Make(15, 155)
                                                        centered:NO
                                                   visibleOnShow:YES
                                               updateViaCallback:NO];
        [self addSubWidget:_text];
        [_text release];
        //setup our header (title) as blank for now too
        _title = [[SFWidgetLabel alloc] initLabel:@"chalkDust32"
                                  initialCaption:@"<blank>"
                                        position:Vec2Make(15, 200)
                                        centered:NO
                                   visibleOnShow:YES
                               updateViaCallback:NO];
        [self addSubWidget:_title];
        [_title release];

    }
    return self;
}

-(void)setHighScore{
    [_title setCaption:TITLE_HIGHSCORE];
    [_text setCaption:[[self gi] getGameText:@"highScoreMessage"]];
    [_icon hide];
}

-(void)setAchievement:(NSString*)resourceId{
    //for the content, we need to know the achievementId
    //to look up the achievement info for picture and text
    NSDictionary *achievementInfo  = [[[self gi] getAchievementInfo:resourceId] retain];
    CGPoint       atlasOffset      = CGPointFromString([achievementInfo objectForKey:@"atlasOffset"]);
    //set our text
    NSString *kind = [achievementInfo objectForKey:@"kind"];
    NSString *description = [[kind uppercaseString] stringByAppendingFormat:@": "];
    description = [description stringByAppendingString:[[achievementInfo objectForKey:@"name"] stringByAppendingFormat:@"\n\n"]];
    description = [description stringByAppendingString:[achievementInfo objectForKey:@"description"]];
    [_text setCaption:description];
    //create and setup our icon
    if (_icon) {
        [self removeSubWidget:_icon];
    }
    _icon = [[SFWidget alloc] initWidget:@"achievements"
                               atlasItem:kind
                                position:Vec2Make(222, 220)
                                centered:YES
                           visibleOnShow:YES
                            enableOnShow:NO];
    [_icon setImageOffset:atlasOffset];
    [self addSubWidget:_icon];
    
    [_title setCaption:TITLE_ACHIEVEMENT];
    [_icon show];
    
    [_icon release];
    [achievementInfo release];
}

@end
