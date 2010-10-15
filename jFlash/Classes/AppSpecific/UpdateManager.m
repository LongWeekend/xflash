//
//  UpdateManager.m
//  jFlash
//
//  Created by Mark Makdad on 10/13/10.
//  Copyright 2010 Long Weekend Inc. All rights reserved.
//

#import "UpdateManager.h"

// Private methods
@interface UpdateManager ()

// JFLASH 1.0 -> 1.1
+ (void) _createDefaultSettingsFor10:(NSUserDefaults*) settings;
+ (void) _updateSettingsFrom10to11:(NSUserDefaults*) settings;
+ (BOOL) _needs10to11SettingsUpdate:(NSUserDefaults*) settings;

// JFLASH 1.1 -> 1.2
+ (void) _createDefaultSettingsFor11:(NSUserDefaults*) settings;
+ (void) _updateSettingsFrom11to12:(NSUserDefaults*) settings;
+ (BOOL) _needs11to12SettingsUpdate:(NSUserDefaults*) settings;

// JFLASH 1.2 -> 1.3
+ (void) _updateSettingsFrom12to13:(NSUserDefaults*) settings;
+ (BOOL) _needs12to13SettingsUpdate:(NSUserDefaults*) settings;
@end

@implementation UpdateManager

/** DEBUG ONLY method to simulate settings for JFlash 1.0 **/
+ (void) _createDefaultSettingsFor10:(NSUserDefaults*) settings
{
  [settings setInteger:0 forKey:@"first_load"];
  [settings setInteger:DEFAULT_TAG_ID forKey:@"tag_id"];
  [settings setInteger:DEFAULT_USER_ID forKey:APP_USER];
  [settings setValue:SET_J_TO_E forKey:APP_HEADWORD];
  [settings setValue:SET_THEME_FIRE forKey:APP_THEME];
  [settings setValue:SET_READING_BOTH forKey:APP_READING];
  [settings setBool:YES forKey:@"db_did_finish_copying"];
  [settings setValue:SET_MODE_QUIZ forKey:APP_MODE];
}

/** DEBUG ONLY method to simulate settings for JFlash 1.1 **/
+ (void) _createDefaultSettingsFor11:(NSUserDefaults*) settings
{
	LWE_LOG(@"Program runs, and creating the default settings");
	NSArray *keys = [[NSArray alloc] initWithObjects:APP_THEME,APP_HEADWORD,APP_READING,APP_MODE,APP_PLUGIN,APP_DATA_VERSION,nil];
	NSArray *objects = [[NSArray alloc] initWithObjects:DEFAULT_THEME,SET_J_TO_E,SET_READING_BOTH,SET_MODE_QUIZ,[PluginManager preinstalledPlugins],JFLASH_VERSION_1_1,nil];
	for (int i = 0; i < [keys count]; i++)
	{
		[settings setValue:[objects objectAtIndex:i] forKey:[keys objectAtIndex:i]];
	}  
	[keys release];
	[objects release];
	
	[settings setInteger:DEFAULT_TAG_ID forKey:@"tag_id"];
	[settings setInteger:DEFAULT_USER_ID forKey:APP_USER];
	[settings setInteger:DEFAULT_FREQUENCY_MULTIPLIER forKey:APP_FREQUENCY_MULTIPLIER];
	[settings setInteger:DEFAULT_MAX_STRUDYING forKey:APP_MAX_STUDYING];
	[settings setInteger:DEFAULT_DIFFICULTY forKey:APP_DIFFICULTY];
	
	[settings setBool:NO forKey:@"db_did_finish_copying"];
	[settings setBool:YES forKey:@"settings_already_created"];
}

#pragma mark -
#pragma mark Update and Check Settings Region. 

#pragma mark Version 1.1

/** Updates NSUserDefaults to use 1.1 values instead of 1.0 values (adds new ones, removes old first_load) */
+ (void) _updateSettingsFrom10to11:(NSUserDefaults*) settings
{
  // Definitely first-run after an upgrade.  Update their settings so we have the right stuff for 1.1
  // Update plugins so we have that we have that information
	LWE_LOG(@"This is the updated setting from 1.0 to 1.1");
  [settings setValue:[PluginManager preinstalledPlugins] forKey:APP_PLUGIN];
  [settings setValue:JFLASH_VERSION_1_0 forKey:APP_DATA_VERSION];
  [settings setInteger:DEFAULT_FREQUENCY_MULTIPLIER forKey:APP_FREQUENCY_MULTIPLIER];
  [settings setInteger:DEFAULT_MAX_STRUDYING forKey:APP_MAX_STUDYING];
  [settings setInteger:DEFAULT_DIFFICULTY forKey:APP_DIFFICULTY];    
  
  // This is what first load is called now
  [settings setBool:YES forKey:@"settings_already_created"];
  
  // Now get rid of first_load so it doesn't confuse us
  [settings removeObjectForKey:@"first_load"];                        
  
  // This tells the CurrentState initializeSettings method that we're down with the new settings
  [settings setValue:JFLASH_VERSION_1_1 forKey:APP_SETTINGS_VERSION];
}


/** Returns YES if the user needs to update settings from 1.0 to 1.1, otherwise returns NO */
+ (BOOL) _needs10to11SettingsUpdate:(NSUserDefaults*) settings
{
  // First things first, do a check to make sure this is not a first run after an upgrade
  if ([settings objectForKey:@"first_load"])
  {
    // Aha, this is a JFlash 1.0 install, now double check the data version
    if ([settings objectForKey:@"data_version"] == nil)
    {
      return YES;
    }
    else
    {
      [NSException raise:@"first load exists, but data version does too!" format:@"data_version value was: %@",[settings objectForKey:@"data_version"]];
    }
  }
  return NO;
}

#pragma mark Version 1.2

/** Updates NSUserDefaults to add 1.2 values*/
+ (void) _updateSettingsFrom11to12:(NSUserDefaults*) settings
{
	LWE_LOG(@"Update from 1.1 to 1.2 Yatta!");
	[settings setObject:[NSDate dateWithTimeIntervalSince1970:0] forKey:PLUGIN_LAST_UPDATE];                    
	
  // Now change the app version and the data version
	[settings setValue:JFLASH_VERSION_1_2 forKey:APP_SETTINGS_VERSION];
  [settings setValue:JFLASH_VERSION_1_2 forKey:APP_DATA_VERSION];
}


/** Returns YES if the user needs to update settings from 1.1 to 1.2, otherwise returns NO */
+ (BOOL) _needs11to12SettingsUpdate:(NSUserDefaults*) settings
{
	// First things first, do a check to make sure this is not a first run after an upgrade
	// TODO: Check whether it needs to check [settings objectForKey:@"first_load"] as well
	if (![settings objectForKey:PLUGIN_LAST_UPDATE] && [settings valueForKey:@"settings_already_created"])
	{
		return YES;
	}
	return NO;
}


#pragma mark Version 1.3


/** Updates NSUserDefaults to add 1.2 values*/
+ (void) _updateSettingsFrom12to13:(NSUserDefaults*) settings
{
	LWE_LOG(@"Update from 1.2 to 1.3 - we need to make a tag for favorites!");

  // Open the database!
  LWEDatabase *db = [LWEDatabase sharedLWEDatabase];
  NSString *filename = JFLASH_CURRENT_USER_DATABASE;
  if ([db openDatabase:[LWEFile createDocumentPathWithFilename:filename]])
  {
    // Cool, we are open - run the SQL
    NSString *commands = [NSString stringWithContentsOfFile:[LWEFile createBundlePathWithFilename:JFLASH_12_TO_13_SQL_FILENAME] encoding:NSUTF8StringEncoding error:NULL];
    if (commands && [db executeUpdate:commands])
    {
      // Now change the app version
      [settings setValue:JFLASH_VERSION_1_3 forKey:APP_SETTINGS_VERSION];
      [settings setValue:JFLASH_VERSION_1_3 forKey:APP_DATA_VERSION];
    }
    else
    {
      LWE_LOG(@"Failed to update database from 1.2 to 1.3");
    }
    
    // In any case close the DB so that jFlash can open it
    [db closeDatabase];
  }
}


/** Returns YES if the user needs to update settings from 1.1 to 1.2, otherwise returns NO */
+ (BOOL) _needs12to13SettingsUpdate:(NSUserDefaults*) settings
{
  // We do not want to update the settings if we are STILL waiting on a 1.0 upgrade
  return ([[settings objectForKey:APP_DATA_VERSION] isEqualToString:JFLASH_VERSION_1_2] &&
          [settings valueForKey:@"settings_already_created"]);
}

#pragma mark -
#pragma mark Public Methods

+ (void) performMigrations:(NSUserDefaults*)settings
{
  // DEBUG: this simulates being a JFlash 1.0 upgrade user
  //[self _createDefaultSettingsFor10:settings];
  
  // NOTE THAT THESE ARE MIGRATIONS!!!!  They should be in order of version.
  
  // If we are JFlash 1.0 settings, update to 1.1
  if ([UpdateManager _needs10to11SettingsUpdate:settings])
  {
    [UpdateManager _updateSettingsFrom10to11:settings];
  }
	
  //In the jFlash 1.2, jFlash included some new features, and it requires the plugin manager to be updated.
  //The plugin manager will have to look at the last time it gets updated, there is the list of the data
  if ([UpdateManager _needs11to12SettingsUpdate:settings])
  {
		LWE_LOG(@"Oops, we need update to 1.2 version");
	  [UpdateManager _updateSettingsFrom11to12:settings];
  }
  
  // JFlash 1.3 - does small database migration for favorites!
  if ([UpdateManager _needs12to13SettingsUpdate:settings])
  {
		LWE_LOG(@"Oops, we need update to 1.3 version");
	  [UpdateManager _updateSettingsFrom12to13:settings];
  }
}

/**
 * Determine's if the user's database is lagging behind the current version
 * This is a static method as it only needs to access NSUserDefaults to return
 */
+ (BOOL) databaseIsUpdatable: (NSUserDefaults*)settings
{
  // Get the active database name from settings, compare to the current version.
  NSString *dataVersion = [settings objectForKey:APP_DATA_VERSION];
  if (dataVersion == nil)
  {
    // If dataVersion doesn't exist, this is a fresh install first load
    return NO;
  }
  else
  {
    // Is the active database the current one?
    if ([dataVersion isEqualToString:JFLASH_VERSION_1_0])
      return YES;
    else
      return NO;
  }
}

@end
