//
//  Tag.h
//  jFlash
//
//  Created by Paul Chapman on 5/6/09.
//  Copyright 2009 LONG WEEKEND INC. All rights reserved.
//

#import "Card.h"
#import "CardPeerProxy.h"
#import "LWEFile.h"

@interface Tag : NSObject
{
	NSInteger tagId;
	NSString *tagName;
  NSInteger tagEditable;
	NSString *tagDescription;
	NSMutableArray *cards;
  NSMutableArray *cardIds;
  NSMutableArray *cardLevelCounts;
	NSInteger currentIndex;
  CardPeerProxy *cardPeerProxy;
}

- (void) hydrate: (FMResultSet*)rs;
- (void) populateCards;
- (void) populateCardIds;
- (Card*) getRandomCard:(int) currentCardId;
- (Card*) getFirstCard;
- (Card*) getNextCard;
- (Card*) getPrevCard;
- (NSInteger) cardCount;
- (void) setCardCount: (NSInteger) count;
- (void) updateLevelCounts:(Card*) card nextLevel:(NSInteger) nextLevel;
- (void) saveCardCountCache;
- (void) cacheCardLevelCounts;
- (void) replenishUnseenCache;
- (void) freezeCardIds;
- (NSMutableArray*) thawCardIds;

@property (nonatomic) NSInteger tagEditable;
@property (nonatomic, retain) NSString *tagName;
@property (nonatomic, retain) NSString *tagDescription;
@property (nonatomic, retain) NSMutableArray *cards;
@property (nonatomic, retain) NSMutableArray *cardIds;
@property (nonatomic, retain) CardPeerProxy *cardPeerProxy;
@property (nonatomic, retain) NSMutableArray *cardLevelCounts;
@property (nonatomic) NSInteger tagId;
@property (nonatomic) NSInteger currentIndex;

@end