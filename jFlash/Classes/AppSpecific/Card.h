
// Card types, added for import support for now, to be implemented in model later!
#define CARD_TYPE_WORD 0
#define CARD_TYPE_KANA 1
#define CARD_TYPE_KANJI 2
#define CARD_TYPE_DICTIONARY 3
#define CARD_TYPE_SENTENCE 4

#import "FMResultSet.h"

//! Class for an individual card's data, also holds user data ABOUT the card for convenience
@interface Card : NSObject
{
  // Intrinsic card stuff
	NSInteger cardId;               //! PK of the card
	NSString* headword;             //! Japanese headword of a card 
	NSString* headword_en;          //! English headword of a card
	NSString* reading;              //! Japanese kana reading
	NSString* romaji;               //! Romanized reading
	NSString* meaning;              //! Actual English meaning
  
  BOOL isBasicCard;               //! If no, none of the properties below are set
  
	// User history attributes specific to Card
  NSInteger userId;               //! User id associated with the level and counts
	NSInteger levelId;              //! What level this card is in for user userId
  NSInteger wrongCount;           //! How many times this card has been tapped "wrong" by this userId
  NSInteger rightCount;           //! How many times this card has been tapped "right" by this userId
}

- (id) initAsBasicCard;

- (void) simpleHydrate: (FMResultSet*) rs;
- (void) hydrate: (FMResultSet*) rs;
- (void) hydrate: (FMResultSet*) rs simple:(BOOL)includeMeaning;

- (NSString*) meaningWithoutMarkup;
- (NSString*) combinedReadingForSettings;
- (NSString*) readingBasedonSettingsForExpandedSampleSentences;
- (BOOL) hasExampleSentences;

@property (nonatomic) BOOL isBasicCard;
@property (nonatomic) NSInteger cardId;
@property (nonatomic) NSInteger userId;
@property (nonatomic) NSInteger levelId;
@property (nonatomic) NSInteger wrongCount;
@property (nonatomic) NSInteger rightCount;
@property (nonatomic, retain) NSString* headword;
@property (nonatomic, retain) NSString* headword_en;
@property (nonatomic, retain) NSString* reading;
@property (nonatomic, retain) NSString* romaji;
@property (nonatomic, retain) NSString* meaning;

@end