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
 * Owns the theme manager and the version manager (to be debated whether that is the best design or not)
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


/**
 * Retrieve & initialize settings from NSUserDefaults to CurrentState object
 */
- (void) initializeSettings
{
  // We initialize the plugins manager & version manager
  //TODO: this is not the best place for this?
  [self setPluginMgr:[[PluginManager alloc] init]];

  NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];

  // Check for first load (MUST keep "first load" in there, that's what it was in JFlash 1.0)
  // We deprecated it in favor of "settings_already_created", which is must more descriptive...
  if ([settings objectForKey:@"settings_already_created"] || [settings objectForKey:@"first_load"])
  {
    // If we don't have a key for the current version of JFlash, we can assume it is first load after update
    if (![settings objectForKey:JFLASH_CURRENT_VERSION])
    {
      [settings setValue:[NSNumber numberWithBool:YES] forKey:JFLASH_CURRENT_VERSION];
      [self setIsFirstLoadAfterNewVersion:YES];
    }
    else
    {
      [self setIsFirstLoadAfterNewVersion:NO];
    }
    [self setIsFirstLoad:NO];
    [self setIsUpdatable:[VersionManager databaseIsUpdatable]];
  }
  else
  {
    [self setIsFirstLoad:YES];
    [self setIsFirstLoadAfterNewVersion:NO];
    [self setIsUpdatable:NO];
    [self _createDefaultSettings];
  }
}


//! Create & store default settings to NSUserDefaults
- (void) _createDefaultSettings
{
  NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];

  NSDictionary *availablePlugins = [[NSDictionary alloc] initWithObjectsAndKeys:[LWEFile createBundlePathWithFilename:JFLASH_CURRENT_CARD_DATABASE],CARD_DB_KEY,nil];
  NSArray *keys = [[NSArray alloc] initWithObjects:@"theme", @"headword", @"reading", @"mode", @"plugins",@"data_version",nil];
  NSArray *objects = [[NSArray alloc] initWithObjects:DEFAULT_THEME,SET_J_TO_E,SET_READING_BOTH,SET_MODE_QUIZ,availablePlugins,JFLASH_CURRENT_VERSION,nil];
  for(int i=0; i < [keys count]; i++)
  {
    [settings setValue:[objects objectAtIndex:i] forKey:[keys objectAtIndex:i]];
  }  
  [keys release];
  [objects release];
  [availablePlugins release];
  // these are integers so we can't use the array loop above
  [settings setInteger:DEFAULT_TAG_ID forKey:@"tag_id"];
  [settings setInteger:DEFAULT_USER_ID forKey:@"user_id"];
  [settings setInteger:DEFAULT_FREQUENCY_MULTIPLIER forKey:APP_FREQUENCY_MULTIPLIER];
  [settings setInteger:DEFAULT_MAX_STRUDYING forKey:APP_MAX_STUDYING];
  [settings setInteger:DEFAULT_DIFFICULTY forKey:APP_DIFFICULTY];
  // disable first load messsage if we get this far
  [settings setBool:YES forKey:@"settings_already_created"];
  [settings setBool:NO forKey:@"db_did_finish_copying"];
}

- (void) dealloc
{
  [super dealloc];
  [self setPluginMgr:nil];
}
   
@end
