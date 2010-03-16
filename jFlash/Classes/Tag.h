//
//  Tag.h
//  jFlash
//
//  Created by Paul Chapman on 5/6/09.
//  Copyright 2009 LONG WEEKEND INC. All rights reserved.
//

#import "Card.h"

@interface Tag : NSObject
{
	NSInteger tagId;
	NSString *tagName;
  NSInteger tagEditable;
  NSInteger cardCount;
	NSString *tagDescription;
  NSMutableArray *cardIds;
  NSMutableArray *cardLevelCounts;
	NSInteger currentIndex;
}

- (void) hydrate: (FMResultSet*)rs;
- (void) populateCardIds;
- (NSInteger) calculateNextCardLevel;
- (Card*) getRandomCard:(int) currentCardId;
- (Card*) getFirstCard;
- (Card*) getNextCard;
- (Card*) getPrevCard;
- (NSInteger) cardCount;
- (void) updateLevelCounts:(Card*) card nextLevel:(NSInteger) nextLevel;
- (void) cacheCardLevelCounts;
- (void) freezeCardIds;
- (NSMutableArray*) thawCardIds;
- (void) removeCardFromActiveSet:(Card *)card;
- (void) setCardCount:(int) count;

@property (nonatomic) NSInteger tagEditable;
@property (nonatomic, retain) NSString *tagName;
@property (nonatomic, retain) NSString *tagDescription;
@property (nonatomic, retain) NSMutableArray *cardIds;
@property (nonatomic, retain) NSMutableArray *cardLevelCounts;
@property (nonatomic) NSInteger tagId;
@property (nonatomic) NSInteger currentIndex;

@end