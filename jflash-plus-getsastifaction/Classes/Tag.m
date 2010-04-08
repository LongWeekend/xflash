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
	self = [super init];
  if (self)
  {
    cardCount = -1;
    [self setCurrentIndex:0];
  }
	return self;
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
    LWE_LOG(@"CardTotal became more than totalCards... (%d, %d)", cardTotal, totalCards);
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


- (void) cacheCardLevelCounts
{
  NSNumber *count;
  int totalCount = 0;
  NSMutableArray* cardLevelCountsTmp = [[NSMutableArray alloc] init];
  for (int i = 0; i < 6; i++)
  {
    count = [[NSNumber alloc] initWithInt:[[[self cardIds] objectAtIndex:i] count]];
    [cardLevelCountsTmp addObject:count];
    totalCount = totalCount + [count intValue];
    [count release];
  }
  [self setCardLevelCounts:cardLevelCountsTmp];
  [cardLevelCountsTmp release];
  [self setCardCount:totalCount];
}


- (NSMutableArray*) thawCardIds
{
  NSString *path = [LWEFile createDocumentPathWithFilename:@"ids.plist"];
  LWE_LOG(@"Beginning plist reading: %@",path);
  NSMutableArray* tmpCardIds = [[[NSMutableArray alloc] initWithContentsOfFile:path] autorelease];
  LWE_LOG(@"Finished plist reading");
  return tmpCardIds;
}


- (void) freezeCardIds
{
  NSString* path = [LWEFile createDocumentPathWithFilename:@"ids.plist"];
  LWE_LOG(@"Beginning plist freezing: %@",path);
  [[self cardIds] writeToFile:path atomically:YES];
  LWE_LOG(@"Finished plist freezing");
}

- (void) populateCardIds
{
  LWE_LOG(@"Began populating card ids and setting counts");
  NSMutableArray* tmpArray = [self thawCardIds];
  if (tmpArray == nil)
  {
    LWE_LOG(@"No plist, load from database");
    tmpArray = [CardPeer retrieveCardSetIds:self.tagId];
  }
  else
  {
    LWE_LOG(@"Found plist, deleting plist");
    NSString* path = [LWEFile createDocumentPathWithFilename:@"ids.plist"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    [fileManager removeItemAtPath:path error:NULL];
  }
  
  // Now set it
  [self setCardIds:tmpArray];
  
  // Also set the combined card ids
  [self setCombinedCardIdsForBrowseMode:[self combineCardIds]];

  // populate the card level counts
	[self cacheCardLevelCounts];
  
  LWE_LOG(@"End populating card ids and setting counts");
}


//--------------------------------------------------------------------------
// Card getRandomCard
// Returns a Card object from the database randomly
//--------------------------------------------------------------------------
- (Card*) getRandomCard:(int) currentCardId
{
  // determine the next level
  int next_level = [self calculateNextCardLevel];
  
  // Get a random card offset
  int numCardsAtLevel = [[[self cardIds] objectAtIndex:next_level] count];
  int randomOffset = arc4random() % numCardsAtLevel;
  NSNumber* cardId;
  
  NSMutableArray* cardIdArray = [[self cardIds] objectAtIndex:next_level];
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
    cardIdArray = [[self cardIds] objectAtIndex:next_level];
    randomOffset = arc4random() % [[[self cardIds] objectAtIndex:next_level] count];
    cardId = [cardIdArray objectAtIndex:randomOffset];      
  }
  return [CardPeer retrieveCardByPK:[cardId intValue]];
}

//--------------------------------------------------------------------------
// updateLevelCounts
// Update level counts
//--------------------------------------------------------------------------
- (void) updateLevelCounts:(Card*) card nextLevel:(NSInteger) nextLevel
{
  // update the cardIds if necessary
  if (nextLevel != card.levelId)
  { 
    LWE_LOG(@"Moving card Id %d From level %d to level %d",card.cardId,card.levelId,nextLevel);
    NSNumber* cardId = [NSNumber numberWithInt:card.cardId];
    LWE_LOG(@"Items in index to be removed: %d",[[[self cardIds] objectAtIndex:card.levelId] count]);
    LWE_LOG(@"Items in index to be added: %d",[[[self cardIds] objectAtIndex:nextLevel] count]);
    [[[self cardIds] objectAtIndex:card.levelId] removeObject:cardId];
    [[[self cardIds] objectAtIndex:nextLevel] addObject:cardId];
    LWE_LOG(@"Items in removed: %d",[[[self cardIds] objectAtIndex:card.levelId] count]);
    LWE_LOG(@"Items in added: %d",[[[self cardIds] objectAtIndex:nextLevel] count]);
    [self cacheCardLevelCounts];
  }
}


//--------------------------------------------------------------------------
// int cardCount
// Get how many cards are in this tag
//--------------------------------------------------------------------------
- (NSInteger) cardCount
{ 
  return cardCount;
}

- (void) setCardCount: (int) count
{
  // do nothing if its the same
  if(cardCount == count) return;
  
  // update the count in the database if not first load (e.g. cardCount = -1)
  if (cardCount >= 0)
  {
    LWEDatabase *db = [LWEDatabase sharedLWEDatabase];
    NSString *sql = [[NSString alloc] initWithFormat:@"UPDATE tags SET count = '%d' WHERE tag_id = '%d'",count,[self tagId]];
    [[db dao] executeUpdate:sql];
    [sql release];
  }

  // set the variable to the new count
  cardCount = count; 
}


- (void) removeCardFromActiveSet:(Card *)card
{
  NSMutableArray* cardLevel = [[self cardIds] objectAtIndex:[card levelId]];
  [cardLevel removeObjectIdenticalTo:[NSNumber numberWithInt:[card cardId]]];
  [[self combinedCardIdsForBrowseMode] removeObjectIdenticalTo:[NSNumber numberWithInt:[card cardId]]];
  [self cacheCardLevelCounts];
}


- (Card*) getFirstCard
{
  NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
  Card* card;
  if ([[settings objectForKey:APP_MODE] isEqualToString: SET_MODE_BROWSE])
  {
    // TODO: in some cases the currentIndex can be beyond the range.  We should figure out why, but for the time being I'll reset it to 0 instead of breaking
    if([self currentIndex] >= [[self combinedCardIdsForBrowseMode] count])
    {
      [self setCurrentIndex:0];
    }
    NSNumber* cardId = [[self combinedCardIdsForBrowseMode] objectAtIndex: [self currentIndex]];
    card = [CardPeer retrieveCardByPK:[cardId intValue]];
  }
  else
  {
    if ([settings integerForKey:@"card_id"] != 0)
    {
      card = [CardPeer retrieveCardByPK:[settings integerForKey:@"card_id"]];
      [settings setInteger:0 forKey:@"card_id"];
    }
    else
    {
      card = [self getRandomCard:0];
    }
  }
  return card;
}


- (NSMutableArray *) combineCardIds
{
  NSMutableArray* allCardIds = [[[NSMutableArray alloc] init] autorelease];
  NSMutableArray* cardIdsInLevel;
  for (cardIdsInLevel in [self cardIds]) 
  {
    [allCardIds addObjectsFromArray:cardIdsInLevel];
  }
  [allCardIds sortUsingSelector:@selector(compare:)];
  return allCardIds;
}

//--------------------------------------------------------------------------
// Card getNextCard
// Returns the next card in the list, resets index if at the end of the list
//--------------------------------------------------------------------------
- (Card*) getNextCard
{
  NSMutableArray *allCardIds;
  allCardIds = [self combinedCardIdsForBrowseMode];
  
	int currIdx = [self currentIndex];
	int total = [allCardIds count];
	if(currIdx >= total - 1)
  {
    currIdx = 0;
  }
  else 
  {
    currIdx++;
  }

  [self setCurrentIndex:currIdx];
  return [CardPeer retrieveCardByPK:[[allCardIds objectAtIndex:currIdx] intValue]];
}


//----------------------------------------------------------------------------
// Card getPrevCard
// Returns the previous card in the list, resets index to top last card if at 0
//-----------------------------------------------------------------------------
- (Card*) getPrevCard
{
  NSMutableArray *allCardIds;
  allCardIds = [self combinedCardIdsForBrowseMode];
	int currIdx = [self currentIndex];

	int total = [allCardIds count];
	if(currIdx == 0)
  {
    currIdx = total-1;
  }
  else
  {
    currIdx--;
  }
  
  [self setCurrentIndex:currIdx];
  int tmp = [[allCardIds objectAtIndex:currIdx] intValue];
  return [CardPeer retrieveCardByPK:tmp];
}


//--------------------------------------------------------------------------
//takes a sqlite result set and populates the properties of tag
//--------------------------------------------------------------------------
- (void) hydrate: (FMResultSet*) rs
{
	[self setTagId:           [rs intForColumn:@"tag_id"]];
  [self setTagDescription:  [rs stringForColumn:@"description"]];
  [self setTagName:         [rs stringForColumn:@"tag_name"]];
  [self setTagEditable:     [rs intForColumn:@"editable"]];
  [self setCardCount:       [rs intForColumn:@"count"]];
}
//--------------------------------------------------------------------------


- (void) dealloc
{
  [tagName release];
  [tagDescription release];
  [cardIds release];
	[super dealloc];
}

@end