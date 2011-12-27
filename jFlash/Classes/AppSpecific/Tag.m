//
//  Tag.m
//  jFlash
//
//  Created by Paul Chapman on 5/6/09.
//  Copyright 2009 LONG WEEKEND LLC. All rights reserved.
//

#import "Tag.h"
#import "FlurryAPI.h"
#import "LWEDebug.h"

NSString * const kTagErrorDomain          = @"kTagErrorDomain";
NSString * const LWETagDidSave = @"kTagDidSave";
NSUInteger const kAllBuriedAndHiddenError = 999;
NSUInteger const kLWETagUnknownError = 998;
NSInteger const kLWEUninitializedTagId = -1;
NSInteger const kLWEUninitializedCardCount = -1;
NSInteger const kLWEUnseenCardLevel = 0;
NSInteger const kLWELearnedCardLevel = 5;

#define kLWETimesToRetryForNonRecentCardId 3

@interface Tag ()
//Privates function
- (float)calculateProbabilityOfUnseenWithCardsSeen:(NSUInteger)cardsSeenTotal totalCards:(NSUInteger)totalCardsInSet numerator:(NSUInteger)numeratorTotal levelOneCards:(NSUInteger)levelOneTotal;
@end

@implementation Tag

@synthesize tagId, tagName, tagEditable, tagDescription, isFault = _isFault;
@synthesize cardCount, currentIndex, cardIds, cardLevelCounts, flattenedCardIdArray, lastFiveCards;

+ (Tag *) starredWordsTag
{
  return [TagPeer retrieveTagById:STARRED_TAG_ID];
}

+ (Tag *) blankTagWithId:(NSInteger)tagId
{
  Tag *tag = [[[[self class] alloc] init] autorelease];
  tag.tagId = tagId;
  return tag;
}

- (id) init
{
  if ((self = [super init]))
  {
    _isFault = YES;
    self.tagId = kLWEUninitializedTagId;
    cardCount = kLWEUninitializedCardCount; // don't use setter here, has special behavior of updating DB 
    self.lastFiveCards = [NSMutableArray array];
  }
	return self;
}


/**
 * Gets the group for this tag and returns the id
 */
- (NSInteger) groupId
{
  // TODO: all of this makes the assumption that tags are 1-1 with groups.  that was not the 
  // original design, but are we moving that direction?  MMA - Oct 19 2011
  return [GroupPeer parentGroupIdOfTag:self];
}

- (BOOL) isEditable
{
  return (self.tagEditable == 1);
}

#pragma mark - Level algorithm

/**
 * Calculates next card level based on current performance & Tag progress
 */
- (NSInteger)calculateNextCardLevelWithError:(NSError **)error
{
  LWE_ASSERT_EXC(([self.cardLevelCounts count] == 6),@"There must be 6 card levels (1-5 plus unseen cards)");
  
  // control variables
  // controls how many words to show from new before preferring seen words
  NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
  NSInteger weightingFactor = [settings integerForKey:APP_FREQUENCY_MULTIPLIER];
  BOOL hideLearnedCards = [settings boolForKey:APP_HIDE_BURIED_CARDS];
  
  // Total number of cards in this set and its level
  NSInteger numLevels = 5;
  NSInteger unseenCount = [[self.cardLevelCounts objectAtIndex:kLWEUnseenCardLevel] intValue];
  NSInteger totalCardsInSet = self.cardCount;
  
  // This is a quick return case; if all cards are unseen, just return that
  if (unseenCount == totalCardsInSet)
  {
    return kLWEUnseenCardLevel;
  }

  //if the hide learned cards is set to ON. Try to simulate with the decreased numLevels (hardcoded)
  //and also tell that the totalCardsInSet is no longer the whole sets but the ones NOT in the buried section.
  if (hideLearnedCards)
  {
    // In this mode, we don't have 5 levels, we have four.
    numLevels = 4;
    
    // If all cards are learned, return "Learned" along with an error
    NSInteger learnedCount = [[self.cardLevelCounts objectAtIndex:kLWELearnedCardLevel] intValue];
    totalCardsInSet = totalCardsInSet - learnedCount;
    if ((totalCardsInSet == 0) && (learnedCount > 0))
    {
      if (error != NULL)
      {
        *error = [NSError errorWithDomain:kTagErrorDomain code:kAllBuriedAndHiddenError userInfo:nil];
      }
      return kLWELearnedCardLevel;
    }
  }
  
  LWE_ASSERT_EXC(totalCardsInSet > 0, @"Beyond this point we assume we have some cards!");
  
  // Get m cards in n bins, figure out total percentages
  // Calculate different of weights and percentages and adjust accordingly
  NSInteger denominatorTotal = 0, weightedTotal = 0, cardsSeenTotal = 0, numeratorTotal = 0;
  
  // the guts to get the total of card seen so far
  NSInteger totalArray[6];
  for (NSInteger levelId = 1; levelId <= numLevels; levelId++)
  {
    // Get denominator values from cache/database
    NSInteger tmpTotal = [[self.cardLevelCounts objectAtIndex:levelId] intValue];
    totalArray[levelId-1] = tmpTotal;   // all the level references (& the math) are 1-indexed, the array is 0 indexed
    cardsSeenTotal = cardsSeenTotal + tmpTotal;
    denominatorTotal = denominatorTotal + (tmpTotal * weightingFactor * (numLevels - levelId + 1)); 
    numeratorTotal = numeratorTotal + (tmpTotal * levelId);
  }
  
  float p_unseen = [self calculateProbabilityOfUnseenWithCardsSeen:cardsSeenTotal 
                                                        totalCards:totalCardsInSet
                                                         numerator:numeratorTotal 
                                                     levelOneCards:totalArray[0]];
  
  CGFloat randomNum = ((float)rand() / (float)RAND_MAX);
  CGFloat p = 0, pTotal = 0;
  //this for works like russian roulette where there is a 'randomNum' 
  //and each level has its own probability scaled 0-1 and if it sum-ed it would be 1.
  //this for enumerate through that level, accumulate the probability until it reach the 'randomNum'.
  for (NSInteger levelId = 1; levelId <= numLevels; levelId++)
  {
    // For this array, the levels are 0-indexed, so we have to minus one (see above)
    weightedTotal = (totalArray[levelId-1] * weightingFactor * (numLevels - levelId + 1));
    p = ((CGFloat)weightedTotal / (CGFloat)denominatorTotal);
    p = (1 - p_unseen) * p;
    pTotal = pTotal + p;
	  if (pTotal > randomNum)
    {
		  return levelId;
	  }
  }
  
  // If we get here, that would be an error (we should return in the above for loop) -- fail with level unseen
  if (error != NULL)
  {
    *error = [NSError errorWithDomain:kTagErrorDomain code:kLWETagUnknownError userInfo:nil];
  }
  return kLWEUnseenCardLevel;
}

/**
 *  \brief  Calculate the probability of the unseen cards showing for the next 'round'
 *  \return The float ranged 0-1 for the probability of unseen card showing next.
 */
- (float)calculateProbabilityOfUnseenWithCardsSeen:(NSUInteger)cardsSeenTotal totalCards:(NSUInteger)totalCardsInSet numerator:(NSUInteger)numeratorTotal levelOneCards:(NSUInteger)levelOneTotal
{
  NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
  NSInteger maxCardsToStudy = [settings integerForKey:APP_MAX_STUDYING];
  NSInteger weightingFactor = [settings integerForKey:APP_FREQUENCY_MULTIPLIER];
  LWE_ASSERT_EXC((maxCardsToStudy > 0), @"This value must be non-zero");
  LWE_ASSERT_EXC((weightingFactor > 0), @"This value must be non-zero");
  
  // Quick return of 0 probability if we've already seen all the cards in a set, or aren't taking any more
  if ((cardsSeenTotal == totalCardsInSet) || (levelOneTotal >= maxCardsToStudy))
  {
    return 0;
  }
  else
  {
    LWE_ASSERT_EXC((cardsSeenTotal < totalCardsInSet), @"To get to this point, there should be more cards in the set than cards seen");
    
    // Sets probability if we have less cards in the study pool than MAX allowed
    CGFloat p_unseen = 0, mean = 0;
    mean = (CGFloat)numeratorTotal / (CGFloat)cardsSeenTotal;
    p_unseen = (mean - 1.0f);
    p_unseen = pow((p_unseen / 4.0f), weightingFactor);
    p_unseen = p_unseen + (1.0f - p_unseen)*(pow((maxCardsToStudy - cardsSeenTotal),0.25)/pow(maxCardsToStudy,0.25));
    return p_unseen;
  }
}

#pragma mark - Prep Card Ids, Deal with Card Ids

//! Create a cache of the number of Card objects in each level
- (void) recacheCardCountForEachLevel
{
  LWE_ASSERT_EXC(([self.cardIds count] == 6),@"Must be six card level arrays");

  NSNumber *count = nil;
  NSInteger totalCount = 0;
  NSMutableArray *cardLevelCountsTmp = [NSMutableArray array];
  for (NSInteger i = 0; i < 6; i++)
  {
    count = [NSNumber numberWithInt:[[self.cardIds objectAtIndex:i] count]];
    [cardLevelCountsTmp addObject:count];
    totalCount = totalCount + [count intValue];
  }
  self.cardLevelCounts = cardLevelCountsTmp;
  self.cardCount = totalCount;
}


/** Unarchive plist file containing the user's last session data */
- (NSArray *) thawCardIds
{
  NSString *path = [LWEFile createCachesPathWithFilename:@"ids.plist"];
  return [NSArray arrayWithContentsOfFile:path];
}


/** Archive current session data to a plist so we can re-start at same place in next session */
- (void) freezeCardIds
{
  NSString *path = [LWEFile createCachesPathWithFilename:@"ids.plist"];
  [self.cardIds writeToFile:path atomically:YES];
}


/** Executed when loading a new set on app load */
- (void) populateCardIds
{
  NSArray *tmpCardIdsArray = [self thawCardIds];
  if (tmpCardIdsArray)
  {
    // Delete the PLIST now that we have it in memory
    [LWEFile deleteFile:[LWEFile createCachesPathWithFilename:@"ids.plist"]];
  }
  else
  {
    // No PLIST, generate new card Ids array
    tmpCardIdsArray = [CardPeer retrieveCardIdsSortedByLevelForTag:self];
  }
  
  self.cardIds = [[tmpCardIdsArray mutableCopy] autorelease];
  self.flattenedCardIdArray = [self combineCardIds];

  // populate the card level counts
	[self recacheCardCountForEachLevel];
}

//! Concatenate cardId arrays for browse mode
- (NSMutableArray *)combineCardIds
{
  NSMutableArray *allCardIds = [NSMutableArray arrayWithCapacity:self.cardCount];
  for (NSArray *cardIdsInLevel in self.cardIds) 
  {
    [allCardIds addObjectsFromArray:cardIdsInLevel];
  }
  [allCardIds sortUsingSelector:@selector(compare:)];
  return allCardIds;
}


/**
 * Update level counts cache - (kept in memory how many cards are in each level)
 */
- (void) moveCard:(Card*)card toLevel:(NSInteger) nextLevel
{
  LWE_ASSERT_EXC(([self.cardIds count] == 6),@"Must be 6 arrays in cardIds");
  
  // update the cardIds if necessary
  if (nextLevel != card.levelId)
  {
    NSNumber *cardId = [NSNumber numberWithInt:card.cardId];

    NSMutableArray *thisLevelCards = [self.cardIds objectAtIndex:card.levelId];
    NSMutableArray *nextLevelCards = [self.cardIds objectAtIndex:nextLevel];
    
    NSInteger countBeforeRemove = [thisLevelCards count];
    NSInteger countBeforeAdd = [nextLevelCards count];

    // Now do the remove
    LWE_ASSERT_EXC([thisLevelCards containsObject:cardId], @"Can't remove the card, it's no longer there!");
    [thisLevelCards removeObject:cardId];
    NSInteger countAfterRemove = [thisLevelCards count];

    // Only do the add if remove was successful
    if (countBeforeRemove == (countAfterRemove + 1))
    {
      [nextLevelCards addObject:cardId];
      
      // Now confirm the add
      NSInteger countAfterAdd = [[self.cardIds objectAtIndex:nextLevel] count];
      LWE_ASSERT_EXC(((countAfterAdd-1) == countBeforeAdd),@"The number after add (%d) should be 1 more than the count before add (%d)",countAfterAdd,countBeforeAdd);

      [self recacheCardCountForEachLevel];
    }
  }
}

#pragma mark - Custom Getter & Setter - Card Count

- (NSInteger) cardCount
{
  return cardCount;
}

//! Setter for cardCount; updates the database cache automatically
- (void) setCardCount:(NSInteger)newCount
{
  NSInteger currentCount = cardCount;
  if (currentCount == newCount)
  {
    // do nothing if its the same
   return;
  }
  
  // update the count in the database if not first load (e.g. cardCount = -1)
  if (currentCount >= 0)
  {
    [TagPeer setCardCount:newCount forTag:self];
  }

  // set the variable to the new count - do this directly to bypass this setter!
  cardCount = newCount; 
}

#pragma mark - Add & Remove Cards From the Tag

/**
 * Removes card from tag's memory arrays so they are out of the set
 */
- (void) removeCardFromActiveSet:(Card *)card
{
  NSNumber *tmpNum = [NSNumber numberWithInt:card.cardId];
  NSMutableArray *cardLevel = [self.cardIds objectAtIndex:card.levelId];
  [cardLevel removeObject:tmpNum];
  [self.flattenedCardIdArray removeObject:tmpNum];
  [self recacheCardCountForEachLevel];
}

/**
 * Add card to tag's memory arrays
 */
- (void) addCardToActiveSet:(Card *)card
{
  NSNumber *tmpNum = [NSNumber numberWithInt:card.cardId];
  NSMutableArray *cardLevel = [self.cardIds objectAtIndex:card.levelId];
  [cardLevel addObject:tmpNum];
  [self.flattenedCardIdArray addObject:tmpNum];
  [self recacheCardCountForEachLevel];
}

#pragma mark - Get Cards

/**
 * Returns a Card object from the database randomly
 * Accepts current cardId in an attempt to not return the last card again
 */
- (Card*) getRandomCard:(NSInteger)currentCardId error:(NSError **)error
{
  LWE_ASSERT_EXC(([self.cardIds count] == 6),@"Card IDs must have 6 array levels");
  
  // determine the next level
  NSError *theError = nil;
  NSInteger next_level = [self calculateNextCardLevelWithError:&theError];
  if ((next_level == kLWELearnedCardLevel) && (theError.domain == kTagErrorDomain) && (theError.code == kAllBuriedAndHiddenError))
  {
    if (error != NULL) *error = theError;
  }
  
  // Get a random card offset
  NSInteger numCardsAtLevel = [[self.cardIds objectAtIndex:next_level] count];
  NSInteger randomOffset = 0;
  
  LWE_ASSERT_EXC((numCardsAtLevel > 0),@"We've been asked for cards at level %d but there aren't any.",next_level);
  if (numCardsAtLevel > 0)
  {
    randomOffset = arc4random() % numCardsAtLevel;
  }
  
  NSMutableArray *cardIdArray = [self.cardIds objectAtIndex:next_level];
  NSNumber *cardId = [cardIdArray objectAtIndex:randomOffset];
  
  // this is a simple queue of the last five cards
  [self.lastFiveCards addObject:[NSNumber numberWithInt:currentCardId]];
  
  if ([self.lastFiveCards count] == NUM_CARDS_IN_NOT_NEXT_QUEUE)
  {
    [self.lastFiveCards removeObjectAtIndex:0];
  }
  
  // prevent getting the same card twice.
  NSInteger i = 0; // counts how many times we whiled against the array
  NSInteger j = 0; // second iterator to count tries that return the same card as before
  while ([self.lastFiveCards containsObject:cardId])
  {
    LWE_LOG(@"Got the same card as last time");
    // If there is only one card left (this card) in the level, let's get a different level
    
    if (numCardsAtLevel == 1)
    {
      LWE_LOG(@"Only one card left in this level, getting a new level");
      // Try up five times to get a different level
      NSInteger lastNextLevel = next_level;
      for (NSInteger j = 0; j < 5; j++)
      {
        next_level = [self calculateNextCardLevelWithError:nil];
        if (next_level != lastNextLevel) break;
      }
    }
    // now get a different card randomly
    cardIdArray = [self.cardIds objectAtIndex:next_level];
    NSInteger numCardsAtLevel2 = [[self.cardIds objectAtIndex:next_level] count];
    LWE_ASSERT_EXC((numCardsAtLevel2 > 0),@"We've been asked for cards at level %d but there aren't any.",next_level);
    if (numCardsAtLevel2 > 0)
    {
      randomOffset = arc4random() % numCardsAtLevel2;
    }
    cardId = [cardIdArray objectAtIndex:randomOffset];      
    
    i++;
    if (i > kLWETimesToRetryForNonRecentCardId)
    {
      // the same card is worse than a card that was twice ago, so we check again that it's not that
      if (j == kLWETimesToRetryForNonRecentCardId || currentCardId != [cardId intValue]) 
      {
        break; //we tried 3 times, fuck it
      }
      j++;
    }
  }
  return [CardPeer retrieveCardByPK:[cardId intValue]];
}

#pragma mark - Database Related

//! Saves the tag to the DB. WARNING: this only updates the tags basic info, creation is handled in TagPeer for historical reasons.
// TODO: Should likely be refactored to work as a save method instead of TagPeer creation.
- (void) save
{
  LWE_ASSERT_EXC((self.tagId != kLWEUninitializedTagId),@"The tag must already exist to be saved, use createTagNamed in TagPeer to create a tag");
  LWEDatabase *db = [LWEDatabase sharedLWEDatabase];
  BOOL success = [db.dao executeUpdate:@"UPDATE tags SET tag_name = ?, description = ? WHERE tag_id = ?",self.tagName,self.tagDescription,[NSNumber numberWithInt:self.tagId]];
  if (success)
  {
    [[NSNotificationCenter defaultCenter] postNotificationName:LWETagDidSave object:self];
  }
}

//! Refreshes self from the DB if a didSave notification is called
- (void)tagDidSave:(NSNotification *)notification
{
  if ([self isEqual:notification.object] && (self.isFault == NO)) // we only care if it's us & this isn't a faulted entry
  {
    [self hydrate];
  }
}

//! gets a tags info from the db and hydrates
- (void) hydrate
{
  LWE_ASSERT_EXC(self.tagId != kLWEUninitializedTagId, @"Hydrate called with uninitialized tag ID");
  LWEDatabase *db = [LWEDatabase sharedLWEDatabase];
	FMResultSet *rs = [db.dao executeQuery:@"SELECT * FROM tags WHERE tag_id = ? LIMIT 1",[NSNumber numberWithInt:self.tagId]];
	while ([rs next])
  {
		[self hydrate:rs];
	}
	[rs close];
}

//! takes a sqlite result set and populates the properties of Tag
- (void) hydrate: (FMResultSet *) rs
{
  self.tagId = [rs intForColumn:@"tag_id"];
  self.tagDescription = [rs stringForColumn:@"description"];
  self.tagName = [rs stringForColumn:@"tag_name"];
  self.tagEditable = [rs intForColumn:@"editable"];
  self.cardCount = [rs intForColumn:@"count"];
  
  // We only care about getting new updates on data if we had data to begin with.
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tagDidSave:) name:LWETagDidSave object:nil];
  _isFault = NO;
}

#pragma mark - Class Plumbing

- (void) dealloc
{
  if (self.isFault == NO)
  {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
  }
  [tagName release];
  [tagDescription release];
  [flattenedCardIdArray release];
  [cardLevelCounts release];
  [cardIds release];
  [lastFiveCards release];
	[super dealloc];
}

#pragma mark - NSObject Protocol

- (BOOL)isEqual:(id)object
{
  if ([object isKindOfClass:[self class]])
  {
    Tag *anotherTag = (Tag *)object;
    return (anotherTag.tagId == self.tagId);
  }
  return NO;
}

#pragma mark - Description

- (NSString *)description
{
  return [NSString stringWithFormat:@"<%@: 0x%0X>\n\
          Editable: %d\n\
          Name: %@\n\
          Description: %@\n\
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