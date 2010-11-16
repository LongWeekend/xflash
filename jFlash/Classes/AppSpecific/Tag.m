//
//  Tag.m
//  jFlash
//
//  Created by Paul Chapman on 5/6/09.
//  Copyright 2009 LONG WEEKEND LLC. All rights reserved.
//

#import "Tag.h"

@implementation Tag

@synthesize tagId, tagName, tagEditable, tagDescription, currentIndex, cardIds, cardLevelCounts, combinedCardIdsForBrowseMode;

- (id) init
{
  if ((self = [super init]))
  {
    cardCount = -1;
    self.currentIndex = 0;
  }
	return self;
}


/**
 * Calculates next card level based on current performance & Tag progress
 */
- (NSInteger) calculateNextCardLevel
{
  //-----Internal array consistency-----
  LWE_ASSERT(([self.cardLevelCounts count] == 6));
  //------------------------------------
  
  // control variables
  // controls how many words to show from new before preferring seen words
  NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
  int wordsInStudyingBeforeTakingNewCard = [settings integerForKey:APP_MAX_STUDYING];
  int weightingFactor = [settings integerForKey:APP_FREQUENCY_MULTIPLIER];
  
  // Total number of cards in this set
  int levelOneTotal;
  int totalCardsInSet = [self cardCount];
  if (totalCardsInSet < 1) return 0;
  
  // Get m cards in n bins, figure out total percentages
  // Calculate different of weights and percentages and adjust accordingly
  int i, tmpTotal = 0, denominatorTotal = 0, weightedTotal = 0, cardsSeenTotal = 0, numeratorTotal = 0;
  float p = 0,mean = 0, p_unseen = 0, pTotal = 0;
  int numLevels = 5;
  
  // the guts
  NSMutableArray* tmpTotalArray = [[NSMutableArray alloc] init];
  for (i = 1; i <= numLevels; i++)
  {
    // Get denominator values from cache/database
    tmpTotal = [[self.cardLevelCounts objectAtIndex:i] intValue];
    if (i == 1) levelOneTotal = tmpTotal;
    [tmpTotalArray addObject:[NSNumber numberWithInt:tmpTotal]];
    cardsSeenTotal = cardsSeenTotal + tmpTotal;
    denominatorTotal = denominatorTotal + (tmpTotal * weightingFactor * (numLevels - i + 1)); 
    numeratorTotal = numeratorTotal + (tmpTotal * i);
  }
  
  // Quick check to make sure we are not at the "start of a set". 
  if (cardsSeenTotal == totalCardsInSet)
  {
    p_unseen = 0;
  }
  else if (cardsSeenTotal > totalCardsInSet) // error check
  {
    // This should not happen, it is likely that we need to re-cache TotalCards
    LWE_LOG(@"CardTotal became more than totalCards... (%d, %d)", cardsSeenTotal, totalCardsInSet);
    p_unseen = 0;
  }
  else
  {
    // Get the "new card" p -- RSH - what is "p"??
    // MMA - p means probability in statistics :) and is usually defined between 0 (impossible) and 1 (definite)
    mean = (float)numeratorTotal / (float)cardsSeenTotal;
    p_unseen = (mean - (float)1);
    p_unseen = pow((p_unseen / (float) 4),weightingFactor);
    if (levelOneTotal < wordsInStudyingBeforeTakingNewCard && (totalCardsInSet - cardsSeenTotal) > 0)
    {
      p_unseen = p_unseen + (1-p_unseen)*(pow((wordsInStudyingBeforeTakingNewCard - cardsSeenTotal),.25)/pow(wordsInStudyingBeforeTakingNewCard,.25));
    }
  }
	
  float randomNum = ((float)rand() / (float)RAND_MAX);
  
  for (i = 1; i <= numLevels; i++)
  {
    tmpTotal = [[tmpTotalArray objectAtIndex:(i-1)] intValue];
    weightedTotal = (tmpTotal * weightingFactor * (numLevels - i + 1));
    p = ((float)weightedTotal / (float)denominatorTotal);
    p = (1-p_unseen)*p;
    pTotal = pTotal + p;
	  if (pTotal > randomNum)
    {
		  [tmpTotalArray release];
		  return i;
	  }
  }
  [tmpTotalArray release];
  return 0;
}


//! Create a cache of the number of Card objects in each level
- (void) cacheCardLevelCounts
{
  //-----Internal array consistency-----
  LWE_ASSERT(([self.cardIds count] == 6));
  //------------------------------------

  NSNumber *count;
  NSInteger totalCount = 0;
  NSMutableArray* cardLevelCountsTmp = [[NSMutableArray alloc] init];
  for (NSInteger i = 0; i < 6; i++)
  {
    count = [[NSNumber alloc] initWithInt:[[self.cardIds objectAtIndex:i] count]];
    [cardLevelCountsTmp addObject:count];
    totalCount = totalCount + [count intValue];
    [count release];
  }
  [self setCardLevelCounts:cardLevelCountsTmp];
  [cardLevelCountsTmp release];
  [self setCardCount:totalCount];
}


/** Unarchive plist file containing the user's last session data */
- (NSMutableArray*) thawCardIds
{
  NSString *path = [LWEFile createDocumentPathWithFilename:@"ids.plist"];
  NSMutableArray* tmpCardIds = [[[NSMutableArray alloc] initWithContentsOfFile:path] autorelease];
  LWE_LOG(@"Tried unarchiving plist file at path: %@",path);
  return tmpCardIds;
}


/** Archive current session data to a plist so we can re-start at same place in next session */
- (void) freezeCardIds
{
  NSString* path = [LWEFile createDocumentPathWithFilename:@"ids.plist"];
  LWE_LOG(@"Beginning plist freezing: %@",path);
  [self.cardIds writeToFile:path atomically:YES];
  LWE_LOG(@"Finished plist freeze");
}


/** Executed when loading a new set on app load */
- (void) populateCardIds
{
  LWE_LOG(@"Began populating card ids and setting counts");
  NSMutableArray* tmpArray = [self thawCardIds];
  if (tmpArray == nil)
  {
    LWE_LOG(@"No plist, load from database");
    tmpArray = [CardPeer retrieveCardIdsSortedByLevel:self.tagId];
  }
  else
  {
    LWE_LOG(@"Found plist, deleting plist");
    [LWEFile deleteFile:[LWEFile createDocumentPathWithFilename:@"ids.plist"]];
  }
  
  // Now set it
  [self setCardIds:tmpArray];
  
  // Also set the combined card ids
  [self setCombinedCardIdsForBrowseMode:[self combineCardIds]];

  // populate the card level counts
	[self cacheCardLevelCounts];
  
  LWE_LOG(@"End populating card ids and setting counts");
}


/**
 * Returns a Card object from the database randomly
 * Accepts current cardId in an attempt to not return the last card again
 */
- (Card*) getRandomCard:(NSInteger)currentCardId
{
  //-----Internal array consistency-----
#if defined(APP_STORE_FINAL)
  if ([self.cardIds count] != 6)
  {
    [FlurryAPI logError:@"getRandomCard" message:[NSString stringWithFormat:@"cardIds has %d indicies, not 6",[self.cardIds count]] error:nil];
  }
#else
  LWE_ASSERT(([self.cardIds count] == 6));
#endif
  //------------------------------------  
  
  // determine the next level
  NSInteger next_level = [self calculateNextCardLevel];
  
  // Get a random card offset
  NSInteger numCardsAtLevel = [[self.cardIds objectAtIndex:next_level] count];
  NSInteger randomOffset = 0;
  LWE_ASSERT (numCardsAtLevel > 0);
  if (numCardsAtLevel > 0)
  {
    randomOffset = arc4random() % numCardsAtLevel;
  }

  NSNumber* cardId;
  
  NSMutableArray* cardIdArray = [self.cardIds objectAtIndex:next_level];
  cardId = [cardIdArray objectAtIndex:randomOffset];

  // prevent getting the same card twice.
  if([cardId intValue] == currentCardId)
  {
    LWE_LOG(@"Got the same card as last time");
    // If there is only one card left (this card) in the level, let's get a different level
    if (numCardsAtLevel == 1)
    {
      LWE_LOG(@"Only one card left in this level, getting a new level");
      // Try up five times to get a different level
      int lastNextLevel = next_level;
      for (int j = 0; j < 5; j++)
      {
        next_level = [self calculateNextCardLevel];
        if (next_level != lastNextLevel) break;
      }
    }
    // now get a different card randomly
    cardIdArray = [self.cardIds objectAtIndex:next_level];
    int numCardsAtLevel2 = [[self.cardIds objectAtIndex:next_level] count];
    LWE_ASSERT(numCardsAtLevel2 > 0);
    if (numCardsAtLevel2 > 0)
    {
      randomOffset = arc4random() % numCardsAtLevel2;
    }
    cardId = [cardIdArray objectAtIndex:randomOffset];      
  }
  return [CardPeer retrieveCardByPK:[cardId intValue]];
}

/**
 * Update level counts cache - (kept in memory how many cards are in each level)
 */
- (void) updateLevelCounts:(Card*) card nextLevel:(NSInteger) nextLevel
{
  //-----Internal array consistency-----
#if defined(APP_STORE_FINAL)
  if ([self.cardIds count] != 6)
  {
    [FlurryAPI logError:@"updateLevelCounts" message:@"currentCardId is nil" error:nil];
  }
#else
  LWE_ASSERT(([self.cardIds count] == 6));
#endif
  //------------------------------------  
  
  // update the cardIds if necessary
  if (nextLevel != card.levelId)
  {
    LWE_LOG(@"Moving card Id %d From level %d to level %d",card.cardId,card.levelId,nextLevel);
    NSNumber *cardId = [NSNumber numberWithInt:card.cardId];

    NSMutableArray *thisLevelCards = [self.cardIds objectAtIndex:card.levelId];
    NSMutableArray *nextLevelCards = [self.cardIds objectAtIndex:nextLevel];
    
    // First do the remove
    NSInteger countBeforeRemove = [thisLevelCards count];
    NSInteger countBeforeAdd = [nextLevelCards count];

    // Now do the remove
    if ([thisLevelCards containsObject:cardId])
    {
      [thisLevelCards removeObject:cardId];
      NSInteger countAfterRemove = [thisLevelCards count];

      // Only do the add if remove was successful
      //LWE_ASSERT(countBeforeRemove == (countAfterRemove + 1));
      if (countBeforeRemove == (countAfterRemove + 1))
      {
        [nextLevelCards addObject:cardId];
      }
      NSInteger countAfterAdd = [[self.cardIds objectAtIndex:nextLevel] count];
      // Consistency checks
      LWE_ASSERT((countAfterRemove+1) == countBeforeRemove);
      LWE_ASSERT((countAfterAdd-1) == countBeforeAdd);
      LWE_LOG(@"Items in index to be removed: %d",countBeforeRemove);
      LWE_LOG(@"Items in index to be added: %d", countBeforeAdd);
      LWE_LOG(@"Items in removed: %d",countAfterRemove);
      LWE_LOG(@"Items in added: %d",countAfterAdd);
    }
    else
    {
      LWE_LOG(@"Card ID %d was not contained in the current tag's level cache for level %d - this is OK if you removed this card from the set!",card.cardId,card.levelId);
    }
    [self cacheCardLevelCounts];
  }
}


/**
 * Return how many Card objects are in this Tag
 */
- (NSInteger) cardCount
{ 
  return cardCount;
}


//! Setter for cardCount; updates the database cache automatically
- (void) setCardCount:(NSInteger)count
{
  // do nothing if its the same
  if (cardCount == count) return;
  
  // update the count in the database if not first load (e.g. cardCount = -1)
  if (cardCount >= 0)
  {
    LWEDatabase *db = [LWEDatabase sharedLWEDatabase];
    NSString *sql = [[NSString alloc] initWithFormat:@"UPDATE tags SET count = '%d' WHERE tag_id = '%d'",count,[self tagId]];
    [db.dao executeUpdate:sql];
    [sql release];
  }

  // set the variable to the new count
  cardCount = count; 
}


/**
 * Removes card from tag's memory arrays so they are out of the set
 */
- (void) removeCardFromActiveSet:(Card *)card
{
  NSNumber *tmpNum = [NSNumber numberWithInt:card.cardId];
  NSMutableArray* cardLevel = [self.cardIds objectAtIndex:card.levelId];
  [cardLevel removeObject:tmpNum];
  [[self combinedCardIdsForBrowseMode] removeObject:tmpNum];
  [self cacheCardLevelCounts];

  // This needs to be here to stop a double decrement!! (first decremented here, then in SQL in TagPeer)
  // SQL in TagPeer just uses Count=count-1, so it is "stupid" about what the actual count is
  [self setCardCount:cardCount+1];
}


/**
 * Add card to tag's memory arrays
 */
- (void) addCardToActiveSet:(Card *)card
{
  NSNumber *tmpNum = [NSNumber numberWithInt:card.cardId];
  NSMutableArray* cardLevel = [self.cardIds objectAtIndex:card.levelId];
  [cardLevel addObject:tmpNum];
  [[self combinedCardIdsForBrowseMode] addObject:tmpNum];
  [self cacheCardLevelCounts];
  
  // This needs to be here to stop a double increment!! (first incremented here, then in SQL in TagPeer)
  // SQL in TagPeer just uses Count=count+1, so it is "stupid" about what the actual count is
  [self setCardCount:cardCount-1];
}


// TODO: why does Tag care what mode we are in?  Seems fishy to me.
/** Gets first card in browse mode */
- (Card*) getFirstCard
{
  NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
  Card *card;
  if ([[settings objectForKey:APP_MODE] isEqualToString:SET_MODE_BROWSE])
  {
    // TODO: in some cases the currentIndex can be beyond the range.  We should figure out why, but for the time being I'll reset it to 0 instead of breaking
    if ([self currentIndex] >= [[self combinedCardIdsForBrowseMode] count])
    {
      [self setCurrentIndex:0];
    }
    NSNumber *cardId = [[self combinedCardIdsForBrowseMode] objectAtIndex:self.currentIndex];
    card = [CardPeer retrieveCardByPK:[cardId intValue]];
  }
  else
  {
    if ([settings integerForKey:@"card_id"] != 0)
    {
      card = [CardPeer retrieveCardByPK:[settings integerForKey:@"card_id"]];
      // We need to do this so that way this code knows to get a new card when loading 2nd or later set in one session
      [settings setInteger:0 forKey:@"card_id"];
    }
    else
    {
      card = [self getRandomCard:0];
    }
  }
  return card;
}


//! Concatenate cardId arrays for browse mode
- (NSMutableArray *) combineCardIds
{
  NSMutableArray* allCardIds = [[[NSMutableArray alloc] init] autorelease];
  NSMutableArray* cardIdsInLevel;
  for (cardIdsInLevel in self.cardIds) 
  {
    [allCardIds addObjectsFromArray:cardIdsInLevel];
  }
  [allCardIds sortUsingSelector:@selector(compare:)];
  return allCardIds;
}

/**
 * Returns the next card in the list, resets index if at the end of the list
 */
- (Card*) getNextCard
{
  NSMutableArray *allCardIds = [self combinedCardIdsForBrowseMode];
	NSInteger currIdx = self.currentIndex;
	NSInteger total = [allCardIds count];
	if (currIdx >= total - 1)
  {
    currIdx = 0;
  }
  else 
  {
    currIdx++;
  }

  self.currentIndex = currIdx;
  return [CardPeer retrieveCardByPK:[[allCardIds objectAtIndex:currIdx] intValue]];
}


/**
 * Returns the previous card in the list, resets index to top last card if at 0
 */
- (Card*) getPrevCard
{
  NSMutableArray *allCardIds = [self combinedCardIdsForBrowseMode];
	NSInteger currIdx = self.currentIndex;
	NSInteger total = [allCardIds count];
	if (currIdx == 0)
  {
    currIdx = total-1;
  }
  else
  {
    currIdx--;
  }
  
  self.currentIndex = currIdx;
  NSInteger tmp = [[allCardIds objectAtIndex:currIdx] intValue];
  return [CardPeer retrieveCardByPK:tmp];
}


//! takes a sqlite result set and populates the properties of Tag
- (void) hydrate: (FMResultSet*) rs
{
	[self setTagId:           [rs intForColumn:@"tag_id"]];
  [self setTagDescription:  [rs stringForColumn:@"description"]];
  [self setTagName:         [rs stringForColumn:@"tag_name"]];
  [self setTagEditable:     [rs intForColumn:@"editable"]];
  [self setCardCount:       [rs intForColumn:@"count"]];
}

- (void) dealloc
{
  [self setTagName:nil];
  [self setTagDescription:nil];
  [self setCombinedCardIdsForBrowseMode:nil];
  [self setCardLevelCounts:nil];
  [self setCardIds:nil];
	[super dealloc];
}

@end