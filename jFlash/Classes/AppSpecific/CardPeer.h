#import "Card.h"

/** Peer object to retrieve & handle Card objects */
@interface CardPeer : NSObject

//! Card methods
+ (Card*) retrieveCardByPK:(NSInteger)cardId;

//! Array of cards methods
+ (NSArray*) retrieveCardIdsSortedByLevel:(NSInteger)tagId;
+ (NSArray*) retrieveCardIdsForTagId:(NSInteger)tagId;

+ (NSArray*) retrieveCardSetForSentenceId:(NSInteger)sentenceId;
+ (NSArray*) retrieveCardSetForExampleSentenceId:(NSInteger)sentenceID;

//! Search methods
+ (NSArray*) searchCardsForKeyword:(NSString*) keyword doSlowSearch:(BOOL)slowSearch;
@end