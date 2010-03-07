//
//  ApplicationSettings.m
//  jFlash
//
//  Created by Mark Makdad on 7/12/09.
//  Copyright 2009 LONG WEEKEND INC.. All rights reserved.
//

#import "ApplicationSettings.h"


@implementation ApplicationSettings
@synthesize isFirstLoad;

SYNTHESIZE_SINGLETON_FOR_CLASS(ApplicationSettings);

- (void) setActiveTag: (Tag*) tag
{
  [tag retain];
  [_activeTag release];
  _activeTag = tag;
  
  NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
  [settings setInteger:tag.tagId forKey:@"tag_id"];
  
  if ([[settings objectForKey:APP_MODE] isEqualToString:SET_MODE_QUIZ])
  {
     // Get new card count cache
     [_activeTag populateCardIds];
     // Get a cache of unseen cards
     [_activeTag replenishUnseenCache];
  }
}

- (Tag *) activeTag
{
  if(_activeTag == nil)
  {
     NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
     [self setActiveTag:[TagPeer retrieveTagById:[settings integerForKey:@"tag_id"]]];
  }
  
  id tag;
  tag = [[_activeTag retain] autorelease];
  return tag;
}

+ (UIColor*) getThemeTintColor
{
  UIColor *theColor;
  NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
  if ([[settings objectForKey:APP_THEME] isEqualToString:SET_THEME_FIRE])
  {
    theColor = [UIColor colorWithRed:THEME_FIRE_NAV_TINT_R green:THEME_FIRE_NAV_TINT_G blue:THEME_FIRE_NAV_TINT_B alpha:0.8f];
  }
  else
  {
    theColor = [UIColor colorWithRed:THEME_WATER_NAV_TINT_R green:THEME_WATER_NAV_TINT_G blue:THEME_WATER_NAV_TINT_B alpha:0.8f];
  }
  return theColor;
}

+ (NSString*) getThemeName
{
  NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
  NSString *theName;
  if ([[settings objectForKey:APP_THEME] isEqualToString:SET_THEME_FIRE])
  {
    theName = [[[NSString alloc] initWithString:@"red"] autorelease];
  }
  else
  {
    theName = [[[NSString alloc] initWithString:@"blue"] autorelease];
  }
  return theName;
}


- (void) loadActiveTag
{
  LWE_LOG(@"START load active tag");
  NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
  int currentIndex = [settings integerForKey:@"current_index"];
  [self setActiveTag:[TagPeer retrieveTagById:[settings integerForKey:@"tag_id"]]];
  [[self activeTag] setCurrentIndex:currentIndex];
  LWE_LOG(@"END load active tag");
}

- (BOOL) splashIsOn
{
  NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
  if ([[settings objectForKey:APP_SPLASH] isEqualToString:SET_SPLASH_ON])
    return YES;
  else
    return NO;
}

- (void) initializeSettings
{
  NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
  int firstLoad = 1;
  if([settings objectForKey:@"first_load"] != nil) firstLoad = [settings integerForKey:@"first_load"];
  int appRunning = [settings integerForKey:@"app_running"];
  
  // Now tell if first load or not
  if (firstLoad)
  {
    [self setIsFirstLoad:YES];
    // Initialize all settings & defaults
    NSArray *keys = [NSArray arrayWithObjects:@"theme", @"headword", @"reading", @"mode", @"splash", nil];
    NSArray *objects = [NSArray arrayWithObjects:SET_THEME_FIRE,SET_J_TO_E,SET_READING_BOTH,SET_MODE_QUIZ,SET_SPLASH_ON,nil];
    for(int i=0; i < [keys count]; i++)
    {
      [settings setValue:[objects objectAtIndex:i] forKey:[keys objectAtIndex:i]];
    }
    // these are integers so we can't use the array loop above
    [settings setInteger:DEFAULT_TAG_ID forKey:@"tag_id"];
    [settings setInteger:DEFAULT_USER_ID forKey:@"user_id"];
    
    // disable first load messsage if we get this far
    [settings setInteger:0 forKey:@"first_load"];
  }
  else
  {
    [self setIsFirstLoad:NO];
  }
  
  // Did we crash?
  if (appRunning)
  {
    LWE_LOG(@"Appear to be recovering from a crash, we should rebuild indexes for caches here");
    //[[db dao] executeUpdate:@"DELETE FROM tag_level_count_cache"];
  }
  else
  {
    // Set the app to be running 
    [settings setInteger:1 forKey:@"app_running"];
  }
}

@end
