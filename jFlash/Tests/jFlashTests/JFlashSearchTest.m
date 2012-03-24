//
//  JFlashSearchTest.m
//  jFlash
//
//  Created by Ross Sharrott on 11/25/11.
//  Copyright (c) 2011 Long Weekend LLC. All rights reserved.
//

#import "JFlashSearchTest.h"

#import <UIKit/UIKit.h>

#import "SetupDatabaseHelper.h"
#import "CardPeer.h"
#import "JapaneseCard.h"

@implementation JFlashSearchTest

- (NSArray *) _resultsForSearchKeyword:(NSString *)keyword
{
  NSArray *results = [CardPeer searchCardsForKeyword:keyword];
  STAssertTrue(([results count] > 0), @"Search should return more than 0 entries for keyword %@", keyword);
  return results;
}

#pragma mark - Search Test Methods

- (void) testBasicSearch
{
  NSArray *results = [CardPeer searchCardsForKeyword:@"日本語"];
  NSInteger resultCount = [results count];
  STAssertEquals(resultCount, 1, @"JFlash database should return 1 results for search keyword '日本語'");
}

- (void) testMatchReadingFirst
{
/*
    FROM THE STORY THIS IS INTENDED TO ADDRESS:
    Kieran, while searching for "Teruterubozu", tried putting in "teru".  He was surprised when none
    of the words began with "teru".... good point.  When I tested my hunch and put "terut", there were
    no entries (of course), and then I ran the deep search, and I came back with the single, correct card.
    I think the expected behavior from the search is that it would prioritize results that match the
    beginning of a headword, reading, or meaning.
 */
  NSArray *results = [self _resultsForSearchKeyword:@"teru"];
  if ([results count] > 0)
  {
    Card *card = [results objectAtIndex:0];
    [card hydrate];
    
    STAssertTrue([card.reading hasPrefix:@"teru"], @"Card reading should start with search term");
  }
  else
  {
    STFail(@"Couldn't get any cards for search: teru");
  }
}

- (void) testChokinFix
{
  /**
   * User reported that "ちょきん" (savings) was in the database as "chikin" (it was).  This
   * test confirms that it is fixed as of Mar 2012 (MMA).  It was actually a duplicate card 
   * (didn't match the real card because of the different reading in the first versions).
   *
   * Since we have trouble " deleting " cards, I just fixed the card.  This test confirms that.
   */
  NSArray *results = [CardPeer searchCardsForKeyword:@"貯金"];
  STAssertTrue([results count] > 0,@"Should have gotten some results for this search");
  for (JapaneseCard *card in results)
  {
    [card hydrate];
    // This will be "both" because the "reading" returns the romaji + kana in the ddefault setting
    STAssertEqualObjects(card.reading,@"ちょきん - chokin",@"Both readings should be chokin.");
  }
}

#pragma mark - Setup & Teardown

- (void)setUp
{
  //get the cloned database as a test database.
  NSError *error = nil;
  JFlashDatabase *db = [JFlashDatabase sharedJFlashDatabase];
  BOOL result = [db setupTestDatabaseAndOpenConnectionWithError:&error];
  STAssertTrue(result, @"Failed in setup the test database with error: %@", [error localizedDescription]);
  
  //Setup FTS
  result = [db setupAttachedDatabase:CURRENT_FTS_TEST_DATABASE asName:@"fts"];
  STAssertTrue(result, @"Failed to setup search database");
  
  //Setup Cards
  result = [db setupAttachedDatabase:CURRENT_CARD_TEST_DATABASE asName:@"cards"];
  STAssertTrue(result, @"Failed to setup cards database");
}

- (void)tearDown
{
  JFlashDatabase *db = [JFlashDatabase sharedJFlashDatabase];
  NSError *error = nil;
  BOOL result = [db removeTestDatabaseWithError:&error];
  STAssertTrue(result, @"Test database cannot be removed for some reason.\nError: %@", [error localizedDescription]);
}


@end
