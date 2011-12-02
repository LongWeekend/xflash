#import "Card.h"

@class Tag;

/** Peer object to retrieve & handle Card objects */
@interface CardPeer : NSObject

//! Factory methods for getting a card
+ (Card *) blankCardWithId:(NSInteger)cardId;
+ (Card *) blankCard;

//! Card methods
+ (Card*) retrieveCardByPK:(NSInteger)cardId;

//! Array of cards methods
+ (NSArray*) retrieveCardIdsSortedByLevel:(NSInteger)tagId;
+ (NSArray*) retrieveFaultedCardsForTag:(Tag *)tag;

//! Example sentences
+ (NSArray*) retrieveCardSetForExampleSentenceId:(NSInteger)sentenceID;

//! Search methods
+ (NSArray*) fullTextSearchForKeyword:(NSString*)keyword;
+ (NSArray*) substringSearchForKeyword:(NSString*)keyword;
+ (NSArray*) searchCardsForKeyword:(NSString*) keyword doSlowSearch:(BOOL)slowSearch;
@end