//
//  CardPeerProxy.h
//  jFlash
//
//  Created by シャロット ロス on 2/7/10.
//  Copyright 2010 LONG WEEKEND INC.. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CardPeerProxy : NSObject
{
  NSMutableArray *cardLevelCounts;
  NSMutableArray *recentCards;
  NSMutableArray *cardCache;
  NSMutableArray *unseenCache;
  NSInteger cardCount;
  BOOL locked;
  NSInteger userId;
  NSInteger tagId;
}

- (Card*) retrieveCardForLevel: (NSInteger)levelId;
- (Card*) retrieveCardForLevelNull: (NSInteger) randomOffset;
- (Card*) getRandomCard;
- (NSInteger) calculateNextCardLevel;
- (NSMutableArray*) cacheCardLevelCountsWithCards:(NSMutableArray*) cards;
- (void) replenishUnseenCache;
- (void) replenishCardCacheForLevel: (NSNumber*) levelId;
- (void) updateLevelCounts:(Card*) card nextLevel:(NSInteger)nextLevel;
- (void) saveCardCountCache;

@property (nonatomic,retain) NSMutableArray *cardLevelCounts;
@property (nonatomic) NSInteger cardCount;
@property (nonatomic) NSInteger tagId;
@property (nonatomic) NSInteger userId;
@property (nonatomic, retain) NSMutableArray *recentCards;
@property (retain) NSMutableArray *cardCache;
@property (retain) NSMutableArray *unseenCache;
@property (nonatomic) BOOL locked;

@end