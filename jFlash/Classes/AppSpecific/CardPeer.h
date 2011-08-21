#import "Card.h"

/** Peer object to retrieve & handle Card objects */
@interface CardPeer : NSObject

//! Card methods
+ (Card*) retrieveCardWithSQL: (NSString*) sql;
+ (Card*) retrieveCardByPK: (NSInteger)cardId;
+ (Card*) retrieveCardByLevel: (NSInteger)levelId setId:(NSInteger)setId withRandom: (NSInteger) randomNum;
+ (Card*) hydrateCardByPK: (Card*) card;

// TODO: deprecate/get rid of this method in favor of the one below it
+ (NSMutableArray*) retrieveCardSetWithSQL: (NSString*) sql hydrate:(BOOL)hydrate;

//! Array of cards methods
+ (NSMutableArray*) retrieveCardSetWithSQL: (NSString*) sql hydrate:(BOOL)hydrate isBasicCard:(BOOL)basicCard;
+ (NSMutableArray*) retrieveCardSet: (NSInteger)setId;
+ (NSMutableArray*) retrieveCardIdsSortedByLevel: (NSInteger) tagId;
+ (NSMutableArray*) retrieveCardIdsForTagId: (NSInteger)tagId;
+ (NSMutableArray*) retrieveCardSetWithSQL: (NSString*) sql hydrate:(BOOL)hydrate isBasicCard:(BOOL)basicCard;
+ (NSMutableArray*) retrieveCardSetForSentenceId: (NSInteger) sentenceId;
+ (NSMutableArray*) retrieveCardSetForExampleSentenceID: (NSInteger) sentenceID showAll:(BOOL)showAll;
+ (NSMutableArray*) retrieveCardSetByLevel: (NSInteger)setId levelId:(NSInteger)levelId;
+ (NSMutableArray*) searchCardsForKeyword: (NSString*) keyword doSlowSearch:(BOOL)slowSearch;
@end