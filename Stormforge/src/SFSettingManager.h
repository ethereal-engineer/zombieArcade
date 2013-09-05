//
//  SFSettingManager.h
//  ZombieArcade
//
//  Created by Adam Iredale on 21/01/10.
//  Copyright 2010 Stormforge Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SFObject.h"

@interface SFSettingManager : SFObject {
	//deals with all settings
}

//save/load setting class routines
+(void)registerDefaults;
+(void)saveObject:(NSString*)settingName settingValue:(id)settingValue;
+(void)saveFloat:(NSString*)settingName settingValue:(float)settingValue;
+(void)saveInt:(NSString*)settingName settingValue:(int)settingValue;
+(void)saveBool:(NSString*)settingName settingValue:(BOOL)settingValue;
+(BOOL)loadBool:(NSString*)settingName;
+(float)loadFloat:(NSString*)settingName;
+(int)loadInt:(NSString*)settingName;
+(id)loadObject:(NSString*)settingName;
+(void)syncSettings;
+(void)print;
@end
