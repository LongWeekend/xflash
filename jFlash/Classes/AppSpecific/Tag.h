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
extern NSUInteger const kLWETagUnknownError;

extern NSInteger const kLWEUninitializedTagId;
extern NSInteger const kLWEUnseenCardLevel;
extern NSInteger const kLWELearnedCardLevel;

@interface Tag : NSObject

- (void) hydrate: (FMResultSet*)rs;
- (void) hydrate;

//! Factory method that returns the starred words tag
+ (Tag *) starredWordsTag;

//! Factory method for an unitialized tag that only has its ID set
+ (Tag *) blankTagWithId:(NSInteger)tagId;

//! Returns YES if the user is allowed to edit this tag (either description or the contents)
- (BOOL) isEditable;

- (void) populateCardIds;
- (NSInteger) calculateNextCardLevelWithError:(NSError **)error;
- (Card *) getRandomCard:(NSInteger)currentCardId error:(NSError **)error;
- (Card *) getFirstCardWithError:(NSError **)error;
- (Card *) getNextCard;
- (Card *) getPrevCard;
- (NSInteger) cardCount;
- (void) moveCard:(Card*) card toLevel:(NSInteger) nextLevel;
- (void) recacheCardCountForEachLevel;
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
@property (nonatomic, retain) NSMutableArray *flattenedCardIdArray;
@property (nonatomic, retain) NSMutableArray *cardLevelCounts;
@property (nonatomic, retain) NSMutableArray *lastFiveCards;
@property (nonatomic) NSInteger tagId;
@property (nonatomic) NSInteger currentIndex;

//! Returns YES if this Tag is not actually a Tag, but a shell of a tag.  If so, call -hydrate
@property (readonly) BOOL isFault;

//! Current count of Card objects in the Tag
@property NSInteger cardCount;

@end