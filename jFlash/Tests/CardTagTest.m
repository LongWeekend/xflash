//
//  CardTagTest.m
//  jFlash
//
//  Created by Rendy Pranata on 19/07/11.
//  Copyright 2011 Long Weekend LLC. All rights reserved.
//

#import "CardTagTest.h"
#import "SetupDatabaseHelper.h"

#import "TagPeer.h"

static NSString * const kTagTestDefaultName             = @"TestTag";
static NSString * const kLWEFavoriteTagName = @"Long Weekend Favorites";

@interface CardTagTest ()
@property (retain) Tag *tag;
@end


@implementation CardTagTest

@synthesize tag = tag_;

- (void)testCalculateNextCardLevelWithError
{
  Tag *longWeekendFavTag = [TagPeer retrieveTagByName:kLWEFavoriteTagName];
  [longWeekendFavTag populateCardIds];
  NSError *error = nil;
  NSInteger nextCardLevel = [longWeekendFavTag calculateNextCardLevelWithError:&error];
  STAssertTrue(nextCardLevel < 6, @"Next card level is outside of possible range");
  STAssertNil(error, @"There should not be an error getting the next level: %@", error);
  
  // Now we cause an error but it's robust enough to work anyway
  Card *card = [longWeekendFavTag getRandomCard:0 error:&error];
  [longWeekendFavTag moveCard:card toLevel:1];
  [longWeekendFavTag setCardCount:1];
  nextCardLevel = [longWeekendFavTag calculateNextCardLevelWithError:&error];
  STAssertTrue(nextCardLevel < 6, @"Next card level is outside of possible range");
  //  STAssertNotNil(error, @"There should be an error getting the next level, but wasn't");
}

- (void) testUpdateLevelCounts
{
  Tag *longWeekendFavTag = [TagPeer retrieveTagByName:kLWEFavoriteTagName];
  [longWeekendFavTag populateCardIds];
  NSError *error = nil;
  Card *card = [longWeekendFavTag getRandomCard:0 error:&error];
  STAssertNotNil(card,@"Could not get random card");
  STAssertNil(error, @"Error should be nil, but wasn't: %@",error);
  
  [longWeekendFavTag moveCard:card toLevel:5];
  NSInteger count = [[[longWeekendFavTag cardIds] objectAtIndex:5] count];
  STAssertTrue(count > 0, @"Moved card to level 5 but level 5 is empty");
}

- (void)testAddThenRemoveCardsFromStudySet
{
  Tag *newlyCreatedTag = [TagPeer createTagNamed:kTagTestDefaultName inGroup:[GroupPeer topLevelGroup]];
  Tag *longWeekendFavTag = [TagPeer retrieveTagByName:kLWEFavoriteTagName];

  //get the list of card ids on the sample group study set and copy it over the newly created tag.
  NSArray *cardIds = [CardPeer retrieveFaultedCardsForTag:longWeekendFavTag];
  for (Card *card in cardIds)
  {
    BOOL subscribed = [TagPeer subscribeCard:card toTag:newlyCreatedTag];
    STAssertTrue(subscribed,@"Could not subscribe card %@ to tag %@",card,newlyCreatedTag);
  }
  
  //Make sure that the test study set has the same count as the sample study set.
  NSArray *newCardIds = [CardPeer retrieveFaultedCardsForTag:newlyCreatedTag];
  STAssertEquals([cardIds count],[newCardIds count],@"Count number is diferent from default tag and the newly created group study: %@", [newlyCreatedTag tagName]);
  
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
  
  // Try to set the current tag to be LWE favorites
  Tag *favoritesTag = [TagPeer retrieveTagByName:kLWEFavoriteTagName];
  CurrentState *state = [CurrentState sharedCurrentState];
  [state setActiveTag:favoritesTag];
}

- (void)tearDown
{
  JFlashDatabase *db = [JFlashDatabase sharedJFlashDatabase];
  NSError *error = nil;
  BOOL result = [db removeTestDatabaseWithError:&error];
  STAssertTrue(result, @"Test database cannot be removed for some reason.\nError: %@", [error localizedDescription]);
}

@end