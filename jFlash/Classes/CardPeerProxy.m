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



- (void) dealloc 
{
  [super dealloc];
  [unseenCache release];
  // TODO: find out why this crashes
//  [cardLevelCounts release];
  [cardCache release];
}


@end
