#import "Card.h"
#import "ExampleSentencePeer.h"

@implementation Card 

@synthesize cardId, userId, levelId, headword, headword_en, reading, romaji, meaning, wrongCount, rightCount, isBasicCard;

/** Customized initializer setting all variables to zero or nil */
- (id) init
{
  self = [super init];
  if (self)
  {
    self.wrongCount = 0;
    self.rightCount = 0;
    self.cardId = 0;
    self.userId = 0;
    self.levelId = 0;
    self.headword = nil;
    self.headword_en = nil;
    self.reading = nil;
    self.romaji = nil;
    self.meaning = nil;
    self.isBasicCard = NO;
  }
  return self;
}


/** Initializes this card as a card that does not have user history info */
- (id) initAsBasicCard
{
  self = [self init];
  if (self)
  {
    self.isBasicCard = YES;
  }
  return self;
}


/** Returns the meaning field w/o any HTML markup */
- (NSString*) meaningWithoutMarkup
{
  //Remove HTML from cards.meaning field ... messy!
  NSString* txtStr;
  txtStr = [self.meaning stringByReplacingOccurrencesOfString:@"</dfn><dfn>" withString:@","];
  txtStr = [txtStr stringByReplacingOccurrencesOfString:@"<dfn>" withString:@"("];
  txtStr = [txtStr stringByReplacingOccurrencesOfString:@"</dfn>" withString:@")"];
  txtStr = [txtStr stringByReplacingOccurrencesOfString:@"<li>" withString:@""];
  txtStr = [txtStr stringByReplacingOccurrencesOfString:@"</li>" withString:@"; "];
  txtStr = [txtStr stringByReplacingOccurrencesOfString:@"<ol>" withString:@""];
  txtStr = [txtStr stringByReplacingOccurrencesOfString:@"</ol>" withString:@""];
  txtStr = [txtStr stringByReplacingOccurrencesOfString:@" ; " withString:@"; "];
  return txtStr;
}


/** depending on APP_READING value in settings, will return a combined headword */
- (NSString*) combinedReadingForSettings
{
  NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
  NSString *combined_reading;
  
  // Mux the readings according to user preference
  if([[settings objectForKey:APP_READING] isEqualToString:SET_READING_KANA])
  {
    combined_reading = [NSString stringWithFormat:@"%@", [self reading]];
  } 
  else if([[settings objectForKey:APP_READING] isEqualToString: SET_READING_ROMAJI])
  {
    combined_reading = [NSString stringWithFormat:@"%@", [self romaji]];
  }
  else
  {
    // Both together
    combined_reading = [NSString stringWithFormat:@"%@\n%@", [self reading], [self romaji]];
  }
  
  return combined_reading;
}


/** Returns YES if a card has example sentences attached to it */
- (BOOL) hasExampleSentences
{
  // Get settings to determine what data versio we are on
  NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
  
  if([[settings objectForKey:APP_DATA_VERSION] isEqualToString:JFLASH_VERSION_1_0]) // version 1 doesn't understand this so say NO
  {
    return NO;
  }
  else if (![[[CurrentState sharedCurrentState] pluginMgr] pluginIsLoaded:EXAMPLE_DB_KEY]) // we always have a sentence if the plugin is not installed
  {
    return YES;
  }
  else 
  {
    return [ExampleSentencePeer sentencesExistForCardId:[self cardId]];
  }
}


/** Takes a sqlite result set and populates the properties of card */
- (void) hydrate: (FMResultSet*) rs
{
	self.cardId   =    [rs intForColumn:@"card_id"];
	self.headword =    [rs stringForColumn:@"headword"];
	self.headword_en = [rs stringForColumn:@"headword_en"];
	self.reading  =    [rs stringForColumn:@"reading"];
	self.romaji  =     [rs stringForColumn:@"romaji"];
	self.meaning  =    [rs stringForColumn:@"meaning"];
  
  // Get additional stuff if we're going to have it
  if (self.isBasicCard == NO)
  {
    self.levelId  =    [rs intForColumn:@"card_level"];
    self.userId   =    [rs intForColumn:@"user_id"];
    self.rightCount =  [rs intForColumn:@"right_count"];
    self.wrongCount =  [rs intForColumn:@"wrong_count"];
  }
}


//! Standard dealloc
- (void) dealloc
{
	[romaji release];
	[headword release];
	[headword_en release];
	[reading release];
	[meaning release];
	[super dealloc];
}

@end