//
//  Tag.m
//  jFlash
//
//  Created by Paul Chapman on 5/6/09.
//  Copyright 2009 LONG WEEKEND LLC. All rights reserved.
//

#import "Tag.h"

@implementation Tag

@synthesize tagId, tagName, tagEditable, tagDescription, currentIndex, cardPeerProxy, cardIds, cardLevelCounts;

- (id) init
{
	self = [super init];
  if (self)
  {
    [self setCurrentIndex:0];
    NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
    CardPeerProxy *tmpProxy = [[CardPeerProxy alloc] init];
    [tmpProxy setUserId:[settings integerForKey:@"user_id"]];
    [tmpProxy setTagId:[self tagId]];
    [self setCardPeerProxy:tmpProxy];
    [tmpProxy release];
  }
	return self;
}


- (void) cacheCardLevelCounts
{
  NSNumber *count;
  int totalCount = 0;
  NSMutableArray* cardLevelCountsTmp = [[[NSMutableArray alloc] init] autorelease];
  for (int i = 0; i < 6; i++)
  {
    count = [NSNumber numberWithInt:[[[self cardIds] objectAtIndex:i] count]];
    [cardLevelCountsTmp addObject:count];
    totalCount = totalCount + [count intValue];
  }
  [self setCardLevelCounts:cardLevelCountsTmp];
  [self setCardCount:totalCount];
  [cardPeerProxy setCardLevelCounts:[self cardLevelCounts]];
}


- (NSMutableArray*) thawCardIds
{
  NSString *path = [LWEFile createDocumentPathWithFilename:@"ids.plist"];
  LWE_LOG(@"Beginning plist reading: %@",path);
  NSMutableArray* tmpCardIds = [[NSMutableArray alloc] initWithContentsOfFile:path];
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
  int next_level = [cardPeerProxy calculateNextCardLevel];
  while([[[self cardIds] objectAtIndex:next_level] count] == 0)
  {
    next_level = [cardPeerProxy calculateNextCardLevel];
  }
  
  // Get a random card offset
  int randomOffset = arc4random() % [[[self cardIds] objectAtIndex:next_level] count];

  NSNumber* cardId;
  
  NSMutableArray* cardIdArray = [[self cardIds] objectAtIndex:next_level];
  cardId = [cardIdArray objectAtIndex:randomOffset];

// TODO: prevent getting the same card twice.
//  if([cardId intValue] == currentCardId)
//  {
//    [self getRandomCard:currentCardId];
//  }
  
  return [CardPeer retrieveCardByPK:[cardId intValue]];
}

//--------------------------------------------------------------------------
// updateLevelCounts
// Update level counts
//--------------------------------------------------------------------------
- (void) updateLevelCounts:(Card*) card nextLevel:(NSInteger) nextLevel
{
  // update the cardIds
  NSNumber* cardId = [NSNumber numberWithInt:card.cardId];
  [[[self cardIds] objectAtIndex:card.levelId] removeObject:cardId];
  [[[self cardIds] objectAtIndex:nextLevel] addObject:cardId];
  
  [self cacheCardLevelCounts];
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
  
  // set the variable to the new count
  cardCount = count;  
  
  // update the count in the database
  LWEDatabase *db = [LWEDatabase sharedLWEDatabase];
	NSString *sql = [[NSString alloc] initWithFormat:@"UPDATE tags SET count = '%d' WHERE tag_id = '%d'",count,[self tagId]];
  [[db dao] executeUpdate:sql];
}

- (void) removeCardFromActiveSet:(Card *)card
{
  NSMutableArray* cardLevel = [[self cardIds] objectAtIndex:[card levelId]];
  [cardLevel removeObjectIdenticalTo:[NSNumber numberWithInt:[card cardId]]];
}

- (Card*) getFirstCard
{
  NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
  Card* card;
  if ([[settings objectForKey:APP_MODE] isEqualToString: SET_MODE_BROWSE])
  {
    NSNumber* cardId = [[[self cardIds] objectAtIndex:0] objectAtIndex: [self currentIndex]];
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


- (NSMutableArray *) getCombinedCardIds {
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
  allCardIds = [self getCombinedCardIds];
  
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
  allCardIds = [self getCombinedCardIds];
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
  [[self cardPeerProxy] setTagId: [rs intForColumn:@"tag_id"]];
  [self setCardCount:       [rs intForColumn:@"count"]];
}
//--------------------------------------------------------------------------


- (void) dealloc
{
  [cardPeerProxy release];
  [tagName release];
  [tagDescription release];
  [cardIds release];
	[super dealloc];
}

@end