//
//  CardTagTest.m
//  jFlash
//
//  Created by Rendy Pranata on 19/07/11.
//  Copyright 2011 Long Weekend LLC. All rights reserved.
//

#import "CardTagTest.h"

#import "TagPeer.h"
#import "JFlashDatabase.h"

static NSString * const kTagTestDefaultName             = @"TestTag";
static NSString * const kLongWeekendFavorites = @"Long Weekend Favorites";

@interface CardTagTest ()
@property (retain) Tag *tag;
@end


@implementation CardTagTest

@synthesize tag = tag_;

- (void)testCalculateNextCardLevelWithError
{
  Tag *longWeekendFavTag = [TagPeer retrieveTagByName:kLongWeekendFavorites];
  [longWeekendFavTag populateCardIds];
  NSError* error;
  NSInteger nextCardLevel = [longWeekendFavTag calculateNextCardLevelWithError:&error];
  STAssertTrue(nextCardLevel < 6, @"Next card level is outside of possible range");
  
  // Now we cause an error but it's robust enough to work anyway
  Card* card = [longWeekendFavTag getRandomCard:0 error:&error];
  [longWeekendFavTag updateLevelCounts:card nextLevel:1];
  [longWeekendFavTag setCardCount:1];
  nextCardLevel = [longWeekendFavTag calculateNextCardLevelWithError:&error];
  STAssertTrue(nextCardLevel < 6, @"Next card level is outside of possible range");
}

- (void) testUpdateLevelCounts
{
  Tag *longWeekendFavTag = [TagPeer retrieveTagByName:kLongWeekendFavorites];
  [longWeekendFavTag populateCardIds];
  NSError *error = nil;
  Card *card = [longWeekendFavTag getRandomCard:0 error:&error];
  STAssertTrue((card != nil), @"Could not get random card");
  
  [longWeekendFavTag updateLevelCounts:card nextLevel:5];
  int count = [[[longWeekendFavTag cardIds] objectAtIndex:5] count];
  STAssertTrue(count > 0, @"Moved card to level 5 but level 5 is empty");
}

- (void)testAddThenRemoveCardsFromStudySet
{
  Tag *longWeekendFavTag = [TagPeer retrieveTagByName:kLongWeekendFavorites];
  Tag *newlyCreatedTag = [[CurrentState sharedCurrentState] activeTag];
  NSUInteger newlyCreatedTagId = [newlyCreatedTag tagId];
  STAssertNotNil(longWeekendFavTag, @"Failed in getting Long Weekend Favourite tag.");
  
  //get the list of card ids on the sample group study set and copy it over the newly created tag.
  NSArray *cardIds = [CardPeer retrieveCardIdsForTagId:[longWeekendFavTag tagId]];
  for (Card *card in cardIds)
  {
    NSUInteger cardId = [card cardId];
    NSLog(@"[TEST LOG]Adding card with id: %d to tag id: %d", cardId, newlyCreatedTagId);
    [TagPeer subscribeCard:card toTag:newlyCreatedTag];
  }
  NSLog(@"[TEST LOG]The newly created tag is has now been populated with group study set: %@", kLongWeekendFavorites);
  
  //Make sure that the test study set has the same count as the sample study set.
  NSArray *newCardIds = [CardPeer retrieveCardIdsForTagId:newlyCreatedTagId];
  STAssertEquals([cardIds count], [newCardIds count], @"Count number is diferent from tag %@ and the newly created group study: %@", 
                 kLongWeekendFavorites, [newlyCreatedTag tagName]);
  NSLog(@"[TEST LOG]Group Test Tag: %@ now has %@ as its card list.", newlyCreatedTag, newCardIds);
  
  //Remove the card one by one.
  NSUInteger count = [newCardIds count];
  for (int i=0; i<count; i++)
  {
    Card *card = [newCardIds objectAtIndex:i];
    NSError *error = nil;
    BOOL success = [TagPeer cancelMembership:card fromTag:newlyCreatedTag error:&error]; 
    if ((i!=count-1) && (!success)) 
    {
      STFail(@"Fail in removing a card from the newly created study set.\nCard with id: %d cannot be removed with error: %@", card.cardId, [error localizedDescription]);
    }
    else if ((i==count-1) && (!success))
    {
      STAssertTrue(((!success) && (error != nil) && ([error code] == kAllBuriedAndHiddenError)), @"Last card also get 'removed' which should not be removed.");
      NSLog(@"[TEST LOG]Last card in an active set couldn't be removed. Error from the TagPeer: %@", error);
    }
    else
    {
      NSLog(@"[TEST LOG]Card with id %d has been successfuly removed from an active set.", card.cardId);
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
  
  //Setup FTS
  result = [db setupAttachedDatabase:CURRENT_FTS_TEST_DATABASE asName:@"fts"];
  STAssertTrue(result, @"Failed to setup search database");

  //Setup Cards
  result = [db setupAttachedDatabase:CURRENT_CARD_TEST_DATABASE asName:@"cards"];
  STAssertTrue(result, @"Failed to setup cards database");
  
  //Create the tag for testing purposes.
  Tag *createdTag = [TagPeer createTag:kTagTestDefaultName withOwner:0];
  STAssertTrue(createdTag != nil, @"Failed in creating new tag (Study Set) for some reason.\nCreated TagId: %d", createdTag.tagId);
  
  //Tried to set the active tag to the one we just newly created
  CurrentState *state = [CurrentState sharedCurrentState];
  [state setActiveTag:createdTag];
  STAssertTrue([createdTag isEqual:[state activeTag]], 
                 @"Active tag has not been set properly. The active set tag set is: %@\nWhile the newly created tag should be: %@", 
                 [state activeTag], createdTag);
}

- (void)tearDown
{
  JFlashDatabase *db = [JFlashDatabase sharedJFlashDatabase];
  NSError *error = nil;
  BOOL result = [db removeTestDatabaseWithError:&error];
  STAssertTrue(result, @"Test database cannot be removed for some reason.\nError: %@", [error localizedDescription]);
}

@end