
#import "Card.h"

NSString *const kLWEFullReadingKey        = @"lwe_full_reading";
NSString *const kLWESegmentedReadingKey   = @"lwe_segmented_reading";

@interface Card ()
//! AudioPlayer object for a card
@property (nonatomic, retain) LWEAudioQueue *player;
@end

@implementation Card 

@synthesize cardId, userId, levelId, _headword, headword_en, hw_reading, _meaning, wrongCount, rightCount;
@synthesize player = _player;

#pragma mark - Public getter

- (LWEAudioQueue *)player
{
  if (!_player)
  {
    NSDictionary *dict = [self audioFilenames];
    NSString *fullReading = [dict objectForKey:kLWEFullReadingKey];
    LWEAudioQueue *q = nil;
    if (fullReading)
    {
      //If the full_reading key exists in the audioFilenames, 
      //means there is an audio file dedicated to this card. 
      //So, just instantiate the AVQueuePlayer with the array
      NSURL *url = [NSURL fileURLWithPath:[LWEFile createBundlePathWithFilename:fullReading]];
      q = [[LWEAudioQueue alloc] initWithItems:[NSArray arrayWithObject:url]];
    }
    else
    {
      NSArray *segmentedReading = [dict objectForKey:kLWESegmentedReadingKey];
      NSMutableArray *items = [[NSMutableArray alloc] initWithCapacity:[dict count]];
      //Enumerate the dict which is filled with the filename(s) associated with a card-pinyin
      [segmentedReading enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        //Construct the filename for its audioFilename filename
        //and instantiate the AVPlayerItem for it. 
        NSString *filename = (NSString *)obj;
        NSURL *url = [NSURL fileURLWithPath:[LWEFile createBundlePathWithFilename:filename]];
        [items addObject:url];
      }];
      //And create the player with the NSArray filled with the AVPlayerItem(s)
      q = [[LWEAudioQueue alloc] initWithItems:items];
    }
    
    self.player = q;
    [q release];
  }
  return [[_player retain] autorelease];
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

- (NSDictionary *) audioFilenames
{
  // TODO: this is stub code (really, a live mock) for Rendy - done by MMA 10.25.2011
  NSMutableDictionary *dict = [NSMutableDictionary dictionary];
  [dict setObject:@"foo.mp3" forKey:kLWEFullReadingKey];
  return (NSDictionary*)dict;
}

- (void) pronounceWithDelegate:(id)theDelegate
{
  LWEAudioQueue *q = self.player;
  q.delegate = theDelegate;
  [q play];
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

#pragma mark - Static Helper for UILabels

+ (UIFont *) configureFontForLabel:(UILabel*)theLabel
{
  UIFont *theFont = theLabel.font;
#if defined (LWE_CFLASH)
  CGFloat currSize = theLabel.font.pointSize;
  NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
  if ([[settings objectForKey:APP_HEADWORD_TYPE] isEqualToString:SET_HEADWORD_TYPE_TRAD])
  {
    theFont = [UIFont fontWithName:@"STHeitiTC-Medium" size:currSize];
  }
  else
  {
    theFont = [UIFont fontWithName:@"STHeitiSC-Medium" size:currSize];
  }
#endif
  return theFont;
}


#pragma mark - Class Plumbing

//! Standard dealloc
- (void) dealloc
{
  self.player = nil;
  
	[_headword release];
	[headword_en release];
	[hw_reading release];
	[_meaning release];
	[super dealloc];
}

@end