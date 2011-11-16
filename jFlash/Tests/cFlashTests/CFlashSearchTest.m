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

#pragma mark - Search Test Methods

- (void) testBasicSearch
{
  NSArray *results = [CardPeer fullTextSearchForKeyword:@"keyword"];
  NSInteger resultCount = [results count];
  STAssertEquals(3, resultCount, @"CFlash database should return 3 results for search keyword 'keyword'");
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
