//
//  JapaneseCard.m
//  jFlash
//
//  Created by Mark Makdad on 8/21/11.
//  Copyright 2011 Long Weekend LLC. All rights reserved.
//

#import "JapaneseCard.h"
#import "ExampleSentencePeer.h"

@implementation JapaneseCard

@synthesize romaji;

- (void) dealloc
{
  [romaji release];
  [super dealloc];
}

- (void) simpleHydrate: (FMResultSet*) rs
{
  [super simpleHydrate:rs];
  self.romaji = [rs stringForColumn:@"romaji"];
}

- (void) hydrate:(FMResultSet*)rs simple:(BOOL)isSimple
{
  [super hydrate:rs simple:isSimple];
  self.romaji = [rs stringForColumn:@"romaji"];
}

- (void) hydrate:(FMResultSet*)rs
{
  [super hydrate:rs];
  self.romaji = [rs stringForColumn:@"romaji"];
}

/**
 * Returns YES if a card has example sentences attached to it
 * \param newVersion - If YES, uses 1.2 version Sql, if NO, uses 1.1 version
 */
- (BOOL) hasExampleSentences:(BOOL)newVersion
{
  // Get settings to determine what data versio we are on
  NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
  if([[settings objectForKey:APP_DATA_VERSION] isEqualToString:LWE_JF_VERSION_1_0]) // version 1 doesn't understand this so say NO
  {
		LWE_LOG(@"JFlash Version 1.0?"); 
    return NO;
  }
  if ([[[CurrentState sharedCurrentState] pluginMgr] pluginIsLoaded:EXAMPLE_DB_KEY] == NO) // we always have a sentence if the plugin is not installed
  {
		LWE_LOG(@"Example Sentences plugin is NOT loaded");
    return YES;
  }
  else 
  {
		LWE_LOG(@"Example sentences show all?");
    return [ExampleSentencePeer sentencesExistForCardId:self.cardId showAll:newVersion];
  }
}

/** depending on APP_READING value in settings, will return a combined reading */
- (NSString*) reading //combinedReadingForSettings
{
  NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
  NSString *combined_reading;
  
  // Mux the readings according to user preference
  if([[settings objectForKey:APP_READING] isEqualToString:SET_READING_KANA])
  {
    combined_reading = [NSString stringWithFormat:@"%@", [self hw_reading]];
  } 
  else if([[settings objectForKey:APP_READING] isEqualToString: SET_READING_ROMAJI])
  {
    combined_reading = [NSString stringWithFormat:@"%@", [self romaji]];
  }
  else
  {
    // Both together
    combined_reading = [NSString stringWithFormat:@"%@ - %@", [self hw_reading], [self romaji]];
  }
  
  return combined_reading;
}


/** depending on APP_READING value in settings, will return a combined reading. This is used with the expand sample sentences functionality */
- (NSString*) readingBasedonSettingsForExpandedSampleSentences
{
	NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
	NSString *combined_reading;
	
	// Mux the readings according to user preference
	if([[settings objectForKey:APP_READING] isEqualToString:SET_READING_KANA])
	{
		combined_reading = [NSString stringWithFormat:@"%@", [self reading]];
	} 
	else if([[settings objectForKey:APP_READING] isEqualToString: SET_READING_ROMAJI])
	{
		combined_reading = [NSString stringWithFormat:@"%@", [self romaji]];
	}
	else
	{
		// Both together
		combined_reading = [NSString stringWithFormat:@"%@ - %@", [self reading], [self romaji]];
	}
	
	return combined_reading;
}

@end
