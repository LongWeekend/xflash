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
@synthesize isFirstLoad, pluginMgr, isUpdatable, isFirstLoadAfterNewVersion;

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


/** Updates NSUserDefaults to use 1.1 values instead of 1.0 values (adds new ones, removes old first_load) */
- (void) _updateSettingsFrom10to11:(NSUserDefaults*) settings
{
  // Definitely first-run after an upgrade.  Update their settings so we have the right stuff for 1.1
  // Update plugins so we have that we have that information
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


/**
 * Retrieve & initialize settings from NSUserDefaults to CurrentState object
 * It is vital for jFlash that this be the first thing called before ANY user
 * functionality is called to prevent versioning issues
 */
- (void) initializeSettings
{
  // We initialize the plugins manager
  //TODO: this is not the best place for this?
  [self setPluginMgr:[[PluginManager alloc] init]];

  NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];

  // DEBUG: this simulates being a JFlash 1.0 upgrade user
  //[self _createDefaultSettingsFor10:settings];
  
  // Dump the dictionary to make sure we have the right data
  LWE_DICT_DUMP([settings dictionaryRepresentation]);
  
  // STEP 1 - check for settings updates
  // If we are JFlash 1.0 settings, update to 1.1
  if ([self _needs10to11SettingsUpdate:settings])
  {
    [self _updateSettingsFrom10to11:settings];

    //DEBUG: check that the settings are updated correctly
    LWE_DICT_DUMP([settings dictionaryRepresentation]);

    [self setIsFirstLoadAfterNewVersion:YES];
  }
  else
  {
    // Normal execution, this is NO
    [self setIsFirstLoadAfterNewVersion:NO];
  }
  
  // STEP 2 - is the data update-able?
  // Let the version manager tell us if we are update-able
  [self setIsUpdatable:[VersionManager databaseIsUpdatable]];

  // STEP 3 - is this first run after a fresh install?
  // Do we need to freshly create settings?
  if ([settings objectForKey:@"settings_already_created"] == nil)
  {
    [self _createDefaultSettings];
    [self setIsFirstLoad:YES];
  }
  else
  {
    [self setIsFirstLoad:NO];
  }
}


/** Create & store default settings to NSUserDefaults */
- (void) _createDefaultSettings
{
  NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
  NSArray *keys = [[NSArray alloc] initWithObjects:APP_THEME,APP_HEADWORD,APP_READING,APP_MODE,APP_PLUGIN,APP_DATA_VERSION,nil];
  NSArray *objects = [[NSArray alloc] initWithObjects:DEFAULT_THEME,SET_J_TO_E,SET_READING_BOTH,SET_MODE_QUIZ,[PluginManager preinstalledPlugins],JFLASH_CURRENT_VERSION,nil];
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

//! Standard dealloc
- (void) dealloc
{
  [super dealloc];
  [self setPluginMgr:nil];
}
   
@end
