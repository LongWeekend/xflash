//
//  CardTagTest.m
//  jFlash
//
//  Created by Rendy Pranata on 19/07/11.
//  Copyright 2011 Long Weekend LLC. All rights reserved.
//

#import "CardTagTest.h"
#import "AppDelegate.h"

#import "TagPeer.h"
#import "JFlashDatabase.h"

static NSString * const kTagTestDefaultName             = @"TestTag";
static NSString * const kDefaultGroupStudySetToCopyFrom = @"Long Weekend Favorites";

@interface CardTagTest ()
@property (retain) Tag *tag;
@end


@implementation CardTagTest

@synthesize tag = tag_;

- (void)testAddThenRemoveCardsFromStudySet
{
  Tag *longWeekendFavTag = [TagPeer retrieveTagByName:kDefaultGroupStudySetToCopyFrom];
  Tag *newlyCreatedTag = [[CurrentState sharedCurrentState] activeTag];
  NSUInteger newlyCreatedTagId = [newlyCreatedTag tagId];
  STAssertNotNil(longWeekendFavTag, @"Failed in getting Long Weekend Favourite tag.");
  
  //get the list of card ids on the sample group study set and copy it over the newly created tag.
  NSArray *cardIds = [CardPeer retrieveCardIdsForTagId:[longWeekendFavTag tagId]];
  for (Card *card in cardIds)
  {
    NSUInteger cardId = [card cardId];
    NSLog(@"[TEST LOG]Adding card with id: %d to tag id: %d", cardId, newlyCreatedTagId);
    [TagPeer subscribe:cardId tagId:newlyCreatedTagId];
  }
  NSLog(@"[TEST LOG]The newly created tag is has now been populated with group study set: %@", kDefaultGroupStudySetToCopyFrom);
  
  //Make sure that the test study set has the same count as the sample study set.
  NSArray *newCardIds = [CardPeer retrieveCardIdsForTagId:newlyCreatedTagId];
  STAssertEquals([cardIds count], [newCardIds count], @"Count number is diferent from tag %@ and the newly created group study: %@", 
                 kDefaultGroupStudySetToCopyFrom, [newlyCreatedTag tagName]);
  NSLog(@"[TEST LOG]Group Test Tag: %@ now has %@ as its card list.", newlyCreatedTag, newCardIds);
  
  //Remove the card one by one.
  NSUInteger count = [newCardIds count];
  for (int i=0; i<count; i++)
  {
    Card *card = [newCardIds objectAtIndex:i];
    NSUInteger cardId = [card cardId];
    NSError *error = nil;
    BOOL success = [TagPeer cancelMembership:cardId tagId:newlyCreatedTagId error:&error]; 
    if ((i!=count-1) && (!success)) 
    {
      STFail(@"Fail in removing a card from the newly created study set.\nCard with id: %d cannot be removed with error: %@", cardId, [error localizedDescription]);
    }
    else if ((i==count-1) && (!success))
    {
      STAssertTrue(((!success) && (error != nil) && ([error code] == kAllBuriedAndHiddenError)), @"Last card also get 'removed' which should not be removed.");
      NSLog(@"[TEST LOG]Last card in an active set couldn't be removed. Error from the TagPeer: %@", error);
    }
    else
    {
      NSLog(@"[TEST LOG]Card with id %d has been successfuly removed from an active set.", cardId);
    }
  }
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
  
  //Create the tag for testing purposes.
  NSUInteger createdTagId = [TagPeer createTag:kTagTestDefaultName withOwner:0];
  STAssertTrue(createdTagId != 0, @"Failed in creating new tag (Study Set) for some reason.\nCreated TagId: %d", createdTagId);
  
  //Tried to set the active tag to the one we just newly created
  Tag *tag = [TagPeer retrieveTagById:createdTagId];
  STAssertNotNil(tag, @"Tag with createdTagId: %d has failed to be retreived.", createdTagId);
  CurrentState *state = [CurrentState sharedCurrentState];
  [state setActiveTag:tag];
  STAssertTrue([tag isEqual:[state activeTag]], 
                 @"Active tag has not been set properly. The active set tag set is: %@\nWhile the newly created tag should be: %@", 
                 [state activeTag], tag);
}

- (void)tearDown
{
  JFlashDatabase *db = [JFlashDatabase sharedJFlashDatabase];
  NSError *error = nil;
  BOOL result = [db removeTestDatabaseWithError:&error];
  STAssertTrue(result, @"Test database cannot be removed for some reason.\nError: %@", [error localizedDescription]);
}

@end