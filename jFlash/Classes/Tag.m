//
//  Tag.m
//  jFlash
//
//  Created by Paul Chapman on 5/6/09.
//  Copyright 2009 LONG WEEKEND LLC. All rights reserved.
//

#import "Tag.h"

@implementation Tag

@synthesize tagId, tagName, tagEditable, tagDescription, cards, currentIndex, cardPeerProxy;

- (id) init
{
	self = [super init];
  if (self)
  {
    [self setCurrentIndex:0];
    [self setCards:[[NSMutableArray alloc] init]];
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
  [[self cardPeerProxy] cacheCardLevelCountsWithCards:cards];
}


//--------------------------------------------------------------------------
// void populateCards
// sets all of the cards for a tag to this tag's cards array
//--------------------------------------------------------------------------
- (void) populateCards
{
  LWE_LOG(@"Began populating cards");
  [self setCards:[CardPeer retrieveCardSetIds:[self tagId]]];
  LWE_LOG(@"Done populating cards");
}


//--------------------------------------------------------------------------
// Card getRandomCard
// Returns a Card object from the database randomly
//--------------------------------------------------------------------------
- (Card*) getRandomCard
{
  return [[self cardPeerProxy] getRandomCard];
}


//--------------------------------------------------------------------------
// NSMutableArray cardLevelCounts
// Returns number of cards at each level
//--------------------------------------------------------------------------
- (NSMutableArray*) cardLevelCounts
{
  return [[self cardPeerProxy] cardLevelCounts];
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
  return [[self cardPeerProxy] updateLevelCounts:card nextLevel:nextLevel];
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


//--------------------------------------------------------------------------
// Card getNextCard
// Returns the next card in the list, or nil if at end of list
//--------------------------------------------------------------------------
- (Card*) getNextCard
{
	int currIdx = [self currentIndex];
	int total = [cards count]-1;
	if(currIdx < total)
  {
		currIdx++;
		Card* nextCard = [[self cards] objectAtIndex:currIdx];
    if ([nextCard cardId] > 0 && [nextCard headword] == nil)
    {
      nextCard = [CardPeer hydrateCardByPK:nextCard];
    }
    [self setCurrentIndex:currIdx];
		return nextCard;
	}
	else
  {
		return nil;
  }
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