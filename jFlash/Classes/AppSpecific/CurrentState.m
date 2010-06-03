//
//  CurrentState.m
//  jFlash
//
//  Created by Mark Makdad on 7/12/09.
//  Copyright 2009 LONG WEEKEND INC.. All rights reserved.
//

#import "CurrentState.h"

//! Maintains the current state of the application (active set, etc).  Is a singleton.
@implementation CurrentState
@synthesize isFirstLoad, pluginMgr;

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

// TODO: this is called loadActiveTag, but seems to only touch "current_index".  Any ideas?   (MMA 5/29/2010)
- (void) loadActiveTag
{
  LWE_LOG(@"START load active tag");
  NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
  int currentIndex = [settings integerForKey:@"current_index"];
  [[self activeTag] setCurrentIndex:currentIndex];
  LWE_LOG(@"END load active tag");
}


/**
 * Retrieve & initialize settings from NSUserDefaults to CurrentState object
 */
- (void) initializeSettings
{
  NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
  int firstLoad = 1;
  if([settings objectForKey:@"first_load"] != nil) firstLoad = [settings integerForKey:@"first_load"];

  // We initialize the plugins manager
  [self setPluginMgr:[[PluginManager alloc] init]];
  
  // Now tell if first load or not
  if (firstLoad)
  {
    // Initialize all settings & defaults
    [self setIsFirstLoad:YES];
    NSMutableDictionary *availablePlugins = [[NSMutableDictionary alloc] init];
    NSArray *keys = [[NSArray alloc] initWithObjects:@"theme", @"headword", @"reading", @"mode", @"plugins", nil];
    NSArray *objects = [[NSArray alloc] initWithObjects:DEFAULT_THEME,SET_J_TO_E,SET_READING_BOTH,SET_MODE_QUIZ,availablePlugins,nil];
    for(int i=0; i < [keys count]; i++)
    {
      [settings setValue:[objects objectAtIndex:i] forKey:[keys objectAtIndex:i]];
    }

    [availablePlugins release];
    [keys release];
    [objects release];

    // these are integers so we can't use the array loop above
    [settings setInteger:DEFAULT_TAG_ID forKey:@"tag_id"];
    [settings setInteger:DEFAULT_USER_ID forKey:@"user_id"];
    
    // disable first load messsage if we get this far
    [settings setInteger:0 forKey:@"first_load"];
    [settings setBool:NO forKey:@"db_did_finish_copying"];
  }
  else
  {
    [self setIsFirstLoad:NO];
  }
  
   // Set the app to be running 
  [settings setInteger:1 forKey:@"app_running"];
}
   
- (void) dealloc
{
  [super dealloc];
  [self setPluginMgr:nil];
}
   
@end
