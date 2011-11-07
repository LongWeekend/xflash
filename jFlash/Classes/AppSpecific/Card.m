
#import "Card.h"

@interface Card ()
/**
 * Returns nil if no audio, otherwise a hash containing the keys: "full_reading",
 * and then a key for each syllable of the reading
 * e.g. "peng4" "you5" would be 2 keys with filenames for each key for the card "peng4 you5".
 */
- (NSDictionary*) _audioFilenames;

//! AudioPlayer object for a card
@property (nonatomic, retain) AVAudioPlayer *avPlayer;
@end

@implementation Card 

@synthesize cardId, userId, levelId, _headword, headword_en, hw_reading, _meaning, wrongCount, rightCount;
@synthesize avPlayer = _avPlayer;

#pragma mark - Public getter

- (AVAudioPlayer *)avPlayer
{
  if (!_avPlayer)
  {
    NSDictionary *dict = [self _audioFilenames];
    NSString *fullReading = [dict objectForKey:@"full_reading"];
    if (fullReading)
    {
      NSString *path = [LWEFile createBundlePathWithFilename:fullReading];
      NSURL *url = [NSURL fileURLWithPath:path];
      
      AVAudioPlayer *ap = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:nil];
      [ap setDelegate:self];
      [self setAvPlayer:ap];
      [ap release];
    }
    
  }
  return [[_avPlayer retain] autorelease];
}

#pragma mark - Handy Method

/** Returns the meaning field w/o any HTML markup */
- (NSString*) meaningWithoutMarkup
{
  //Remove HTML from cards.meaning field ... messy!
  NSString *txtStr = nil;
  txtStr = [self._meaning stringByReplacingOccurrencesOfString:@"</dfn><dfn>" withString:@","];
  txtStr = [txtStr stringByReplacingOccurrencesOfString:@"<dfn>" withString:@"("];
  txtStr = [txtStr stringByReplacingOccurrencesOfString:@"</dfn>" withString:@")"];
  txtStr = [txtStr stringByReplacingOccurrencesOfString:@"<li>" withString:@""];
  txtStr = [txtStr stringByReplacingOccurrencesOfString:@"</li>" withString:@"; "];
  txtStr = [txtStr stringByReplacingOccurrencesOfString:@"<ol>" withString:@""];
  txtStr = [txtStr stringByReplacingOccurrencesOfString:@"</ol>" withString:@""];
  txtStr = [txtStr stringByReplacingOccurrencesOfString:@" ; " withString:@"; "];
  return txtStr;
}

- (NSString*) meaning
{
  NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
  if([[settings objectForKey:APP_HEADWORD] isEqualToString:SET_E_TO_J])
  {
    return self._headword;
  }
  else
  {
    return self._meaning;
  }
}

- (NSString *) headword
{
  NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
  if([[settings objectForKey:APP_HEADWORD] isEqualToString:SET_E_TO_J])
  {
    return self.headword_en;
  }
  else
  {
    return self._headword;
  }
}

- (NSString *) reading
{
  return self.hw_reading;
}

#pragma mark - Audio Related

- (BOOL) hasAudio
{
  // TODO: this is stub code (really, a live mock) for Rendy - done by MMA 10.25.2011
  NSInteger result = arc4random() % 2;
  return (BOOL)result;
}

- (NSDictionary *) _audioFilenames
{
  // TODO: this is stub code (really, a live mock) for Rendy - done by MMA 10.25.2011
  NSMutableDictionary *dict = [NSMutableDictionary dictionary];
  [dict setObject:@"foo.mp3" forKey:@"full_reading"];
  return (NSDictionary*)dict;
}

- (void) pronounceWithDelegate:(id)theDelegate
{
  AVAudioPlayer *player = [self avPlayer];
  [player play];
}

#pragma mark - Card Properties

- (BOOL) hasExampleSentences
{
  return NO;
}

/** Takes a sqlite result set and populates the properties of card icluding the maning of the card */
- (void) hydrate:(FMResultSet*)rs
{
	[self hydrate:rs simple:NO];
}

/**
 * Takes a sqlite result set and populates the properties of card. 
 * Gives the freedom of not including the meaning
 */
- (void) hydrate:(FMResultSet*)rs simple:(BOOL)isSimple
{
	self.cardId      = [rs intForColumn:@"card_id"];
	self._headword    = [rs stringForColumn:@"headword"];
	self.hw_reading  = [rs stringForColumn:@"reading"];
	if (isSimple == NO)
	{
		self.headword_en = [rs stringForColumn:@"headword_en"];
		self._meaning  = [rs stringForColumn:@"meaning"];
	}
		
  self.levelId  =    [rs intForColumn:@"card_level"];
  self.userId   =    [rs intForColumn:@"user_id"];
  self.rightCount =  [rs intForColumn:@"right_count"];
  self.wrongCount =  [rs intForColumn:@"wrong_count"];
}

- (BOOL)isEqual:(id)object
{
  if ([object isKindOfClass:[self class]])
  {
    Card *anotherCard = (Card *)object;
    return [anotherCard cardId] == [self cardId];
  }
  return NO;
}


//! Standard dealloc
- (void) dealloc
{
  self.avPlayer = nil;
  
	[_headword release];
	[headword_en release];
	[hw_reading release];
	[_meaning release];
	[super dealloc];
}

@end