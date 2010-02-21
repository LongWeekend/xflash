//
//  Tag.h
//  jFlash
//
//  Created by Paul Chapman on 5/6/09.
//  Copyright 2009 LONG WEEKEND INC. All rights reserved.
//

#import "Card.h"
#import "CardPeerProxy.h"

@interface Tag : NSObject
{
	NSInteger tagId;
	NSString *tagName;
  NSInteger tagEditable;
	NSString *tagDescription;
	NSMutableArray *cards;
	NSInteger currentIndex;
  CardPeerProxy *cardPeerProxy;
}

- (void) hydrate: (FMResultSet*)rs;
- (void) populateCards;
- (Card*) getRandomCard;
- (Card*) getNextCard;
- (Card*) getPrevCard;
- (NSInteger) cardCount;
- (void) setCardCount: (NSInteger) count;
- (NSMutableArray*) cardLevelCounts;
- (void) updateLevelCounts:(Card*) card nextLevel:(NSInteger) nextLevel;
- (void) saveCardCountCache;
- (void) cacheCardLevelCounts;
- (void) replenishUnseenCache;

@property (nonatomic) NSInteger tagEditable;
@property (nonatomic, retain) NSString *tagName;
@property (nonatomic, retain) NSString *tagDescription;
@property (nonatomic, retain) NSMutableArray *cards;
@property (nonatomic, retain) CardPeerProxy *cardPeerProxy;
@property (nonatomic) NSInteger tagId;
@property (nonatomic) NSInteger currentIndex;

@end