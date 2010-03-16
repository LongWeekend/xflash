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
