//
//  TagTest.m
//  jFlash
//
//  Created by Ross Sharrott on 12/2/11.
//  Copyright (c) 2011 Long Weekend LLC. All rights reserved.
//

#import "TagTest.h"
#import "SetupDatabaseHelper.h"
#import "TagPeer.h"
#import "Tag.h"

#import <UIKit/UIKit.h>

static NSString * const kLWEFavoriteTagName = @"Long Weekend Favorites";

@implementation TagTest

// All code under test is in the iOS Application
- (void)testSave
{
  NSString* description = @"Monkeys Fly Out of My Butt";
  Tag *favoritesTag = [TagPeer retrieveTagByName:kLWEFavoriteTagName];
  favoritesTag.tagDescription = description;
  [favoritesTag save];
  
  Tag *seperatelyRetrivedFavTag = [TagPeer retrieveTagByName:kLWEFavoriteTagName];
  STAssertEqualObjects(favoritesTag.tagDescription, seperatelyRetrivedFavTag.tagDescription, @"The DB does not contain the saved description");
  
  description = @"' foo";
  favoritesTag = [TagPeer retrieveTagByName:kLWEFavoriteTagName];
  favoritesTag.tagDescription = description;
  [favoritesTag save];
  
  seperatelyRetrivedFavTag = [TagPeer retrieveTagByName:kLWEFavoriteTagName];
  STAssertEqualObjects(favoritesTag.tagDescription, seperatelyRetrivedFavTag.tagDescription, @"The DB does not contain the saved description");
}

#pragma mark -
#pragma mark Setting up

- (void)setUp
{
  //get the cloned database as a test database.
  NSError *error = nil;
  JFlashDatabase *db = [JFlashDatabase sharedJFlashDatabase];
  BOOL result = [db setupTestDatabaseAndOpenConnectionWithError:&error];
  STAssertTrue(result, @"Failed in setup the test database with error: %@", [error localizedDescription]);
  
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
