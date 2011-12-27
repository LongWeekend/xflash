//
//  PracticeCardSelector.m
//  xFlash
//
//  Created by Mark Makdad on 12/27/11.
//  Copyright (c) 2011 Long Weekend LLC. All rights reserved.
//

#import "PracticeCardSelector.h"

@implementation PracticeCardSelector
#pragma mark - Level algorithm

/**
 * Calculates next card level based on current performance & Tag progress
 */
- (NSInteger)calculateNextCardLevelForTag:(Tag *)tag error:(NSError **)error
{
  LWE_ASSERT_EXC(([tag.cardLevelCounts count] == 6),@"There must be 6 card levels (1-5 plus unseen cards)");
  
  // control variables
  // controls how many words to show from new before preferring seen words
  NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
  NSInteger weightingFactor = [settings integerForKey:APP_FREQUENCY_MULTIPLIER];
  BOOL hideLearnedCards = [settings boolForKey:APP_HIDE_BURIED_CARDS];
  
  // Total number of cards in this set and its level
  NSInteger numLevels = 5;
  NSInteger unseenCount = [[tag.cardLevelCounts objectAtIndex:kLWEUnseenCardLevel] intValue];
  NSInteger totalCardsInSet = tag.cardCount;
  
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
    NSInteger learnedCount = [[tag.cardLevelCounts objectAtIndex:kLWELearnedCardLevel] intValue];
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
    NSInteger tmpTotal = [[tag.cardLevelCounts objectAtIndex:levelId] intValue];
    totalArray[levelId-1] = tmpTotal;   // all the level references (& the math) are 1-indexed, the array is 0 indexed
    cardsSeenTotal = cardsSeenTotal + tmpTotal;
    denominatorTotal = denominatorTotal + (tmpTotal * weightingFactor * (numLevels - levelId + 1)); 
    numeratorTotal = numeratorTotal + (tmpTotal * levelId);
  }
  
  CGFloat p_unseen = [self calculateProbabilityOfUnseenWithCardsSeen:cardsSeenTotal 
                                                          totalCards:totalCardsInSet
                                                           numerator:numeratorTotal 
                                                       levelOneCards:totalArray[0]];
  
  CGFloat randomNum = ((CGFloat)rand() / (CGFloat)RAND_MAX);
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
- (CGFloat)calculateProbabilityOfUnseenWithCardsSeen:(NSUInteger)cardsSeenTotal totalCards:(NSUInteger)totalCardsInSet numerator:(NSUInteger)numeratorTotal levelOneCards:(NSUInteger)levelOneTotal
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


@end
