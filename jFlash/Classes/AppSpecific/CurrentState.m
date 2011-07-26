//
//  CurrentState.m
//  jFlash
//
//  Created by Mark Makdad on 7/12/09.
//  Copyright 2009 LONG WEEKEND INC.. All rights reserved.
//

#import "CurrentState.h"
#import "UpdateManager.h"

// For private methods
@interface CurrentState ()
- (void) _createDefaultSettings;
@end


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
  if (_activeTag == nil || [_activeTag cardCount] == 0)
  {
    NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
    NSInteger storedTagId = [settings integerForKey:@"tag_id"];
    [self setActiveTag:[TagPeer retrieveTagById:storedTagId]];
    NSInteger currentIndex = [settings integerForKey:@"current_index"];
    // Do not use getter here - it may cause an infinite loop if the card count of the active tag is 0 (which should never hapen but)
    [_activeTag setCurrentIndex:currentIndex];
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
   
  // STEP 1 - Migrations for settings for different versions of JFlash
  [UpdateManager performMigrations:settings];

  // STEP 2 - is the database update-able?  Let the update manager tell us
  [self setIsUpdatable:[UpdateManager databaseIsUpdatable:settings]];

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
  [settings setValue:LWE_CURRENT_VERSION forKey:APP_DATA_VERSION];
  [settings setValue:LWE_CURRENT_VERSION forKey:APP_SETTINGS_VERSION];
  [settings setObject:[NSDate dateWithTimeIntervalSince1970:0] forKey:PLUGIN_LAST_UPDATE];

  [settings setBool:NO forKey:APP_HIDE_BURIED_CARDS];
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
