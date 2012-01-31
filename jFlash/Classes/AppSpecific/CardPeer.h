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
+ (NSMutableArray*) retrieveCardsSortedByLevelForTag:(Tag *)tag;
+ (NSArray*) retrieveFaultedCardsForTag:(Tag *)tag;

//! Example sentences
+ (NSArray*) retrieveCardSetForExampleSentenceId:(NSInteger)sentenceID;

//! Search methods
+ (BOOL) keywordIsReading:(NSString *)keyword;
+ (BOOL) keywordIsHeadword:(NSString *)keyword;
+ (NSArray*) searchCardsForKeyword:(NSString *)keyword;
@end