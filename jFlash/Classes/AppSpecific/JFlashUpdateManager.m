//
//  JFlashUpdateManager.m
//  xFlash
//
//  Created by Mark Makdad on 6/7/12.
//  Copyright (c) 2012 Long Weekend LLC. All rights reserved.
//

#import "JFlashUpdateManager.h"

@interface JFlashUpdateManager ()
// JFLASH 1.1 -> 1.2
+ (void) _createDefaultSettingsFor11:(NSUserDefaults *)settings;
+ (void) _updateSettingsFrom11to12:(NSUserDefaults *)settings;
+ (BOOL) _needs11to12SettingsUpdate:(NSUserDefaults *)settings;

// JFLASH 1.2 -> 1.3
+ (void) _updateSettingsFrom12to13:(NSUserDefaults *)settings;
+ (BOOL) _needs12to13SettingsUpdate:(NSUserDefaults *)settings;
+ (BOOL) _updatePlistFrom12to13;

// JFLASH 1.4 -> 1.5
+ (BOOL) _needs14to15SettingsUpdate:(NSUserDefaults *)settings;
+ (void) _updateSettingsFrom14to15:(NSUserDefaults *)settings;

// JFLASH 1.5 -> 1.6
+ (BOOL) _needs15to16SettingsUpdate:(NSUserDefaults *) settings;
+ (void) _updateSettingsFrom15to16:(NSUserDefaults *)settings;

// JFLASH 1.6 -> 1.6.1
+ (BOOL) _needs16to161SettingsUpdate:(NSUserDefaults *) settings;
+ (void) _updateSettingsFrom16to161:(NSUserDefaults *)settings;

// JFLASH 1.6.1 -> 1.6.2
+ (BOOL) _needs161to162SettingsUpdate:(NSUserDefaults *) settings;
+ (void) _updateSettingsFrom161to162:(NSUserDefaults *)settings;

// JFLASH 1.6.2 -> 1.7
+ (BOOL) _needs162to17SettingsUpdate:(NSUserDefaults *) settings;
+ (void) _updateSettingsFrom162to17:(NSUserDefaults *)settings;

// JFLASH 1.7 -> 1.8
+ (BOOL) _needs17to18SettingsUpdate:(NSUserDefaults *) settings;
+ (void) _updateSettingsFrom17to18:(NSUserDefaults *)settings;

@end


@implementation JFlashUpdateManager

#pragma mark - JFLASH 
#pragma mark Version 1.1

/** DEBUG ONLY method to simulate settings for JFlash 1.1 **/
+ (void) _createDefaultSettingsFor11:(NSUserDefaults*) settings
{
	LWE_LOG(@"Program runs, and creating the default settings");
	NSArray *keys = [[NSArray alloc] initWithObjects:APP_THEME,APP_HEADWORD,APP_READING,APP_MODE,APP_PLUGIN,APP_DATA_VERSION,nil];
  // Write this manually w/o any constants as this is how it was in v1.1
  NSDictionary *preinstalledPlugins = [NSDictionary dictionaryWithObjectsAndKeys:@"jFlash-CARD-1.1.db",CARD_DB_KEY,nil];
	NSArray *objects = [[NSArray alloc] initWithObjects:DEFAULT_THEME,SET_J_TO_E,SET_READING_BOTH,SET_MODE_QUIZ,preinstalledPlugins,LWE_JF_VERSION_1_1,nil];
	for (int i = 0; i < [keys count]; i++)
	{
		[settings setValue:[objects objectAtIndex:i] forKey:[keys objectAtIndex:i]];
	}  
	[keys release];
	[objects release];
	
	[settings setInteger:DEFAULT_TAG_ID forKey:@"tag_id"];
	[settings setInteger:DEFAULT_USER_ID forKey:APP_USER];
	[settings setInteger:DEFAULT_FREQUENCY_MULTIPLIER forKey:APP_FREQUENCY_MULTIPLIER];
	[settings setInteger:DEFAULT_MAX_STUDYING forKey:APP_MAX_STUDYING];
	[settings setInteger:DEFAULT_DIFFICULTY forKey:APP_DIFFICULTY];
	
	[settings setBool:NO forKey:@"db_did_finish_copying"];
	[settings setBool:YES forKey:@"settings_already_created"];
}

#pragma mark Version 1.2

/** Updates NSUserDefaults to add 1.2 values*/
+ (void) _updateSettingsFrom11to12:(NSUserDefaults*) settings
{
	LWE_LOG(@"Update from 1.1 to 1.2 Yatta!");
	[settings setObject:[NSDate dateWithTimeIntervalSince1970:0] forKey:PLUGIN_LAST_UPDATE];                    
	
  // Now change the app version and the data version
	[settings setValue:LWE_JF_VERSION_1_2 forKey:APP_SETTINGS_VERSION];
  [settings setValue:LWE_JF_VERSION_1_2 forKey:APP_DATA_VERSION];
}


/** Returns YES if the user needs to update settings from 1.1 to 1.2, otherwise returns NO */
+ (BOOL) _needs11to12SettingsUpdate:(NSUserDefaults*) settings
{
	// First things first, do a check to make sure this is not a first run after an upgrade
	if (![settings objectForKey:PLUGIN_LAST_UPDATE] && [settings valueForKey:@"settings_already_created"])
	{
		return YES;
	}
	return NO;
}


#pragma mark Version 1.3

/**
 * Adds the plugin_html_content key to each downloadable plugin
 * \return YES if successful, NO if not
 */
+ (BOOL) _updatePlistFrom12to13
{
  BOOL returnVal = NO;
  
  // Add stuff to the PLIST for the plugin manager
  NSString *docPath = [LWEFile createDocumentPathWithFilename:LWE_AVAILABLE_PLUGIN_PLIST];
  NSMutableDictionary *pluginSettingsPlist = [NSMutableDictionary dictionaryWithContentsOfFile:docPath];
  if (pluginSettingsPlist)
  {
    // Set up the new dictionary
    NSMutableDictionary *newDict = [[NSMutableDictionary alloc] init];
    
    // EXAMPLES
    if ([pluginSettingsPlist valueForKey:EXAMPLE_DB_KEY])
    {
      NSMutableDictionary *newExamplePlugin = [NSMutableDictionary dictionaryWithDictionary:[pluginSettingsPlist valueForKey:EXAMPLE_DB_KEY]];
      NSString *exampleString = [NSString stringWithContentsOfFile:[LWEFile createBundlePathWithFilename:@"plugin-resources/example-sentences.html"] encoding:NSUTF8StringEncoding error:NULL];
      [newExamplePlugin setObject:exampleString forKey:@"plugin_html_content"];
      [newDict setObject:newExamplePlugin forKey:EXAMPLE_DB_KEY];
    }
    
    // FTS
    if ([pluginSettingsPlist valueForKey:FTS_DB_KEY])
    {
      NSMutableDictionary *newSearchPlugin = [NSMutableDictionary dictionaryWithDictionary:[pluginSettingsPlist valueForKey:FTS_DB_KEY]];
      NSString *searchString = [NSString stringWithContentsOfFile:[LWEFile createBundlePathWithFilename:@"plugin-resources/full-text-search.html"] encoding:NSUTF8StringEncoding error:NULL];
      [newSearchPlugin setObject:searchString forKey:@"plugin_html_content"];
      [newDict setObject:newSearchPlugin forKey:FTS_DB_KEY];
    }
    
    // Now write it out
    if ([newDict writeToFile:docPath atomically:YES])
    {
      returnVal = YES;
    }
    [newDict release];
  }
  else
  {
    LWE_LOG(@"Unable to load PLIST!");
  }
  return returnVal;
}

/** Updates NSUserDefaults to add 1.2 values*/
+ (void) _updateSettingsFrom12to13:(NSUserDefaults *) settings
{
	LWE_LOG(@"Update from 1.2 to 1.3 - we need to make a tag for favorites!");
  
  // Now do the PLIST as well
  [JFlashUpdateManager _updatePlistFrom12to13];
  
  [JFlashUpdateManager _upgradeDBtoVersion:LWE_JF_VERSION_1_3 withSQLStatements:LWE_JF_12_TO_13_SQL_FILENAME forSettings:settings];
}


/** Returns YES if the user needs to update settings from 1.2 to 1.3, otherwise returns NO */
+ (BOOL) _needs12to13SettingsUpdate:(NSUserDefaults*) settings
{
  // We do not want to update the settings if we are STILL waiting on a 1.0 upgrade
  return ([[settings objectForKey:APP_DATA_VERSION] isEqualToString:LWE_JF_VERSION_1_2] &&
          [settings valueForKey:@"settings_already_created"]);
}


#pragma mark Version 1.4

/** Returns YES if the user needs to update settings from 1.3 to 1.4, otherwise returns NO */
+ (BOOL) _needs13to14SettingsUpdate:(NSUserDefaults*) settings
{
  // We do not want to update the settings if we are STILL waiting on a 1.0 upgrade
  return ([[settings objectForKey:APP_DATA_VERSION] isEqualToString:LWE_JF_VERSION_1_3] && 
          [settings valueForKey:@"settings_already_created"]);
}

#pragma mark Version 1.5

+ (BOOL) _needs14to15SettingsUpdate:(NSUserDefaults*) settings
{
  // We do not want to update the settings if we are STILL waiting on a 1.0 upgrade
  return ([[settings objectForKey:APP_DATA_VERSION] isEqualToString:LWE_JF_VERSION_1_4] && 
          [settings valueForKey:@"settings_already_created"]);
}

+ (void) _updateSettingsFrom14to15:(NSUserDefaults *)settings
{
  //New key for the user settings preference in version 1.5
  [settings setBool:NO forKey:APP_HIDE_BURIED_CARDS];
  [settings setObject:LWE_JF_VERSION_1_5 forKey:APP_DATA_VERSION];
  [settings setObject:LWE_JF_VERSION_1_5 forKey:APP_SETTINGS_VERSION];
}

#pragma mark Version 1.6

+ (BOOL) _needs15to16SettingsUpdate:(NSUserDefaults*) settings
{
  // We do not want to update the settings if we are STILL waiting on a 1.0 upgrade
  return ([[settings objectForKey:APP_DATA_VERSION] isEqualToString:LWE_JF_VERSION_1_5] && 
          [settings valueForKey:@"settings_already_created"]);
}

+ (void) _updateSettingsFrom15to16:(NSUserDefaults *)settings
{
  // We don't use this anymore -- iOS4.0+ state control does most of the heavy lifting for us now.
  [settings removeObjectForKey:@"card_id"];
  [settings setInteger:DEFAULT_REMINDER_DAYS forKey:APP_REMINDER];
  
  //New key for the user settings preference in version 1.6
  [settings setObject:LWE_JF_VERSION_1_6 forKey:APP_SETTINGS_VERSION];
  
  // 1. Execute SQL update file for bad data fixes
  [UpdateManager _upgradeDBtoVersion:LWE_JF_VERSION_1_6 withSQLStatements:LWE_JF_15_TO_16_SQL_FILENAME forSettings:settings];
  [TagPeer recacheCountsForUserTags];
  
  // 2. Update settings inre: plugins -- read from the PLIST file, store everything back to the NSUserDefaults
  NSMutableDictionary *pluginsDict = [[[settings objectForKey:APP_PLUGIN] mutableCopy] autorelease];
  NSString *installedPluginPlistPath = [LWEFile createDocumentPathWithFilename:LWE_DOWNLOADED_PLUGIN_PLIST];
  NSDictionary *installedPluginHash = [NSDictionary dictionaryWithContentsOfFile:installedPluginPlistPath];
  if (installedPluginHash)
  {
    for (NSString *key in installedPluginHash)
    {
      NSDictionary *oldPluginHash = [installedPluginHash objectForKey:key];
      Plugin *newPlugin = [Plugin pluginWithLegacyDictionary:oldPluginHash];
      [pluginsDict setObject:[NSKeyedArchiver archivedDataWithRootObject:newPlugin] forKey:newPlugin.pluginId];
    }
  }
  [settings setValue:pluginsDict forKey:APP_PLUGIN];
  
  // Delete old plugin file now
  [LWEFile deleteFile:[LWEFile createDocumentPathWithFilename:LWE_DOWNLOADED_PLUGIN_PLIST]];
}

#pragma mark Version 1.6.1

+ (BOOL) _needs16to161SettingsUpdate:(NSUserDefaults*) settings
{
  // We do not want to update the settings if we are STILL waiting on a 1.0 upgrade
  return ([[settings objectForKey:APP_DATA_VERSION] isEqualToString:LWE_JF_VERSION_1_6] && 
          [settings valueForKey:@"settings_already_created"]);
}

+ (void) _updateSettingsFrom16to161:(NSUserDefaults *)settings
{
  //New key for the user settings preference in version 1.6
  [settings setObject:LWE_JF_VERSION_1_6_1 forKey:APP_SETTINGS_VERSION];
  
  // 1. Execute SQL update file for bad data fixes
  [UpdateManager _upgradeDBtoVersion:LWE_JF_VERSION_1_6_1 withSQLStatements:LWE_JF_16_TO_161_SQL_FILENAME forSettings:settings];
  [TagPeer recacheCountsForUserTags];
}

#pragma mark Version 1.6.2

+ (BOOL) _needs161to162SettingsUpdate:(NSUserDefaults *) settings
{
  return [[settings objectForKey:APP_DATA_VERSION] isEqualToString:LWE_JF_VERSION_1_6_1];
}

+ (void) _updateSettingsFrom161to162:(NSUserDefaults *)settings
{
  //New key for the user settings preference in version 1.6.2
  [settings setObject:LWE_JF_VERSION_1_6_2 forKey:APP_SETTINGS_VERSION];
  
  // 1. Execute SQL update file for bad data fixes
  [UpdateManager _upgradeDBtoVersion:LWE_JF_VERSION_1_6_2 withSQLStatements:LWE_JF_161_TO_162_SQL_FILENAME forSettings:settings];
  [TagPeer recacheCountsForUserTags];
}

#pragma mark Version 1.7

+ (BOOL) _needs162to17SettingsUpdate:(NSUserDefaults *) settings
{
  return [[settings objectForKey:APP_DATA_VERSION] isEqualToString:LWE_JF_VERSION_1_6_2];
}

+ (void) _updateSettingsFrom162to17:(NSUserDefaults *)settings
{
  //New key for the user settings preference in version 1.6.2
  [settings setObject:LWE_JF_VERSION_1_7 forKey:APP_SETTINGS_VERSION];
  
  // 1. Execute SQL update file for bad data fixes
  [UpdateManager _upgradeDBtoVersion:LWE_JF_VERSION_1_7 withSQLStatements:LWE_JF_162_TO_17_SQL_FILENAME forSettings:settings];
  [TagPeer recacheCountsForUserTags];
}

#pragma mark Version 1.8

+ (BOOL) _needs17to18SettingsUpdate:(NSUserDefaults *) settings
{
  return [[settings objectForKey:APP_DATA_VERSION] isEqualToString:LWE_JF_VERSION_1_7];
}

+ (void) _updateSettingsFrom17to18:(NSUserDefaults *)settings
{
  // Create a default setting that wasn't there before
  [settings setObject:SET_TEXT_NORMAL forKey:APP_TEXT_SIZE];
  
  [settings setObject:LWE_JF_VERSION_1_8 forKey:APP_DATA_VERSION];
  [settings setObject:LWE_JF_VERSION_1_8 forKey:APP_SETTINGS_VERSION];
}

#pragma mark - 

+ (BOOL) performMigrations:(NSUserDefaults*)settings
{
  BOOL migrated = NO;
  /**
   * JFLASH MIGRATIONS
   */
  // NOTE THAT THESE ARE MIGRATIONS!!!!  They should be in order of version.
	
  //In the jFlash 1.2, jFlash included some new features, and it requires the plugin manager to be updated.
  //The plugin manager will have to look at the last time it gets updated, there is the list of the data
  if ([JFlashUpdateManager _needs11to12SettingsUpdate:settings])
  {
		LWE_LOG(@"[Migration Log]Oops, we need update to 1.2 version");
	  [JFlashUpdateManager _updateSettingsFrom11to12:settings];
    migrated = YES;
  }
  
  // JFlash 1.3 - does small database migration for favorites!
  if ([JFlashUpdateManager _needs12to13SettingsUpdate:settings])
  {
		LWE_LOG(@"[Migration Log]Oops, we need update to 1.3 version");
	  [JFlashUpdateManager _updateSettingsFrom12to13:settings];
    migrated = YES;
  }
  
  if ([JFlashUpdateManager _needs13to14SettingsUpdate:settings])
  {
    LWE_LOG(@"[Migration Log]Updating to 1.4 version");
    [JFlashUpdateManager _upgradeDBtoVersion:LWE_JF_VERSION_1_4 withSQLStatements:LWE_JF_13_TO_14_SQL_FILENAME forSettings:settings];
    [TagPeer recacheCountsForUserTags];
    migrated = YES;
  }
  
  if ([JFlashUpdateManager _needs14to15SettingsUpdate:settings])
  {
    LWE_LOG(@"[Migration Log]YAY! Updating to 1.5 version");
    [JFlashUpdateManager _updateSettingsFrom14to15:settings];
    migrated = YES;
  }
  
  if ([JFlashUpdateManager _needs15to16SettingsUpdate:settings])
  {
    LWE_LOG(@"[Migration Log]YAY! Updating to 1.6 version");
    [JFlashUpdateManager _updateSettingsFrom15to16:settings];
    migrated = YES;
  }
  
  if ([JFlashUpdateManager _needs16to161SettingsUpdate:settings])
  {
    LWE_LOG(@"[Migration Log]YAY! Updating to 1.6.1 version");
    [JFlashUpdateManager _updateSettingsFrom16to161:settings];
    migrated = YES;
  }
  
  if ([JFlashUpdateManager _needs161to162SettingsUpdate:settings])
  {
    LWE_LOG(@"[Migration Log]YAY! Updating to 1.6.2 version");
    [JFlashUpdateManager _updateSettingsFrom161to162:settings];
    migrated = YES;
  }
  
  if ([JFlashUpdateManager _needs162to17SettingsUpdate:settings])
  {
    LWE_LOG(@"[Migration Log]YAY! Updating to 1.7 version");
    [JFlashUpdateManager _updateSettingsFrom162to17:settings];
    migrated = YES;
  }
  
  if ([JFlashUpdateManager _needs17to18SettingsUpdate:settings])
  {
    LWE_LOG(@"[Migration Log]YAY! Updating to 1.8 version");
    [JFlashUpdateManager _updateSettingsFrom17to18:settings];
    migrated = YES;
  }
  return migrated;
}

+ (void) showUpgradeAlertView:(NSUserDefaults *)settings delegate:(id<UIAlertViewDelegate>)alertDelegate
{
  NSString *version = [settings objectForKey:APP_SETTINGS_VERSION];
  if ([version isEqualToString:LWE_JF_VERSION_1_6])
  {
    // Show shout-out UI Alert view
    [LWEUIAlertView confirmationAlertWithTitle:NSLocalizedString(@"Updated to JFlash 1.6",@"JFlash1.6 upgrade alert title")
                                       message:NSLocalizedString(@"Thanks for updating!  Special thanks to Ben, Murray, Riley & David for helping us improve a few entries.  Also, do you have Rikai Browser yet?  It tightly integrates with JFlash and helps you read Japanese webpages and learn new words.  Want it?",@"JFlash1.6 upgrade alert msg")
                                            ok:NSLocalizedString(@"Later", @"StudyViewController.Later")
                                        cancel:NSLocalizedString(@"Get Rikai", @"WebViewController.RikaiAppStore")
                                      delegate:alertDelegate];
    
  }
  else if ([version isEqualToString:LWE_JF_VERSION_1_6_1])
  {
    [LWEUIAlertView confirmationAlertWithTitle:NSLocalizedString(@"Updated to JFlash 1.6.1",@"JFlash1.6.1 upgrade alert title")
                                       message:NSLocalizedString(@"Thanks for updating!  We fixed a minor bug in the example sentences display.  Special thanks to Michael & Murray for helping us improve a few entries.  Also, do you have Rikai Browser yet?  It tightly integrates with JFlash and helps you read Japanese webpages and learn new words.",@"JFlash1.6.1 upgrade alert msg")
                                            ok:NSLocalizedString(@"Later", @"StudyViewController.Later")
                                        cancel:NSLocalizedString(@"Get Rikai", @"WebViewController.RikaiAppStore")
                                      delegate:alertDelegate];
  }
  else if ([version isEqualToString:LWE_JF_VERSION_1_6_2])
  {
    [LWEUIAlertView confirmationAlertWithTitle:NSLocalizedString(@"Updated to JFlash 1.6.2",@"JFlash1.6.2 upgrade alert title")
                                       message:NSLocalizedString(@"Another update!  We fixed a bug in the integration between Rikai Browser & Japanese Flash.  Did you know you can send words from Rikai Browser to Japanese Flash with one button?  Get it if you don't have it!  Also, thanks to Michael, who helped us update a few more entries.",@"JFlash1.6.2 upgrade alert msg")
                                            ok:NSLocalizedString(@"No Thanks", @"StudyViewController.Later")
                                        cancel:NSLocalizedString(@"Get Rikai", @"WebViewController.RikaiAppStore")
                                      delegate:alertDelegate];
  }
  else if ([version isEqualToString:LWE_JF_VERSION_1_7])
  {
    [LWEUIAlertView notificationAlertWithTitle:NSLocalizedString(@"Updated to JFlash 1.7",@"JFlash1.7 upgrade alert title")
                                       message:NSLocalizedString(@"Thanks for updating!  Cool new feature: you can browse example sentences for a card within the Search feature.  Also, thanks to Kobe and Murray, who helped us update about 8 dictionary entries.",@"JFlash1.7 upgrade alert msg")];
  }
}



@end
