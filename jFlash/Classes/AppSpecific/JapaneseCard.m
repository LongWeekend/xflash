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

- (void) hydrateWithResultSet:(FMResultSet*)rs
{
  [self hydrateWithResultSet:rs simpleHydrate:NO];
  self.romaji = [rs stringForColumn:@"romaji"];
	self._headword    = [rs stringForColumn:@"headword"];
}

- (void) hydrateWithResultSet:(FMResultSet*)rs simpleHydrate:(BOOL)isSimple
{
  [super hydrateWithResultSet:rs simpleHydrate:isSimple];
  self.romaji = [rs stringForColumn:@"romaji"];
	self._headword    = [rs stringForColumn:@"headword"];
}

/**
 * Returns YES if a card has example sentences attached to it
 * \param newVersion - If YES, uses 1.2 version Sql, if NO, uses 1.1 version
 */
- (BOOL) hasExampleSentencesWithPluginManager:(PluginManager *)pluginManager;
{
  BOOL returnVal = NO;
  if ([pluginManager pluginKeyIsLoaded:EXAMPLE_DB_KEY]) // we always have a sentence if the plugin is not installed
  {
    returnVal = [ExampleSentencePeer sentencesExistForCardId:self.cardId];
  }
  return returnVal;
}

/** depending on APP_READING value in settings, will return a combined reading */
- (NSString*) reading
{
  NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
  NSString *combined_reading = nil;
  
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


@end
