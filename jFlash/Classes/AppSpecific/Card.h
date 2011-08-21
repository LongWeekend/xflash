
// Card types, added for import support for now, to be implemented in model later!
#define CARD_TYPE_WORD 0
#define CARD_TYPE_KANA 1
#define CARD_TYPE_KANJI 2
#define CARD_TYPE_DICTIONARY 3
#define CARD_TYPE_SENTENCE 4

#import "FMResultSet.h"

//! Class for an individual card's data, also holds user data ABOUT the card for convenience
@interface Card : NSObject

- (void) simpleHydrate: (FMResultSet*) rs;
- (void) hydrate: (FMResultSet*) rs;
- (void) hydrate: (FMResultSet*) rs simple:(BOOL)includeMeaning;

- (NSString*) reading;
- (NSString*) headword;

- (NSString*) meaningWithoutMarkup;
- (BOOL) hasExampleSentences;

@property (nonatomic) BOOL isBasicCard;
//! PK of the card
@property (nonatomic) NSInteger cardId;

//! User id associated with the level and counts
@property (nonatomic) NSInteger userId;

//! What level this card is in for user userId
@property (nonatomic) NSInteger levelId;

//! How many times this card has been tapped "wrong" by this userId
@property (nonatomic) NSInteger wrongCount;

//! How many times this card has been tapped "right" by this userId
@property (nonatomic) NSInteger rightCount;

//! Japanese headword of a card 
@property (nonatomic, retain) NSString *_headword;

//! English headword of a card
@property (nonatomic, retain) NSString *headword_en;

//! reading, like kana or pinyin, depending
@property (nonatomic, retain) NSString *hw_reading;

//! Actual English meaning
@property (nonatomic, retain) NSString *meaning;

@end