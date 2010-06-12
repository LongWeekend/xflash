#import "Card.h"
#import "LWEDebug.h"
#import "LWEDatabase.h"
#import "FMResultSet.h"

/** Peer object to retrieve & handle Card objects */
@interface CardPeer : NSObject
{
}

//! Card methods
+ (Card*) retrieveCardWithSQL: (NSString*) sql;
+ (Card*) retrieveCardByPK: (NSInteger)cardId;
+ (Card*) retrieveCardByLevel: (NSInteger)levelId setId:(NSInteger)setId withRandom: (NSInteger) randomNum;
+ (Card*) hydrateCardByPK: (Card*) card;

//! Array of cards methods
+ (NSMutableArray*) retrieveCardSetWithSQL: (NSString*) sql hydrate:(BOOL)hydrate;
+ (NSMutableArray*) retrieveCardSet: (NSInteger)setId;
+ (NSMutableArray*) retrieveCardIdsSortedByLevel: (NSInteger) tagId;
+ (NSMutableArray*) retrieveCardIdsForTagId: (NSInteger)tagId;
+ (NSMutableArray*) retrieveCardSetByLevel: (NSInteger)setId levelId:(NSInteger)levelId;
+ (NSMutableArray*) searchCardsForKeyword: (NSString*) keyword doSlowSearch:(BOOL)slowSearch;
@end