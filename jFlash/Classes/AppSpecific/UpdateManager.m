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
#if defined(LWE_JFLASH)

+ (void) _upgradeDBtoVersion:(NSString*)newVersionName withSQLStatements:(NSString*)pathToSQL forSettings:(NSUserDefaults *)settings;

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

+ (BOOL) _movePluginsToCacheDirectory;
#else

/**
 * CFLASH Private Helpers Go Here
 */

#endif
@end

@implementation UpdateManager
#if defined(LWE_JFLASH)
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

#pragma mark - Update and Check Settings Region. 

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
	// TODO: Check whether it needs to check [settings objectForKey:@"first_load"] as well
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
+ (void) _updateSettingsFrom12to13:(NSUserDefaults*) settings
{
	LWE_LOG(@"Update from 1.2 to 1.3 - we need to make a tag for favorites!");

  // Now do the PLIST as well
  [UpdateManager _updatePlistFrom12to13];

  [UpdateManager _upgradeDBtoVersion:LWE_JF_VERSION_1_3 withSQLStatements:LWE_JF_12_TO_13_SQL_FILENAME forSettings:settings];
}


/** Returns YES if the user needs to update settings from 1.2 to 1.3, otherwise returns NO */
+ (BOOL) _needs12to13SettingsUpdate:(NSUserDefaults*) settings
{
  // We do not want to update the settings if we are STILL waiting on a 1.0 upgrade
  return ([[settings objectForKey:APP_DATA_VERSION] isEqualToString:LWE_JF_VERSION_1_2] &&
          [settings valueForKey:@"settings_already_created"]);
}


#pragma mark - Version 1.4

/** Returns YES if the user needs to update settings from 1.3 to 1.4, otherwise returns NO */
+ (BOOL) _needs13to14SettingsUpdate:(NSUserDefaults*) settings
{
  // We do not want to update the settings if we are STILL waiting on a 1.0 upgrade
  return ([[settings objectForKey:APP_DATA_VERSION] isEqualToString:LWE_JF_VERSION_1_3] && 
          [settings valueForKey:@"settings_already_created"]);
}

#pragma mark - Version 1.5

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

#pragma mark - Version 1.6

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
  
  //New key for the user settings preference in version 1.6
  [settings setObject:LWE_JF_VERSION_1_6 forKey:APP_SETTINGS_VERSION];

  // 1. Execute SQL update file for bad data fixes
  [UpdateManager _upgradeDBtoVersion:LWE_JF_VERSION_1_6 withSQLStatements:LWE_JF_15_TO_16_SQL_FILENAME forSettings:settings];
  
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

  // 3. for moving the already downloaded plugins, but it's not happening for now
  //[self _movePluginsToCacheDirectory];
}


#pragma mark - Shared Private Methods

/**
 * This is a migration method to move already downloaded plugins from the doucments directory to the caches director, specific for 1.5->1.6 migration
 */
+ (BOOL) _movePluginsToCacheDirectory
{
  BOOL success = NO;
  
  NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
  NSMutableDictionary *plugins = [settings objectForKey:APP_PLUGIN];
	LWE_LOG(@"This is the APP_PLUGIN in the NSUserDefaults : %@", plugins);
  NSEnumerator *keyEnumerator = [plugins keyEnumerator];
  NSString *key;
  NSFileManager *fileManager = [NSFileManager defaultManager];
  NSError* error;
  while ((key = [keyEnumerator nextObject]))
  {
    NSString* filename = [plugins objectForKey:key];
		LWE_LOG(@"LOG : Trying to move the installed plugins = %@, with filename = %@ to caches directory", key, filename);
    NSString* documentPathToFilename = [LWEFile createDocumentPathWithFilename:filename];
    if ([LWEFile fileExists:documentPathToFilename])
    {
      success = [fileManager moveItemAtPath:documentPathToFilename toPath:[LWEFile createCachesPathWithFilename:filename] error:&error];
    }
  }
  return success;
}

+ (BOOL) _runMultipleSQLStatements:(NSString*)filePath inDB:(LWEDatabase*)db
{
  // Init variables
  BOOL success = YES;
  FILE *fh = NULL;
  char str_buf[1024];
  
  // Get SQL statement file ready
  fh = fopen([filePath UTF8String],"r");
  if (fh == NULL)
  {
    [NSException raise:@"SQLStatementFileNotOpened" format:@"Unable to open/read SQL statement file"];
  }
  
  [db.dao beginDeferredTransaction];
  
  LWE_LOG(@"Starting SQL statement loop");
  while (!feof(fh))
  {
    fgets(str_buf,1024,fh); // get me a line of the file    
    if (![db.dao executeUpdate:[NSString stringWithCString:str_buf encoding:NSUTF8StringEncoding]])
    {
      success = NO;
      LWE_LOG(@"Unable to do SQL: %@",[NSString stringWithCString:str_buf encoding:NSUTF8StringEncoding]);
      break;
    }
  }
  if (success)
  {
    success = success && [db.dao commit];
  }
  else
  {
    [db.dao rollback];
  }
  
  // Close the file
  fclose(fh);
  
  return success;
}

//! a simple runner of SQL statements in a file and set the new version name
+ (void) _upgradeDBtoVersion:(NSString*)newVersionName withSQLStatements:(NSString*)pathToSQL forSettings:(NSUserDefaults *)settings  
{
  // Open the database!
  LWEDatabase *db = [LWEDatabase sharedLWEDatabase];
  NSString *filename = LWE_CURRENT_USER_DATABASE;
  if ([db openDatabase:[LWEFile createDocumentPathWithFilename:filename]])
  {
    // Cool, we are open - run the SQL
    if ([UpdateManager _runMultipleSQLStatements:[LWEFile createBundlePathWithFilename:pathToSQL] inDB:db])
    {
      // Now change the app version
      [settings setValue:newVersionName forKey:APP_DATA_VERSION];
    }
    else
    {
      // TODO: do something better here?
      LWE_LOG(@"Failed to update database in UpdateManager");
    }
    
    // In any case close the DB so that jFlash can open it
    [db closeDatabase];
  }
}
#endif

#pragma mark - Public Methods

+ (void) performMigrations:(NSUserDefaults*)settings
{
/**
 * JFLASH MIGRATIONS
 */
#if defined(LWE_JFLASH)
  // NOTE THAT THESE ARE MIGRATIONS!!!!  They should be in order of version.
	
  //In the jFlash 1.2, jFlash included some new features, and it requires the plugin manager to be updated.
  //The plugin manager will have to look at the last time it gets updated, there is the list of the data
  if ([UpdateManager _needs11to12SettingsUpdate:settings])
  {
		LWE_LOG(@"[Migration Log]Oops, we need update to 1.2 version");
	  [UpdateManager _updateSettingsFrom11to12:settings];
  }
  
  // JFlash 1.3 - does small database migration for favorites!
  if ([UpdateManager _needs12to13SettingsUpdate:settings])
  {
		LWE_LOG(@"[Migration Log]Oops, we need update to 1.3 version");
	  [UpdateManager _updateSettingsFrom12to13:settings];
  }
  
  if ([UpdateManager _needs13to14SettingsUpdate:settings])
  {
    LWE_LOG(@"[Migration Log]Updating to 1.4 version");
    [UpdateManager _upgradeDBtoVersion:LWE_JF_VERSION_1_4 withSQLStatements:LWE_JF_13_TO_14_SQL_FILENAME forSettings:settings];
    [TagPeer recacheCountsForUserTags];
  }
  
  if ([UpdateManager _needs14to15SettingsUpdate:settings])
  {
    LWE_LOG(@"[Migration Log]YAY! Updating to 1.5 version");
    [UpdateManager _updateSettingsFrom14to15:settings];
  }
  
  if ([UpdateManager _needs15to16SettingsUpdate:settings])
  {
    LWE_LOG(@"[Migration Log]YAY! Updating to 1.6 version");
    [UpdateManager _updateSettingsFrom15to16:settings];
  }
  
#else
/**
 * FUTURE CFLASH MIGRATIONS HERE
 */
#endif
}

/**
 * Determine's if the user's database is lagging behind the current version
 * This is a static method as it only needs to access NSUserDefaults to return
 */
+ (BOOL) databaseIsUpdatable: (NSUserDefaults*)settings
{
#if defined(LWE_JFLASH)
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
    if ([dataVersion isEqualToString:LWE_JF_VERSION_1_0])
      return YES;
    else
      return NO;
  }
#else
  return NO;
#endif
}

@end
