//
//  Tag.m
//  jFlash
//
//  Created by Paul Chapman on 5/6/09.
//  Copyright 2009 LONG WEEKEND LLC. All rights reserved.
//

#import "Tag.h"
#import "FlurryAPI.h"

NSString * const kTagErrorDomain          = @"kTagErrorDomain";
NSUInteger const kAllBuriedAndHiddenError = 999;

@interface Tag ()
//Privates function
- (float)calculateProbabilityOfUnseenWithCardsSeen:(NSUInteger)cardsSeenTotal totalCards:(NSUInteger)totalCardsInSet numerator:(NSUInteger)numeratorTotal levelOneCards:(NSUInteger)levelOneTotal;
@end

@implementation Tag

@synthesize tagId, tagName, tagEditable, tagDescription, currentIndex, cardIds, cardLevelCounts, combinedCardIdsForBrowseMode, lastFiveCards;

- (id) init
{
  if ((self = [super init]))
  {
    cardCount = -1;
    self.currentIndex = 0;
    self.lastFiveCards = [NSMutableArray array];
  }
	return self;
}

/**
 * Gets the group for this tag and returns the id
 */
- (NSInteger) groupId
{
  LWEDatabase *db = [LWEDatabase sharedLWEDatabase];
	NSString *sql = [[NSString alloc] initWithFormat:@"SELECT group_id FROM group_tag_link WHERE tag_id = %d LIMIT 1",tagId];
	FMResultSet *rs = [[db dao] executeQuery:sql];
  NSInteger groupId = 0;
	while ([rs next]) 
  {
    groupId = [rs intForColumn:@"group_id"];
	}
	[rs close];
	[sql release];
  return groupId;
}

#pragma mark -
#pragma mark Level algorithm

/**
 * Calculates next card level based on current performance & Tag progress
 */
- (NSInteger)calculateNextCardLevelWithError:(NSError **)error
{
  //-----Internal array consistency-----
  LWE_ASSERT_EXC(([self.cardLevelCounts count] == 6),@"There must be 6 card levels (1-5 plus unseen cards)");
  //------------------------------------
  
  // control variables
  // controls how many words to show from new before preferring seen words
  NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
  int weightingFactor = [settings integerForKey:APP_FREQUENCY_MULTIPLIER];
  BOOL hideBuriedCard = [settings boolForKey:APP_HIDE_BURIED_CARDS];
  
  // Total number of cards in this set and its level
  int numLevels = 5, levelOneTotal = 0;
  int levelUnseenTotal = [[[self cardLevelCounts] objectAtIndex:0] intValue];
  int totalCardsInSet = [self cardCount];
  
  //if the hide burried cards is set to ON. Try to simulate with the decreased numLevels (hardcoded)
  //and also tell that the totalCardsInSet is no longer the whole sets but the one NOT in the buried section.
  if (hideBuriedCard)
  {
    numLevels = 4;
    NSUInteger totalCardsInBurried = [[self.cardLevelCounts objectAtIndex:5] intValue];
    totalCardsInSet = totalCardsInSet - totalCardsInBurried;
  }
  
  //special cases where this method can return without any math calculation.
  //the first one if highly unlikely there is less then 1 card in a set.
  //second one is if the entire set has not been "started". - return with 0.
  if (totalCardsInSet < 1)
  {
    if ((hideBuriedCard) && (error != NULL))
    {
      //if turns out all cards have been mastered and all are hidden.
      NSError *allCardsHidden = [NSError errorWithDomain:kTagErrorDomain code:kAllBuriedAndHiddenError userInfo:nil];
      *error = allCardsHidden;
    }
    return 0;
  }
  if (levelUnseenTotal == totalCardsInSet) return 0;
  
  // Get m cards in n bins, figure out total percentages
  // Calculate different of weights and percentages and adjust accordingly
  int i, tmpTotal = 0, denominatorTotal = 0, weightedTotal = 0, cardsSeenTotal = 0, numeratorTotal = 0;
  
  // the guts to get the total of card seen so far
  int tmpTotalArray[6];
  for (i = 1; i <= numLevels; i++)
  {
    // Get denominator values from cache/database
    tmpTotal = [[self.cardLevelCounts objectAtIndex:i] intValue];
    if (i == 1) levelOneTotal = tmpTotal;
    tmpTotalArray[i-1] = tmpTotal;
    cardsSeenTotal = cardsSeenTotal + tmpTotal;
    denominatorTotal = denominatorTotal + (tmpTotal * weightingFactor * (numLevels - i + 1)); 
    numeratorTotal = numeratorTotal + (tmpTotal * i);
  }
  
  float p_unseen = [self calculateProbabilityOfUnseenWithCardsSeen:cardsSeenTotal 
                                                        totalCards:totalCardsInSet
                                                         numerator:numeratorTotal 
                                                     levelOneCards:levelOneTotal];
  
  float randomNum = ((float)rand() / (float)RAND_MAX);
  float p = 0, pTotal = 0;
  //this for works like russian roulette where there is a 'randomNum' 
  //and each level has its own probability scaled 0-1 and if it sum-ed it would be 1.
  //this for enumerate through that level, accumulate the probability until it reach the 'randomNum'.
  for (i = 1; i <= numLevels; i++)
  {
    tmpTotal = tmpTotalArray[i-1];
    weightedTotal = (tmpTotal * weightingFactor * (numLevels - i + 1));
    p = ((float)weightedTotal / (float)denominatorTotal);
    p = (1-p_unseen)*p;
    pTotal = pTotal + p;
	  if (pTotal > randomNum)
    {
      LWE_LOG(@"[Debug]Next level will be: %d", i);
		  return i;
	  }
  }
  
  LWE_LOG(@"[Shoudlnt happen?]calculate next level will return with next level: %d", 0);
  return 0;
}

/**
 *  \brief  Calculate the probability of the unseen cards showing for the next 'round'
 *  \return The float ranged 0-1 for the probability of unseen card showing next.
 */
- (float)calculateProbabilityOfUnseenWithCardsSeen:(NSUInteger)cardsSeenTotal totalCards:(NSUInteger)totalCardsInSet numerator:(NSUInteger)numeratorTotal levelOneCards:(NSUInteger)levelOneTotal
{
  NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
  int wordsInStudyingBeforeTakingNewCard = [settings integerForKey:APP_MAX_STUDYING];
  int weightingFactor = [settings integerForKey:APP_FREQUENCY_MULTIPLIER];
  
  // Quick check to make sure we are not at the "end of a set". 
  if (cardsSeenTotal == totalCardsInSet)
  {
    return 0;
  }
  else if (cardsSeenTotal > totalCardsInSet) // error check
  {
    // This should not happen, it is likely that we need to re-cache TotalCards
    LWE_LOG(@"CardTotal became more than totalCards... (%d, %d)", cardsSeenTotal, totalCardsInSet);
    return 0;
  }
  else
  {
    // Sets probability if we have less cards in the study pool than MAX allowed
    if (levelOneTotal < wordsInStudyingBeforeTakingNewCard && (totalCardsInSet - cardsSeenTotal) > 0)
    {
      float p_unseen = 0, mean = 0;
      mean = (float)numeratorTotal / (float)cardsSeenTotal;
      p_unseen = (mean - (float)1);
      p_unseen = pow((p_unseen / (float) 4), weightingFactor);
      p_unseen = p_unseen + (1-p_unseen)*(pow((wordsInStudyingBeforeTakingNewCard - cardsSeenTotal),.25)/pow(wordsInStudyingBeforeTakingNewCard,.25));
      return p_unseen;
    }
    else if (levelOneTotal >= wordsInStudyingBeforeTakingNewCard)
    {
      return 0;
    }
    
    //Should't happen?
    LWE_LOG_ERROR(@"Is there ever a case where this is NO?  If so, we want to know what case!");
  }
  return CGFLOAT_MAX;
}

#pragma mark -

//! Create a cache of the number of Card objects in each level
- (void) cacheCardLevelCounts
{
  //-----Internal array consistency-----
  LWE_ASSERT_EXC(([self.cardIds count] == 6),@"Must be six card level arrays");
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
- (Card*) getRandomCard:(NSInteger)currentCardId error:(NSError **)error
{
  //-----Internal array consistency-----
#if defined(LWE_RELEASE_APP_STORE)
  if ([self.cardIds count] != 6)
  {
    [FlurryAPI logError:@"getRandomCard" message:[NSString stringWithFormat:@"cardIds has %d indicies, not 6",[self.cardIds count]] error:nil];
  }
#else
  LWE_ASSERT_EXC(([self.cardIds count] == 6),@"Card IDs must have 6 array levels");
#endif
  //------------------------------------  
  
  // determine the next level
  NSError *theError = nil;
  NSInteger next_level = [self calculateNextCardLevelWithError:&theError];
  if ((next_level == 0) && ([theError domain] == kTagErrorDomain) && ([theError code] == kAllBuriedAndHiddenError))
  {
    if (error != NULL) *error = theError;
    return nil;
  }
  
  // Get a random card offset
  NSInteger numCardsAtLevel = [[self.cardIds objectAtIndex:next_level] count];
  NSInteger randomOffset = 0;
  
  LWE_ASSERT_EXC((numCardsAtLevel > 0),@"We've been asked for cards at level %d but there aren't any.",next_level);
  
  if (numCardsAtLevel > 0)
  {
    randomOffset = arc4random() % numCardsAtLevel;
  }

  NSNumber* cardId;
  
  NSMutableArray* cardIdArray = [self.cardIds objectAtIndex:next_level];
  cardId = [cardIdArray objectAtIndex:randomOffset];
  
  // this is a simple queue of the last five cards
  [self.lastFiveCards addObject:[NSNumber numberWithInt:currentCardId]];
  
  if ([self.lastFiveCards count] == NUM_CARDS_IN_NOT_NEXT_QUEUE)
  {
    [self.lastFiveCards removeObjectAtIndex:0];
  }

  // prevent getting the same card twice.
  int i = 0; // counts how many times we whiled against the array
  int j = 0; // second iterator to count tries that return the same card as before
  while([self.lastFiveCards containsObject:cardId])
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
        next_level = [self calculateNextCardLevelWithError:nil];
        if (next_level != lastNextLevel) break;
      }
    }
    // now get a different card randomly
    cardIdArray = [self.cardIds objectAtIndex:next_level];
    int numCardsAtLevel2 = [[self.cardIds objectAtIndex:next_level] count];
    LWE_ASSERT_EXC((numCardsAtLevel2 > 0),@"We've been asked for cards at level %d but there aren't any.",next_level);
    if (numCardsAtLevel2 > 0)
    {
      randomOffset = arc4random() % numCardsAtLevel2;
    }
    cardId = [cardIdArray objectAtIndex:randomOffset];      
    
    i++;
    if (i > 3)
    {
      // the same card is worse than a card that was twice ago, so we check again that it's not that
      if (j == 3 || currentCardId != [cardId intValue]) 
      {
        break; //we tried 5 times, fuck it
      }
      j++;
    }
  }
  return [CardPeer retrieveCardByPK:[cardId intValue]];
}

/**
 * Update level counts cache - (kept in memory how many cards are in each level)
 */
- (void) updateLevelCounts:(Card*) card nextLevel:(NSInteger) nextLevel
{
  //-----Internal array consistency-----
#if defined(LWE_RELEASE_APP_STORE)
  if ([self.cardIds count] != 6)
  {
    [FlurryAPI logError:@"updateLevelCounts" message:@"currentCardId is nil" error:nil];
  }
#else
  LWE_ASSERT_EXC(([self.cardIds count] == 6),@"Must be 6 arrays in cardIds");
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
      LWE_ASSERT_EXC(((countAfterRemove+1) == countBeforeRemove),@"The number after remove (%d) should be 1 less than count before remove (%d)",countAfterRemove,countBeforeRemove);
      LWE_ASSERT_EXC(((countAfterAdd-1) == countBeforeAdd),@"The number after add (%d) should be 1 more than the count before add (%d)",countAfterAdd,countBeforeAdd);
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
}

/** 
 *  \brief  Gets first card in browse mode or in a study mode.
 */
- (Card *)getFirstCardWithError:(NSError **)error
{
  // TODO: why does Tag care what mode we are in?  Seems fishy to me.
  NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
  Card *card;
  if ([[settings objectForKey:APP_MODE] isEqualToString:SET_MODE_BROWSE])
  {
    // TODO: in some cases the currentIndex can be beyond the range.  
    // We should figure out why, but for the time being I'll reset it to 0 instead of breaking
    if ([self currentIndex] >= [[self combinedCardIdsForBrowseMode] count])
    {
      [self setCurrentIndex:0];
    }
    
    NSArray *combinedCards = [self combinedCardIdsForBrowseMode];
    NSNumber *cardId = nil;
    if ([combinedCards count] > 0)
    {
      cardId = [combinedCards objectAtIndex:self.currentIndex];
    }
    else
    {
      cardId = [NSNumber numberWithInt:0];
    }
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
      NSError *theError = nil;
      card = [self getRandomCard:0 error:&theError];
      if ((card == nil) && ([theError code] == kAllBuriedAndHiddenError) && (error != NULL))
      {
        LWE_LOG(@"Someone asks for a first card in a set: %@.\nHowever, the user have already mastered this study set, ask the user for a solution.", self);
        *error = theError;
      }
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
  [self setLastFiveCards:nil];
	[super dealloc];
}

- (BOOL)isEqual:(id)object
{
  if ([object isKindOfClass:[self class]])
  {
    Tag *anotherTag = (Tag *)object;
    return [anotherTag tagId] == [self tagId];
  }
  return NO;
}

#pragma mark -
#pragma mark Description

- (NSString *)description
{
  return [NSString stringWithFormat:@"<%@: 0x%0X>\n\
          Tag Editable: %d\n\
          Tag Name: %@\n\
          Tag Description: %@\n\
          Tag Id: %d\n\
          Current Index: %d\n\
          CardIds: %@",
          NSStringFromClass([self class]),
          self, 
          [self tagEditable],
          [self tagName],
          [self tagDescription],
          [self tagId],
          [self currentIndex],
          [self cardIds]];
}


@end