//
//  CFlashUpdateManager.m
//  xFlash
//
//  Created by Mark Makdad on 6/7/12.
//  Copyright (c) 2012 Long Weekend LLC. All rights reserved.
//

#import "CFlashUpdateManager.h"

@interface CFlashUpdateManager ()
// CFLASH 1.0.x -> 1.1
+ (BOOL) _needs10to11SettingsUpdate:(NSUserDefaults *)settings;
+ (void) _updateSettingsFrom10to11:(NSUserDefaults *)settings;

// CFLASH 1.1 -> 1.1.1
+ (BOOL) _needs11to111SettingsUpdate:(NSUserDefaults *)settings;
+ (void) _updateSettingsFrom11to111:(NSUserDefaults *)settings;

// CFLASH 1.1.1 -> 1.2
+ (BOOL) _needs111to12SettingsUpdate:(NSUserDefaults *)settings;
+ (void) _updateSettingsFrom111to12:(NSUserDefaults *)settings;
@end

@implementation CFlashUpdateManager

#pragma mark - CFLASH

#pragma mark Version 1.1

+ (BOOL) _needs10to11SettingsUpdate:(NSUserDefaults *)settings
{
  return [[settings objectForKey:APP_SETTINGS_VERSION] isEqualToString:LWE_CF_VERSION_1_0];
}

+ (void) _updateSettingsFrom10to11:(NSUserDefaults *)settings
{
  // Install a default setting for the pinyin tone change setting (new in 1.1)
  [settings setObject:SET_PINYIN_CHANGE_TONE_OFF forKey:APP_PINYIN_CHANGE_TONE];
  
  // Now update the version
  [settings setObject:LWE_CF_VERSION_1_1 forKey:APP_SETTINGS_VERSION];
}

#pragma mark Version 1.1.1

+ (BOOL) _needs11to111SettingsUpdate:(NSUserDefaults *)settings
{
  return [[settings objectForKey:APP_SETTINGS_VERSION] isEqualToString:LWE_CF_VERSION_1_1];
}

+ (void) _updateSettingsFrom11to111:(NSUserDefaults *)settings
{
  //New key for the user settings preference in version 1.6.2
  [settings setObject:LWE_CF_VERSION_1_1_1 forKey:APP_SETTINGS_VERSION];
  
  // 1. Execute SQL update file for bad data fixes
  [UpdateManager _upgradeDBtoVersion:LWE_CF_VERSION_1_1_1 withSQLStatements:LWE_CF_11_TO_12_SQL_FILENAME forSettings:settings];
  [TagPeer recacheCountsForUserTags];
}

#pragma mark Version 1.2

+ (BOOL) _needs111to12SettingsUpdate:(NSUserDefaults *)settings
{
  return [[settings objectForKey:APP_SETTINGS_VERSION] isEqualToString:LWE_CF_VERSION_1_1_1];
}

+ (void) _updateSettingsFrom111to12:(NSUserDefaults *)settings
{
  // Set the new key for text size
  [settings setObject:SET_TEXT_NORMAL forKey:APP_TEXT_SIZE];
  
  [settings setObject:LWE_CF_VERSION_1_2 forKey:APP_SETTINGS_VERSION];
  [settings setObject:LWE_CF_VERSION_1_2 forKey:APP_DATA_VERSION];
}

#pragma mark - 

+ (BOOL) performMigrations:(NSUserDefaults *)settings
{
  BOOL migrated = NO;
  if ([CFlashUpdateManager _needs10to11SettingsUpdate:settings])
  {
    LWE_LOG(@"[Migration Log]YAY! Updating to 1.1 version");
    [CFlashUpdateManager _updateSettingsFrom10to11:settings];
    migrated = YES;
  }
  
  if ([CFlashUpdateManager _needs11to111SettingsUpdate:settings])
  {
    LWE_LOG(@"[Migration Log]YAY! Updating to 1.1.1 version");
    [CFlashUpdateManager _updateSettingsFrom11to111:settings];
    migrated = YES;
  }
  
  if ([CFlashUpdateManager _needs111to12SettingsUpdate:settings])
  {
    LWE_LOG(@"[Migration Log]YAY! Updating to 1.2 version");
    [CFlashUpdateManager _updateSettingsFrom111to12:settings];
    migrated = YES;
  }
  return migrated;
}


+ (void) showUpgradeAlertView:(NSUserDefaults *)settings delegate:(id<UIAlertViewDelegate>)alertDelegate
{
  NSString *version = [settings objectForKey:APP_SETTINGS_VERSION];
  if ([version isEqualToString:LWE_CF_VERSION_1_1])
  {
    [LWEUIAlertView notificationAlertWithTitle:NSLocalizedString(@"Updated to CFlash 1.1",@"CFlash1.1 upgrade alert title")
                                       message:NSLocalizedString(@"We added Pinyin tone sandhi!  Now, you can also show the pronounciation after taking tone changes into account.  You can turn this feature on in Settings (it's off by default).",@"CFlash1.1 upgrade alert msg")];    
  }
}
@end
