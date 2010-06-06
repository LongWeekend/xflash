#import "Card.h"
#import "LWEDebug.h"
#import "LWEDatabase.h"
#import "FMResultSet.h"

//! Peer object to retrieve & handle Card objects
@interface CardPeer : NSObject {
}

// TODO: is this still used?  I think we can ditch it -- maybe usable for "bad data" reporting?
+ (NSString*) retrieveCsvCardIdsForTag: (NSInteger)setId;

//! Card methods
+ (Card*) retrieveCardWithSQL: (NSString*) sql;
+ (Card*) retrieveCardByPK: (NSInteger)cardId;
+ (Card*) retrieveCardByLevel: (NSInteger)levelId setId:(NSInteger)setId withRandom: (NSInteger) randomNum;
+ (Card*) hydrateCardByPK: (Card*) card;

//! Array of cards methods
+ (NSMutableArray*) retrieveCardSetWithSQL: (NSString*) sql hydrate:(BOOL)hydrate;
+ (NSMutableArray*) retrieveCardSet: (NSInteger)setId;
// TODO: determine how these next 2 methods are really different?
+ (NSMutableArray*) retrieveCardSetIds: (NSInteger) tagId;
+ (NSMutableArray*) retrieveCardIdsForTagId: (NSInteger)tagId;
+ (NSMutableArray*) retrieveCardSetByLevel: (NSInteger)setId levelId:(NSInteger)levelId;
+ (NSMutableArray*) searchCardsForKeyword: (NSString*) keyword doSlowSearch:(BOOL)slowSearch;
@end