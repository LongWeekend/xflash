//
//  CardPeerProxy.m
//  jFlash
//
//  Created by シャロット ロス on 2/7/10.
//  Copyright 2010 LONG WEEKEND INC.. All rights reserved.
//

#import "CardPeerProxy.h"

@implementation CardPeerProxy
@synthesize recentCards, cardCache, locked, unseenCache, tagId, userId, cardCount, cardLevelCounts; 

- (id) init
{
  tagId = 0;
  userId = 0;
  unseenCache = nil;
  locked = NO;
  NSMutableArray *tmpRecentSet = [[NSMutableArray alloc] init];
  NSMutableArray *tmpCardCache = [[NSMutableArray alloc] init];
  NSMutableArray *tmpLevelCounts = [[NSMutableArray alloc] init];
  Card *tmpCard = nil;
  for (int k = 0; k < 6; k++)
  {
    tmpCard = [[Card alloc] init];
    [tmpCardCache addObject:tmpCard];
    [tmpCard release];
  }
  [self setCardLevelCounts:tmpLevelCounts];
  [self setRecentCards: tmpRecentSet];
  [self setCardCache: tmpCardCache];
  [tmpLevelCounts release];
  [tmpCardCache release];
  [tmpRecentSet release];  
  return self;
}

//--------------------------------------------------------------------------
// Card* getRandomCard
//--------------------------------------------------------------------------
- (Card*) getRandomCard
{
  int next_level = [self calculateNextCardLevel];
  Card* tmpCard = [self retrieveCardForLevel:next_level];
  return tmpCard;
}


//--------------------------------------------------------------------------
// void cacheCardLevelCounts
// Caches the number of cards in each level
//--------------------------------------------------------------------------
- (void) cacheCardLevelCounts
{
  int j;
  NSNumber *count;
	for (int i = 0; i < 6; i++)
  {
    j = [CardPeer retrieveCardCountByLevel:tagId levelId:i];
	  count = [[NSNumber alloc] initWithInt:j];
	  [[self cardLevelCounts] addObject:count];
	  [count release];
  }
}

- (NSMutableArray*) cacheCardLevelCountsWithCards:(NSMutableArray*) cards
{
  int total = [cards count];
  NSLog(@"START w %d cards",total);
  int l1 = 0,l2 = 0 ,l3 = 0 ,l4 = 0,l5 = 0;
  for (int j = 0; j < total; j++)
  {
    switch ([[cards objectAtIndex:j] levelId])
    {
      case 1:
        l1++;
        break;
      case 2:
        l2++;
        break;
      case 3:
        l3++;
        break;
      case 4:
        l4++;
        break;
      case 5:
        l5++;
        break;        
    }
  }
  int leftover = total - l1 - l2 - l3 - l4 - l5;
  NSLog(@"1-%d 2-%d 3-%d 4-%d 5-%d leftover-%d",l1,l2,l3,l4,l5,leftover);
  
  NSNumber* count0 = [[NSNumber alloc] initWithInt:leftover];
  NSNumber* count1 = [[NSNumber alloc] initWithInt:l1];
  NSNumber* count2 = [[NSNumber alloc] initWithInt:l2];
  NSNumber* count3 = [[NSNumber alloc] initWithInt:l3];
  NSNumber* count4 = [[NSNumber alloc] initWithInt:l4];
  NSNumber* count5 = [[NSNumber alloc] initWithInt:l5];
  
  [[self cardLevelCounts] addObject:count0];
  [[self cardLevelCounts] addObject:count1];
  [[self cardLevelCounts] addObject:count2];
  [[self cardLevelCounts] addObject:count3];
  [[self cardLevelCounts] addObject:count4];
  [[self cardLevelCounts] addObject:count5];
  
  [count0 release];
  [count1 release];
  [count2 release];
  [count3 release];
  [count4 release];
  [count5 release];
  NSLog(@"DONE");
  return [self cardLevelCounts];
}


//--------------------------------------------------------------------------
// void replenishUnseenCache
// Caches the next 40 unseen cards
//--------------------------------------------------------------------------
- (void) replenishUnseenCache
{
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];    
  locked = YES;
  [self setUnseenCache:[CardPeer retrieveUnseenCards:40 setId:[self tagId]]];
  locked = NO;
  [pool release];
}


//--------------------------------------------------------------------------
// void replenishCardCacheForLevel
// Caches the next card at each level
//--------------------------------------------------------------------------
- (void) replenishCardCacheForLevel: (NSNumber*)levelId
{
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  // Get a random card offset
  int randomOffset = (int)([[[self cardLevelCounts] objectAtIndex:[levelId intValue]] intValue] * ((float)rand() / (float)RAND_MAX));
  int lclLevelId = [levelId intValue];
  Card *tmpCard = [CardPeer retrieveCardByLevel:lclLevelId setId:[self tagId] withRandom:randomOffset];
  if (tmpCard)
  {
    [cardCache replaceObjectAtIndex:lclLevelId withObject:tmpCard];
  }
  [pool release];
}
//--------------------------------------------------------------------------


//--------------------------------------------------------------------------
// Card retrieveCardForLevelNull
// Gets unseen cards (potentially from cache)
//--------------------------------------------------------------------------
- (Card*) retrieveCardForLevelNull: (NSInteger) randomOffset
{
  Card* returnCard = nil;
  if (unseenCache != nil && [unseenCache count] > 0)
  {
    NSLog(@"Taking a card off the unseen cache");
    returnCard = [unseenCache objectAtIndex:0];
    [returnCard retain];
    [unseenCache removeObjectAtIndex:0];
    if ([unseenCache count] < 8 && locked == NO)
    {
      // Need to refresh the cache
      NSLog(@"Unseen cache has %d objects, refreshing",[unseenCache count]);
      [self performSelectorInBackground:@selector(replenishUnseenCache) withObject:nil];
    }
  }
  else
  {
    // Get unseen card manually then set off the refresh for the cache
    returnCard = [CardPeer retrieveCardByLevel:0 setId:self.tagId withRandom:randomOffset];
    NSLog(@"Unseen cache has %d objects, refreshing",[self.unseenCache count]);
    if (locked == NO)
    {
      [self performSelectorInBackground:@selector(replenishUnseenCache) withObject:nil];
    }
  }
  return returnCard;  
}
//--------------------------------------------------------------------------


//--------------------------------------------------------------------------
// Card retrieveCardForLevel
// Local call to CardPeer, allows for caching of cards w/o DB hit
//--------------------------------------------------------------------------
- (Card*) retrieveCardForLevel: (NSInteger)levelId
{
  // Get a random card offset
  int randomOffset = (int)([[[self cardLevelCounts] objectAtIndex:levelId] intValue] * ((float)rand() / (float)RAND_MAX));
  Card* returnCard = nil;

  // First, determine whether or not we should use caching system
  // TODO constant-ify
  if (cardCount < 100)
  {
    LWE_LOG(@"Small set no caching");
    return [CardPeer retrieveCardByLevel:levelId setId:[self tagId] withRandom:randomOffset];
  }
    
  // Take off the unseen cache
  if (levelId == 0)
  {
    returnCard = [self retrieveCardForLevelNull:randomOffset];
  }
  else
  {
    int i = 0;
    // First, ensure cache exists
    if ([[cardCache objectAtIndex:levelId] cardId] == 0)
    {
      while (returnCard == nil && i < 5)
      {
        LWE_LOG(@"DECIDED TO RETRIEVE SINGLE CARD - NO CACHING");
        returnCard = [CardPeer retrieveCardByLevel:levelId setId:[self tagId] withRandom:randomOffset];
        i++;
      }
    }
    else
    {
      LWE_LOG(@"TAKING CACHED CARD FOR LEVEL %d",levelId);
      returnCard = [[self cardCache] objectAtIndex:levelId];
    }
    // Now fire off a thread to get that guy going
    [self performSelectorInBackground:@selector(replenishCardCacheForLevel:) withObject:(id)[NSNumber numberWithInt:levelId]];
  }
  return returnCard;
}
//--------------------------------------------------------------------------

- (void) updateLevelCounts:(Card*)card nextLevel:(NSInteger)nextLevel
{
  if (cardLevelCounts == nil)
  {
    return;
  }
  // Nothing to change
  if (nextLevel == card.levelId)
  {
    return;
  }
  
  // Handle null case
  //  if (card.levelId == ) card.levelId = 0;
  // Handle decrement
  NSNumber *decrementLevel = [cardLevelCounts objectAtIndex:(int)card.levelId];
  decrementLevel = [NSNumber numberWithInt:([decrementLevel intValue]-1)];
  [cardLevelCounts replaceObjectAtIndex:(int)card.levelId withObject:decrementLevel];
  // Handle increment.
  NSNumber *incrementLevel = [cardLevelCounts objectAtIndex:nextLevel];
  incrementLevel = [NSNumber numberWithInt:([incrementLevel intValue]+1)];
  [cardLevelCounts replaceObjectAtIndex:nextLevel withObject:incrementLevel];
  return;
}


//--------------------------------------------------------------------------
// saveCardCountCache
// Saves the cache to the DB
//--------------------------------------------------------------------------
- (void) saveCardCountCache
{
  if ([cardLevelCounts count] == 0) return;
  NSString *sql = nil;
  LWEDatabase *db = [LWEDatabase sharedLWEDatabase];
	int j = 0;
  for (int i = 0; i < 6; i++)
  {
    j = [[cardLevelCounts objectAtIndex:i] intValue];
    sql = [[NSString alloc] initWithFormat:@"INSERT OR REPLACE INTO tag_level_count_cache (tag_id,user_id,card_level,count) VALUES ('%d','%d','%d','%d')",tagId,userId,i,j];
    [[db dao] executeUpdate:sql];
    [sql release];
  }  
}


//--------------------------------------------------------------------------
// NSInteger calculateNextCardLevel
// Returns next card level
//--------------------------------------------------------------------------
- (NSInteger) calculateNextCardLevel
{
  // Total number of cards in this set
  int levelOneTotal;
  int totalCards = [self cardCount];
  if (totalCards < 1) return 0;
  
  // Get m cards in n bins, figure out total percentages
  // Calculate different of weights and percentages and adjust accordingly
  int i, tmpTotal = 0, denominatorTotal = 0, weightedTotal = 0, cardTotal = 0, numeratorTotal = 0;
  int numLevels = 5;
  float p = 0,mean = 0, p_unseen = 0, pTotal = 0;
  
  NSMutableArray* tmpTotalArray = [[NSMutableArray alloc] init];
  
  for (i = 1; i <= numLevels; i++)
  {
    // Get denominator values from cache/database
    tmpTotal = [[cardLevelCounts objectAtIndex:i] intValue];
//    tmpTotal = [CardPeer retrieveCardCountByLevel:[self tagId] levelId:i force:NO];    
    if (i == 1) levelOneTotal = tmpTotal;
    [tmpTotalArray addObject:[NSNumber numberWithInt:tmpTotal]];
    cardTotal = cardTotal + tmpTotal;
    denominatorTotal = denominatorTotal + (tmpTotal * (numLevels - i + 1)); 
    numeratorTotal = numeratorTotal + (tmpTotal * i);
  }
  
  // Quick check to make sure we are not at the "start of a set". 
  if (cardTotal == totalCards)
  {
    p_unseen = 0;
  }
  else if (cardTotal > totalCards)
  {
    // This should not happen, it is likely that we need to re-cache TotalCards
    NSLog(@"CardTotal became more than totalCards... (%d, %d)", cardTotal, totalCards);
    p_unseen = 0;
  }
  else
  {
    // Get the "new card" p
    mean = (float)numeratorTotal / (float)cardTotal;
    p_unseen = (mean - (float)1);
    p_unseen = pow((p_unseen / (float) 4),2);
    if (levelOneTotal < 30 && (totalCards - cardTotal) > 0)
    {
      p_unseen = p_unseen + (1-p_unseen)*(pow((30-cardTotal),.25)/pow(30,.25));
    }
  }
	
  float randomNum = ((float)rand() / (float)RAND_MAX);
  
  for (i = 1; i <= numLevels; i++)
  {
    tmpTotal = [[tmpTotalArray objectAtIndex:(i-1)] intValue];
    weightedTotal = (tmpTotal * (numLevels - i + 1));
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


- (void) dealloc 
{
  [super dealloc];
  [unseenCache release];
  // TODO: find out why this crashes
//  [cardLevelCounts release];
  [cardCache release];
}


@end
