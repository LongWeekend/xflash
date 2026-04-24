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
#import "GroupPeer.h"

#import <UIKit/UIKit.h>

static NSString * const kLWEFavoriteTagName = @"Long Weekend Favorites";

@implementation TagTest

// All code under test is in the iOS Application

- (void)testTagNameAfterRetrieval
{
  Tag *tag = [TagPeer retrieveTagByName:kLWEFavoriteTagName];
  XCTAssertNotNil(tag, @"Should retrieve favorites tag");
  XCTAssertEqualObjects(kLWEFavoriteTagName, tag.tagName, @"Tag name should match what was requested");
}

- (void)testFavoritesTagIsNotEditable
{
  Tag *tag = [TagPeer retrieveTagByName:kLWEFavoriteTagName];
  XCTAssertNotNil(tag, @"Should retrieve favorites tag");
  XCTAssertFalse([tag isEditable], @"System tags must not be editable");
}

- (void)testCreateUserTagIsEditable
{
  Tag *created = [TagPeer createTagNamed:@"EditableTestTag" inGroup:[GroupPeer topLevelGroup]];
  XCTAssertNotNil(created, @"Should be able to create a user tag");
  XCTAssertTrue([created isEditable], @"User-created tags should be editable");
}

- (void)testCreateTagCanBeRetrievedByName
{
  NSString *name = @"RetrievalTestTag";
  Tag *created = [TagPeer createTagNamed:name inGroup:[GroupPeer topLevelGroup]];
  XCTAssertNotNil(created, @"Tag creation should succeed");

  Tag *fetched = [TagPeer retrieveTagByName:name];
  XCTAssertNotNil(fetched, @"Should retrieve the newly created tag by name");
  XCTAssertEqualObjects(name, fetched.tagName, @"Fetched tag name should match");
}

- (void)testRetrieveTagByIdMatchesTagByName
{
  Tag *byName = [TagPeer retrieveTagByName:kLWEFavoriteTagName];
  XCTAssertNotNil(byName, @"Should retrieve favorites by name");

  Tag *byId = [TagPeer retrieveTagById:byName.tagId];
  XCTAssertNotNil(byId, @"Should retrieve the same tag by its ID");
  XCTAssertEqualObjects(byName.tagName, byId.tagName, @"Tag name should be the same whether retrieved by name or ID");
}

- (void)testSysTagListIsNonEmpty
{
  NSArray *sysTags = [TagPeer retrieveSysTagList];
  XCTAssertNotNil(sysTags, @"System tag list should not be nil");
  XCTAssertTrue([sysTags count] > 0, @"There should be at least one system tag");
}

- (void)testSave
{
  NSString* description = @"Monkeys Fly Out of My Butt";
  Tag *favoritesTag = [TagPeer retrieveTagByName:kLWEFavoriteTagName];
  favoritesTag.tagDescription = description;
  [favoritesTag save];
  
  Tag *seperatelyRetrivedFavTag = [TagPeer retrieveTagByName:kLWEFavoriteTagName];
  XCTAssertEqualObjects(favoritesTag.tagDescription, seperatelyRetrivedFavTag.tagDescription, @"The DB does not contain the saved description");
  
  description = @"' foo";
  favoritesTag = [TagPeer retrieveTagByName:kLWEFavoriteTagName];
  favoritesTag.tagDescription = description;
  [favoritesTag save];
  
  seperatelyRetrivedFavTag = [TagPeer retrieveTagByName:kLWEFavoriteTagName];
  XCTAssertEqualObjects(favoritesTag.tagDescription, seperatelyRetrivedFavTag.tagDescription, @"The DB does not contain the saved description");
}

#pragma mark -
#pragma mark Setting up

- (void)setUp
{
  //get the cloned database as a test database.
  NSError *error = nil;
  JFlashDatabase *db = [JFlashDatabase sharedJFlashDatabase];
  BOOL result = [db setupTestDatabaseAndOpenConnectionWithError:&error];
  XCTAssertTrue(result, @"Failed in setup the test database with error: %@", [error localizedDescription]);
  
  //Setup Cards
  result = [db setupAttachedDatabase:CURRENT_CARD_TEST_DATABASE asName:@"cards"];
  XCTAssertTrue(result, @"Failed to setup cards database");
}

- (void)tearDown
{
  JFlashDatabase *db = [JFlashDatabase sharedJFlashDatabase];
  NSError *error = nil;
  BOOL result = [db removeTestDatabaseWithError:&error];
  XCTAssertTrue(result, @"Test database cannot be removed for some reason.\nError: %@", [error localizedDescription]);
}

@end
