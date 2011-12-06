
#import "Card.h"

NSString * const kLWEFullReadingKey        = @"lwe_full_reading";
NSString * const kLWESegmentedReadingKey   = @"lwe_segmented_reading";
NSInteger const kLWEUninitializedCardId    = -1;

@interface Card ()
//! AudioPlayer object for a card
@property (nonatomic, retain) LWEAudioQueue *player;
@end

@implementation Card 

@synthesize cardId, userId, levelId, _headword, headword_en, hw_reading, _meaning, wrongCount, rightCount;
@synthesize player = _player, isFault = _isFault;

- (id) init
{
  self = [super init];
  if (self)
  {
    _isFault = YES;
    cardId = kLWEUninitializedCardId;
  }
  return self;
}

#pragma mark - Public getter

- (LWEAudioQueue *)player
{
  if (_player == nil)
  {
    NSDictionary *dict = [self audioFilenames];
    NSString *fullReadingFilename = [dict objectForKey:kLWEFullReadingKey];
    LWEAudioQueue *q = nil;
    if (fullReadingFilename)
    {
      //If the full_reading key exists in the audioFilenames, it means there is an audio file
      // dedicated to this card.  So, just instantiate the AVQueuePlayer with the array
      NSURL *url = [NSURL fileURLWithPath:fullReadingFilename];
      q = [[LWEAudioQueue alloc] initWithItems:[NSArray arrayWithObject:url]];
    }
    else
    {
      NSArray *segmentedReading = [dict objectForKey:kLWESegmentedReadingKey];
      NSMutableArray *items = [NSMutableArray arrayWithCapacity:[dict count]];
      for (NSString *filename in segmentedReading)
      {
        //Construct the filename for its audioFilename filename and instantiate the AVPlayerItem for it. 
        [items addObject:[NSURL fileURLWithPath:filename]];
      }
      // And create the player with the NSArray filled with the AVPlayerItem(s)
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
  return [self headwordIgnoringMode:NO];
}

- (NSString *) headwordIgnoringMode:(BOOL)ignoreMode
{
  if (ignoreMode)
  {
    return self._headword;
  }
  
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
  // It is up to the subclasses to handle this and say yes
  return NO;
}

- (NSDictionary *) audioFilenames
{
  // By default this does nothing, it is up to the subclasses to implement.
  return nil;
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

//! gets a card from the db and hydrates
- (void) hydrate
{
  LWE_ASSERT_EXC(self.cardId != kLWEUninitializedCardId, @"Hydrate called with uninitialized card ID");
  LWEDatabase *db = [LWEDatabase sharedLWEDatabase];
	FMResultSet *rs = [db executeQuery:[NSString stringWithFormat:@"SELECT c.*, h.meaning FROM cards c, cards_html h WHERE c.card_id = h.card_id AND c.card_id = %d LIMIT 1",self.cardId]];
	while ([rs next])
  {
		[self hydrate:rs];
	}
	[rs close];
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
  
  // Now that we have hydrated, note that this object is no longer a fault
  _isFault = NO;
}

- (BOOL)isEqual:(id)object
{
  if ([object isKindOfClass:[self class]])
  {
    Card *anotherCard = (Card *)object;
    return (anotherCard.cardId == self.cardId);
  }
  return NO;
}

#pragma mark - Static Helper for UILabels

+ (UIFont *) configureFontForLabel:(UILabel*)theLabel
{
#if defined (LWE_CFLASH)
  UIFont *theFont = theLabel.font;
  CGFloat currSize = theFont.pointSize;
  if (currSize == 0)
  {
    // Use default if not set
    currSize = FONT_SIZE_CELL_HEADWORD;
  }
  NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
  
  // Don't change anything about the font if we're in English headword mode
  if ([[settings objectForKey:APP_HEADWORD] isEqualToString:SET_J_TO_E])
  {
    if ([[settings objectForKey:APP_HEADWORD_TYPE] isEqualToString:SET_HEADWORD_TYPE_TRAD])
    {
      theFont = [UIFont fontWithName:@"STHeitiTC-Medium" size:currSize];
    }
    else
    {
      theFont = [UIFont fontWithName:@"STHeitiSC-Medium" size:currSize];
    }
  }
  return theFont;
#else
  return theLabel.font;
#endif
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