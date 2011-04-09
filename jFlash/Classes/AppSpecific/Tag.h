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

@interface Tag : NSObject
{
	NSInteger tagId;
  NSInteger tagEditable;                            //! Is the tag deletable by the user?
  NSInteger cardCount;                              //! Current count of Card objects in the Tag
	NSInteger currentIndex;
	NSString *tagName;
	NSString *tagDescription;
  NSMutableArray *cardIds;
  NSMutableArray *combinedCardIdsForBrowseMode;
  NSMutableArray *cardLevelCounts;
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
- (void) addCardToActiveSet:(Card *)card;
- (void) setCardCount:(int) count;
- (NSMutableArray *) combineCardIds;
- (NSInteger) groupId;

@property (nonatomic) NSInteger tagEditable;
@property (nonatomic, retain) NSString *tagName;
@property (nonatomic, retain) NSString *tagDescription;
@property (nonatomic, retain) NSMutableArray *cardIds;
@property (nonatomic, retain) NSMutableArray *combinedCardIdsForBrowseMode;
@property (nonatomic, retain) NSMutableArray *cardLevelCounts;
@property (nonatomic) NSInteger tagId;
@property (nonatomic) NSInteger currentIndex;

@end