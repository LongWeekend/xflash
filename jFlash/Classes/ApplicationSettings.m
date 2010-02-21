//
//  ApplicationSettings.m
//  jFlash
//
//  Created by Mark Makdad on 7/12/09.
//  Copyright 2009 LONG WEEKEND INC.. All rights reserved.
//

#import "ApplicationSettings.h"


@implementation ApplicationSettings
@synthesize activeSet,isFirstLoad,dao,databaseOpenFinished;

SYNTHESIZE_SINGLETON_FOR_CLASS(ApplicationSettings);

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


- (BOOL) databaseFileExists
{
  NSFileManager *fileManager = [NSFileManager defaultManager];
  NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
  NSString *documentsDirectory = [paths objectAtIndex:0];
  NSString *path = [documentsDirectory stringByAppendingPathComponent:@"jFlash.db"];	
  if(![fileManager fileExistsAtPath:path])
  {
    // This means it is a fresh install
    LWE_LOG(@"No database located at normal location, must be fresh install.");
    return NO;
  }
  return YES;
}

- (BOOL) openedDatabase
{
  self.databaseOpenFinished = NO;
  BOOL success = NO;
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
  NSString *documentsDirectory = [paths objectAtIndex:0];
  NSString *path = [documentsDirectory stringByAppendingPathComponent:@"jFlash.db"];	
  self.dao = [FMDatabase databaseWithPath:path];
  self.dao.logsErrors = YES;
  self.dao.traceExecution = YES;
  if ([self.dao open])
  {
    success = YES;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"databaseIsOpen" object:self];
  }
  else
  {
    LWE_LOG(@"FAIL - Could not open DB.");
  }
  [pool release];
  // So other threads can query whether we are done or not
  self.databaseOpenFinished = YES;
  return success;
}


- (void) loadActiveTag
{
  NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
  int currentIndex = [settings integerForKey:@"current_index"];
  [self setActiveSet:[TagPeer retrieveTagById:[settings integerForKey:@"tag_id"]]];
  [[self activeSet] setCurrentIndex:currentIndex];
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
  }
  else
  {
    [self setIsFirstLoad:NO];
  }
  
  // Did we crash?
  if (appRunning)
  {
    LWE_LOG(@"Appear to be recovering from a crash, we should rebuild indexes for caches here");
    //[[appSettings dao] executeUpdate:@"DELETE FROM tag_level_count_cache"];
  }
  else
  {
    // Set the app to be running 
    [settings setInteger:1 forKey:@"app_running"];
  }
}

@end
