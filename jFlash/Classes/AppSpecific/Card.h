
// Card types, added for import support for now, to be implemented in model later!
#define CARD_TYPE_WORD 0
#define CARD_TYPE_KANA 1
#define CARD_TYPE_KANJI 2
#define CARD_TYPE_DICTIONARY 3
#define CARD_TYPE_SENTENCE 4

//! Class for an individual card's data
@interface Card : NSObject
{
	NSInteger userId;
	NSInteger cardId;
	NSInteger levelId;
  NSInteger wrongCount;
  NSInteger rightCount;
	NSString* headword;
	NSString* headword_en;
	NSString* reading;
	NSString* romaji;
	NSString* meaning;
}

- (void) hydrate: (FMResultSet*) rs;
- (NSString*) meaningWithoutMarkup;
- (NSString*) combinedReadingForSettings;
- (BOOL) hasExampleSentences;
//- (void) setLevel: (FMResultSet*) rs;

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