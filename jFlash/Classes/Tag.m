//
//  Tag.m
//  jFlash
//
//  Created by Paul Chapman on 5/6/09.
//  Copyright 2009 LONG WEEKEND LLC. All rights reserved.
//

#import "Tag.h"

@implementation Tag

@synthesize tagId, tagName, tagEditable, tagDescription, cards, currentIndex, cardPeerProxy, cardIds, cardLevelCounts;

- (id) init
{
	self = [super init];
  if (self)
  {
    [self setCurrentIndex:0];
    [self setCards:[[NSMutableArray alloc] init]];
    [self setCardLevelCounts:[[NSMutableArray alloc] init]];
    NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
    CardPeerProxy *tmpProxy = [[CardPeerProxy alloc] init];
    [tmpProxy setUserId:[settings integerForKey:@"user_id"]];
    [tmpProxy setTagId:[self tagId]];
    [self setCardPeerProxy:tmpProxy];
    [tmpProxy release];
    // Register listener to reload data if user changes study direction
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(initCache) name:@"studyDirectionWasChanged" object:nil];    
  }
	return self;
}


- (void) cacheCardLevelCounts
{
  NSNumber *count;
  for (int i = 0; i < 6; i++)
  {
     count = [NSNumber numberWithInt:[[[self cardIds] objectAtIndex:i] count]];
     [[self cardLevelCounts] addObject:count];
  }
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


//--------------------------------------------------------------------------
// void populateCards
// sets all of the cards for a tag to this tag's cards array
//--------------------------------------------------------------------------
// TODO remove me
- (void) populateCards
{
  LWE_LOG(@"Began populating cards");
  [self setCards:[CardPeer retrieveCardSetIds:[self tagId]]];
  LWE_LOG(@"Done populating cards");
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
    LWE_LOG(@"Found plist, no need to load from database");
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
// replenishUnseenCache
// Gets unseen card cache
//--------------------------------------------------------------------------
- (void) replenishUnseenCache
{
  return [[self cardPeerProxy] replenishUnseenCache];
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
  [[[self cardIds] objectAtIndex:nextLevel] removeObject:cardId];
  
  [[self cardPeerProxy] updateLevelCounts:card nextLevel:nextLevel];
}


//--------------------------------------------------------------------------
// saveCardCountCache
// Save level counts
//--------------------------------------------------------------------------
- (void) saveCardCountCache
{ 
  return [cardPeerProxy saveCardCountCache];
}


//--------------------------------------------------------------------------
// int cardCount
// Get how many cards are in this tag
//--------------------------------------------------------------------------
- (NSInteger) cardCount
{ 
  return [cardPeerProxy cardCount];
}


//--------------------------------------------------------------------------
// void setCardCount
// Sets how many cards are in this tag
//--------------------------------------------------------------------------
- (void) setCardCount: (NSInteger) count
{ 
  [cardPeerProxy setCardCount:count];
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


//--------------------------------------------------------------------------
// Card getNextCard
// Returns the next card in the list, resets index if at the end of the list
//--------------------------------------------------------------------------
- (Card*) getNextCard
{
	int currIdx = [self currentIndex];
	int total = [cards count];
	if(currIdx >= total)
  {
    currIdx = 0;
  }
  else 
  {
    currIdx++;
  }
  // TODO: figure out how to flatten the card levels into total card ids for this kind of thing
  Card* nextCard = [CardPeer retrieveCardByPK:[[[self cardIds] objectAtIndex:currIdx] intValue]];
  [self setCurrentIndex:currIdx];
  return nextCard;
}
//--------------------------------------------------------------------------


//--------------------------------------------------------------------------
// Card getPrevCard
// Returns the previous card in the list, or nil if at start of list
//--------------------------------------------------------------------------
- (Card*) getPrevCard
{
	int currIdx = [self currentIndex];
	if(currIdx > 0)
  {
		currIdx--;
		Card* prevCard = [[self cards] objectAtIndex:currIdx];
    if ([prevCard cardId] > 0 && [prevCard headword] == nil)
    {
      prevCard = [CardPeer hydrateCardByPK:prevCard];
    }
    [self setCurrentIndex:currIdx];
		return prevCard;
	}
	else
  {
		return nil;    
  }
}
//--------------------------------------------------------------------------


//--------------------------------------------------------------------------
//takes a sqlite result set and populates the properties of tag
//--------------------------------------------------------------------------
- (void) hydrate: (FMResultSet*) rs
{
	[self setTagId:           [rs intForColumn:@"tag_id"]];
  [self setTagDescription:  [rs stringForColumn:@"description"]];
  [self setTagName:         [rs stringForColumn:@"tag_name"]];
  [self setTagEditable:     [rs intForColumn:@"editable"]];
  [[self cardPeerProxy] setCardCount: [rs intForColumn:@"count"]];
  [[self cardPeerProxy] setTagId: [rs intForColumn:@"tag_id"]];
  
}
//--------------------------------------------------------------------------


- (void) dealloc
{
  [cardPeerProxy release];
  [tagName release];
  [tagDescription release];
  [cards release];
	[super dealloc];
}

@end