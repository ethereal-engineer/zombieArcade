//
//  SFSettingManager.m
//  ZombieArcade
//
//  Created by Adam Iredale on 21/01/10.
//  Copyright 2010 Stormforge Software. All rights reserved.
//

#import "SFSettingManager.h"
#import "SFUtils.h"

#define SF_SETTINGS_FILE @"SFSettings.plist"

@implementation SFSettingManager

+(void)registerDefaults{
	[[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithContentsOfFile:[SFUtils getFilePathFromBundle:SF_SETTINGS_FILE]]];
}

+(void)saveObject:(NSString*)settingName settingValue:(id)settingValue{
	[[NSUserDefaults standardUserDefaults] setObject:settingValue forKey:settingName];
	[self syncSettings];
}

+(void)saveFloat:(NSString*)settingName settingValue:(float)settingValue{
	[[NSUserDefaults standardUserDefaults] setFloat:settingValue forKey:settingName];
	[self syncSettings];
}

+(void)saveInt:(NSString*)settingName settingValue:(int)settingValue{
	[[NSUserDefaults standardUserDefaults] setInteger:settingValue forKey:settingName];
	[self syncSettings];
}

+(void)saveBool:(NSString*)settingName settingValue:(BOOL)settingValue{
	[[NSUserDefaults standardUserDefaults] setBool:settingValue forKey:settingName];
	[self syncSettings];
}

+(BOOL)loadBool:(NSString*)settingName{
	return [[NSUserDefaults standardUserDefaults] boolForKey:settingName];
}

+(float)loadFloat:(NSString*)settingName{
	return [[NSUserDefaults standardUserDefaults] floatForKey:settingName];
}

+(int)loadInt:(NSString*)settingName{
	return [[NSUserDefaults standardUserDefaults] integerForKey:settingName];
}

+(id)loadObject:(NSString*)settingName{
	return [[NSUserDefaults standardUserDefaults] objectForKey:settingName];
}

+(void)syncSettings{
	[[NSUserDefaults standardUserDefaults] synchronize];
}

+(void)print{
    printf("%s", [[[[NSUserDefaults standardUserDefaults] dictionaryRepresentation] description] UTF8String]);
}

@end
