#import "Card.h"

@implementation Card 

@synthesize cardId, userId, levelId, headword, headword_en, reading, romaji, meaning, wrongCount, rightCount;

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
  }
  return self;
}

- (NSString*) meaningWithoutMarkup {
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

// TODO : make this actually implemented
- (BOOL) hasExampleSentences
{
  int r = rand() % 2;
  if(r == 1) return YES;
  return NO;
}


// Takes a sqlite result set and populates the properties of card
- (void) hydrate: (FMResultSet*) rs
{
  self.levelId  =    [rs intForColumn:@"card_level"];
	self.userId   =    [rs intForColumn:@"user_id"];
	self.cardId   =    [rs intForColumn:@"card_id"];
	self.headword =    [rs stringForColumn:@"headword"];
	self.headword_en = [rs stringForColumn:@"headword_en"];
	self.reading  =    [rs stringForColumn:@"reading"];
	self.romaji  =     [rs stringForColumn:@"romaji"];
	self.meaning  =    [rs stringForColumn:@"meaning"];
  self.rightCount =  [rs intForColumn:@"right_count"];
  self.wrongCount =  [rs intForColumn:@"wrong_count"];
}


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