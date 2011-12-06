//
//  CFlashSearchTest.m
//  jFlash
//
//  Created by Mark Makdad on 11/15/11.
//  Copyright (c) 2011 Long Weekend LLC. All rights reserved.
//

#import "CFlashSearchTest.h"

#import <UIKit/UIKit.h>

#import "SetupDatabaseHelper.h"
#import "CardPeer.h"

@implementation CFlashSearchTest

- (NSArray *) _searchKeywordExpectingResults:(NSString*)keyword
{
  NSArray *results = [CardPeer fullTextSearchForKeyword:keyword];
  STAssertTrue(([results count] > 0), @"FTS search returned no results for keyword: %@!", keyword);
  return results;
}

#pragma mark - Search Test Methods

- (void) testBasicSearch
{
  NSArray *results = [CardPeer fullTextSearchForKeyword:@"keyword"];
  NSInteger resultCount = [results count];
  STAssertEquals(3, resultCount, @"CFlash database should return 3 results for search keyword 'keyword'");
}

// When I search for "gong1", I would expect to see results whose pinyin *starts* with gong1 first.
- (void) testMatchPinyinFirst
{
  // The first card's reading should match
  NSArray *results = [self _searchKeywordExpectingResults:@"gong1"];
  Card *resultCard = [results objectAtIndex:0];
  [resultCard hydrate];
  STAssertEqualObjects(@"gong1", resultCard.reading, @"First search results should match pinyin search.");
}

// When I search for "人", the first match should be only that
- (void) testMatchExactCharacterFirst
{
  // The first card's headword should match
  NSArray *results = [self _searchKeywordExpectingResults:@"人"];
  Card *resultCard = [results objectAtIndex:0];
  [resultCard hydrate];
  STAssertEqualObjects(@"人", resultCard.headword, @"HW of these cards should be the same");
}

- (void) testMatchMultiplePinyin
{
  NSArray *results = [self _searchKeywordExpectingResults:@"duo1 gong1"];
  Card *resultCard = [results objectAtIndex:0];
  [resultCard hydrate];
  
  STAssertEqualObjects(@"duo1 gong1", resultCard.reading, @"First search results should match pinyin search.");
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
