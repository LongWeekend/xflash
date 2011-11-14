//
//  Tag.h
//  jFlash
//
//  Created by Paul Chapman on 5/6/09.
//  Copyright 2009 LONG WEEKEND INC. All rights reserved.
//

#import "Constants.h"
#import "Card.h"
#import "CardPeer.h"
#import "FMResultSet.h"
#import "LWEFile.h"
#import "LWEDatabase.h"

extern NSString * const kTagErrorDomain;
extern NSUInteger const kAllBuriedAndHiddenError;

@interface Tag : NSObject

- (void) hydrate: (FMResultSet*)rs;
- (void) hydrate;
- (void) populateCardIds;
- (NSInteger) calculateNextCardLevelWithError:(NSError **)error;
- (Card *) getRandomCard:(NSInteger)currentCardId error:(NSError **)error;
- (Card *) getFirstCardWithError:(NSError **)error;
- (Card *) getNextCard;
- (Card *) getPrevCard;
- (NSInteger) cardCount;
- (void) updateLevelCounts:(Card*) card nextLevel:(NSInteger) nextLevel;
- (void) cacheCardLevelCounts;
- (void) freezeCardIds;
- (NSMutableArray *) thawCardIds;
- (void) removeCardFromActiveSet:(Card *)card;
- (void) addCardToActiveSet:(Card *)card;
- (void) setCardCount:(int) count;
- (NSMutableArray *) combineCardIds;
- (NSInteger) groupId;
- (void) save;

//! Is the tag deletable by the user?
@property (nonatomic) NSInteger tagEditable;
@property (nonatomic, retain) NSString *tagName;
@property (nonatomic, retain) NSString *tagDescription;
@property (nonatomic, retain) NSMutableArray *cardIds;
@property (nonatomic, retain) NSMutableArray *combinedCardIdsForBrowseMode;
@property (nonatomic, retain) NSMutableArray *cardLevelCounts;
@property (nonatomic, retain) NSMutableArray *lastFiveCards;
@property (nonatomic) NSInteger tagId;
@property (nonatomic) NSInteger currentIndex;

//! Current count of Card objects in the Tag
@property NSInteger cardCount;

@end