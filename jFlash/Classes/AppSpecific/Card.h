
// Card types, added for import support for now, to be implemented in model later!
#define CARD_TYPE_WORD 0
#define CARD_TYPE_KANA 1
#define CARD_TYPE_KANJI 2
#define CARD_TYPE_DICTIONARY 3
#define CARD_TYPE_SENTENCE 4

#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>
#import "FMResultSet.h"
#import "LWEAudioQueue.h"
#import "PluginManager.h"

extern NSString * const kLWEFullReadingKey;
extern NSString * const kLWESegmentedReadingKey;
extern NSInteger const kLWEUninitializedCardId;

//! Class for an individual card's data, also holds user data ABOUT the card for convenience
@interface Card : NSObject <AVAudioPlayerDelegate>

- (void) hydrate;
- (void) hydrateWithResultSet:(FMResultSet*)rs;
- (void) hydrateWithResultSet:(FMResultSet*)rs simpleHydrate:(BOOL)includeMeaning;

//! Returns the reading of the card
- (NSString*) reading;

//! Returns the reading of the card, with any special attributes (color, links etc)
- (NSAttributedString *) attributedReading;

// Returns the headword, taking into account the app's current HW Mode setting
- (NSString*) headword;

// If ignoreMode == YES, returns the "headword" regardless of HW Mode
- (NSString *) headwordIgnoringMode:(BOOL)ignoreMode;

- (NSString*) meaning;

//! Returns the meaning stripped of HTML
- (NSString*) meaningWithoutMarkup;

- (BOOL) hasExampleSentencesWithPluginManager:(PluginManager *)mgr;

//! Returns YES if the card has audio data associated with it (accessible from -audioFilenames hash)
- (BOOL) hasAudioWithPluginManager:(PluginManager *)mgr;

- (void) pronounceWithDelegate:(id)theDelegate pluginManager:(PluginManager *)pluginManager;

/**
 * Returns nil if no audio, otherwise a hash containing the keys: "full_reading",
 * and then a key for each syllable of the reading
 * e.g. "peng4" "you5" would be 2 keys with filenames for each key for the card "peng4 you5".
 */
- (NSDictionary *) audioFilenamesWithPluginManager:(PluginManager *)mgr;

/**
 * Pass a UILabel with text through this method when you want to
 * update the label's font with whatever the app's setting for glyph type is
 * (e.g. in Chinese case, traditional or simplified).
 */
+ (UIFont *) configureFontForLabel:(UILabel*)theLabel;

//! If YES, this Card object isn't really a card -- jsut has an ID and hasn't been fetched.
@property (readonly) BOOL isFault;

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
@property (nonatomic, retain) NSString *_meaning;

@end



