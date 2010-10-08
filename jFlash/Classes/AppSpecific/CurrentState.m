//
//  CurrentState.m
//  jFlash
//
//  Created by Mark Makdad on 7/12/09.
//  Copyright 2009 LONG WEEKEND INC.. All rights reserved.
//

#import "CurrentState.h"
#import "VersionManager.h"

/**
 * Maintains the current state of the application (active set, etc).  Is a singleton.
 * Owns the plugin manager (to be debated whether that is the best design or not)
 */
@implementation CurrentState
@synthesize isFirstLoad, pluginMgr, isUpdatable;

SYNTHESIZE_SINGLETON_FOR_CLASS(CurrentState);

/**
 * Sets the current active study set/tag - also loads cardIds for the tag
 */
- (void) setActiveTag: (Tag*) tag
{
  [tag retain];
  [_activeTag release];
  _activeTag = tag;
  
  NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
  [settings setInteger:tag.tagId forKey:@"tag_id"];
  
  [_activeTag populateCardIds];
}


/**
 * Returns the current active study set/tag
 */
- (Tag *) activeTag
{
  if(_activeTag == nil || [_activeTag cardCount] == 0)
  {
    NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
    int storedTagId = [settings integerForKey:@"tag_id"];
    // error handling in case we somehow set the tag id to 0
    if(storedTagId == 0) storedTagId = DEFAULT_TAG_ID;
    [self setActiveTag:[TagPeer retrieveTagById:storedTagId]];
    int currentIndex = [settings integerForKey:@"current_index"];
    [[self activeTag] setCurrentIndex:currentIndex];
  }
  
  id tag;
  tag = [[_activeTag retain] autorelease];
  return tag;
}


/**
 * Reloads cardIds for active set
 */
- (void) resetActiveTag
{
  [self setActiveTag:[self activeTag]];
}

#pragma mark -
#pragma mark DEBUG PURPOSES

/** DEBUG ONLY method to simulate settings for JFlash 1.0 **/
- (void) _createDefaultSettingsFor10:(NSUserDefaults*) settings
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
- (void) _createDefaultSettingsFor11:(NSUserDefaults*) settings
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
- (void) _updateSettingsFrom10to11:(NSUserDefaults*) settings
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
- (BOOL) _needs10to11SettingsUpdate:(NSUserDefaults*) settings
{
  // First things first, do a check to make sure this is not a first run after an upgrade
  if ([settings objectForKey:@"first_load"])
  {
    // Aha, this is a JFlash 1.0 install, now double check the data version
    if ([settings objectForKey:@"data_version"] == nil)
      return YES;
    else 
      [NSException raise:@"first load exists, but data version does too!" format:@"data_version value was: %@",[settings objectForKey:@"data_version"]];
  }
  return NO;
}

#pragma mark Version 1.2

/** Updates NSUserDefaults to add 1.2 values*/
- (void) _updateSettingsFrom11to12:(NSUserDefaults*) settings
{
	LWE_LOG(@"Update from 1.1 to 1.2 Yatta!");
	[settings setObject:[NSDate dateWithTimeIntervalSince1970:0] forKey:PLUGIN_LAST_UPDATE];                    
	
  // Now change the app version and the data version
	[settings setValue:JFLASH_VERSION_1_2 forKey:APP_SETTINGS_VERSION];
  [settings setValue:JFLASH_VERSION_1_2 forKey:APP_DATA_VERSION];
}


/** Returns YES if the user needs to update settings from 1.1 to 1.2, otherwise returns NO */
- (BOOL) _needs11to12SettingsUpdate:(NSUserDefaults*) settings
{
	// First things first, do a check to make sure this is not a first run after an upgrade
	// TODO: Check whether it needs to check [settings objectForKey:@"first_load"] as well
	if (![settings objectForKey:PLUGIN_LAST_UPDATE])
	{
		return YES;
	}
	LWE_LOG(@"DEBUG : Plugin last update key apparently does exist, this is the value = %@", [settings objectForKey:PLUGIN_LAST_UPDATE]);
	return NO;
}


#pragma mark Version 1.3


/** Updates NSUserDefaults to add 1.2 values*/
- (void) _updateSettingsFrom12to13:(NSUserDefaults*) settings
{
	LWE_LOG(@"Update from 1.2 to 1.3 Yatta!");
  // Now change the app version
	[settings setValue:JFLASH_VERSION_1_3 forKey:APP_SETTINGS_VERSION];
  
  // No need to change the data version because it hasn't changed at all between 1.2 and 1.3
}


/** Returns YES if the user needs to update settings from 1.1 to 1.2, otherwise returns NO */
- (BOOL) _needs12to13SettingsUpdate:(NSUserDefaults*) settings
{
  // If the user was a fresh installer of 1.2, they had this condition where there was no setting for
  // APP_SETTINGS_VERSION - it was our oversight.
  
  // If the user has an APP_DATA_VERSION of 1.2, but does not have the APP_SETTINGS flag, they need it.
  if ([[settings objectForKey:APP_DATA_VERSION] isEqualToString:JFLASH_VERSION_1_2] &&
      [settings objectForKey:APP_SETTINGS_VERSION] == nil)
  {
    return YES;
  }
  else
  {
    return NO;
  }
}
#pragma mark -
#pragma mark Initialization


/**
 * Retrieve & initialize settings from NSUserDefaults to CurrentState object
 * It is vital for jFlash that this be the first thing called before ANY user
 * functionality is called to prevent versioning issues
 */
- (void) initializeSettings
{
  NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
  
  // ADD OBSERVER FOR DB COPY!
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(registerDatabaseCopied) name:LWEDatabaseCopyDatabaseDidSucceed object:nil];
   
  // DEBUG: this simulates being a JFlash 1.0 upgrade user
  //[self _createDefaultSettingsFor10:settings];
  
  // NOTE THAT THESE ARE MIGRATIONS!!!!  They should be in order of version.
  
  // STEP 1 - check for settings updates
  // If we are JFlash 1.0 settings, update to 1.1
  if ([self _needs10to11SettingsUpdate:settings])
  {
    [self _updateSettingsFrom10to11:settings];
  }
	
  //STEP 2 In the jFlash 1.2, jFlash included some new features, and it requires the plugin manager to be updated.
  //The plugin manager will have to look at the last time it gets updated, there is the list of the data
  if ([self _needs11to12SettingsUpdate:settings])
  {
		LWE_LOG(@"Oops, we need update to 1.2 version");
	  [self _updateSettingsFrom11to12:settings];
  }
  
  // In Jflash 1.3, not much has changed -- but unfortunately, we made a mistake in the 1.2 fresh installs -
  // we forgot to set APP_SETTINGS_VERSION, so this will do it
  if ([self _needs12to13SettingsUpdate:settings])
  {
		LWE_LOG(@"Oops, we need update to 1.3 version");
	  [self _updateSettingsFrom12to13:settings];
  }

  // STEP 3 - is the data update-able?  Let the version manager tell us
  [self setIsUpdatable:[VersionManager databaseIsUpdatable]];

  // STEP 4 - is this first run after a fresh install?  Do we need to freshly create settings?
  if ([settings objectForKey:@"settings_already_created"] == nil)
  {
    [self _createDefaultSettings];
    [self setIsFirstLoad:YES];
  }
  else
  {
    [self setIsFirstLoad:NO];
  }
  
  // STEP 5
  // We initialize the plugins manager
  [self setPluginMgr:[[[PluginManager alloc] init] autorelease]];  
}


/** Registers the db_did_finish_copying BOOL value in NSUserDefaults when called */
- (void) registerDatabaseCopied
{
  NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
  [settings setBool:YES forKey:@"db_did_finish_copying"];
}

#pragma mark -
#pragma mark Default - First time run.

/** Create & store default settings to NSUserDefaults */
- (void) _createDefaultSettings
{
  LWE_LOG(@"Creating the default settings");
  NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
  NSArray *keys = [[NSArray alloc] initWithObjects:APP_THEME,APP_HEADWORD,APP_READING,APP_MODE,APP_PLUGIN,nil];
  NSArray *objects = [[NSArray alloc] initWithObjects:DEFAULT_THEME,SET_J_TO_E,SET_READING_BOTH,SET_MODE_QUIZ,[PluginManager preinstalledPlugins],nil];
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
  [settings setValue:JFLASH_CURRENT_VERSION forKey:APP_DATA_VERSION];
  [settings setValue:JFLASH_CURRENT_VERSION forKey:APP_SETTINGS_VERSION];
  [settings setObject:[NSDate dateWithTimeIntervalSince1970:0] forKey:PLUGIN_LAST_UPDATE];

  [settings setBool:NO forKey:@"db_did_finish_copying"];
  [settings setBool:YES forKey:@"settings_already_created"];
}

#pragma mark -

//! Standard dealloc
- (void) dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [pluginMgr release];
  [super dealloc];
}
   
@end
