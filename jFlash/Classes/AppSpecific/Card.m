
#import "Card.h"

static NSString *const kFullReadingKey    = @"full_reading";
static NSString *const kStatusAVPlayerKey = @"status";

@interface Card ()
//! AudioPlayer object for a card
@property (nonatomic, retain) AVQueuePlayer *player;
@end

@implementation Card 

@synthesize cardId, userId, levelId, _headword, headword_en, hw_reading, _meaning, wrongCount, rightCount;
@synthesize player = _player;

#pragma mark - Public getter

- (AVQueuePlayer *)player
{
  if (!_player)
  {
    NSDictionary *dict = [self audioFilenames];
    NSString *fullReading = [dict objectForKey:kFullReadingKey];
    AVQueuePlayer *q = nil;
    if (fullReading)
    {
      //If the full_reading key exists in the audioFilenames, 
      //means there is an audio file dedicated to this card. 
      //So, just instantiate the AVQueuePlayer with the array
      NSURL *url = [NSURL fileURLWithPath:[LWEFile createBundlePathWithFilename:fullReading]];
      AVPlayerItem *item = [AVPlayerItem playerItemWithURL:url];
      q = [[AVQueuePlayer alloc] initWithItems:[NSArray arrayWithObject:item]];
    }
    else
    {
      NSMutableArray *items = [[NSMutableArray alloc] initWithCapacity:[dict count]];
      //Enumerate the dict which is filled with the filename(s) associated with a card-pinyin
      [dict enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        //Construct the filename for its audioFilename filename
        //and instantiate the AVPlayerItem for it. 
        NSString *filename = (NSString *)obj;
        NSURL *url = [NSURL fileURLWithPath:[LWEFile createBundlePathWithFilename:filename]];
        AVPlayerItem *item = [AVPlayerItem playerItemWithURL:url];
        //Add the AVPlayerItem object to the NSArray.
        [items addObject:item];
      }];
      //And create the player with the NSArray filled with the AVPlayerItem(s)
      q = [[AVQueuePlayer alloc] initWithItems:items];
    }
    
    [[NSNotificationCenter defaultCenter] addObserverForName:AVPlayerItemDidPlayToEndTimeNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
      if ([[note object] isKindOfClass:[AVPlayerItem class]])
      {
        AVPlayerItem *p = [note object];
        [p seekToTime:kCMTimeZero];

        NSLog(@"FINISH PLAYING WITH : %@", p);
      }
      
    }];
    [q setActionAtItemEnd:AVPlayerActionAtItemEndPause];
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
  [dict setObject:@"foo.mp3" forKey:@"full_reading"];
  return (NSDictionary*)dict;
}

- (void) pronounceWithDelegate:(id)theDelegate
{
//  AVQueuePlayer *queue = self.player;
//  if (queue.status == AVPlayerStatusReadyToPlay)
//  {
//    [self.player play];
//  }
//  else
//  {
//    [self.player addObserver:self forKeyPath:kStatusAVPlayerKey options:NSKeyValueObservingOptionNew context:NULL];
//  }
  
  NSDictionary *dict = [self audioFilenames];
  NSString *fullReading = [dict objectForKey:kFullReadingKey];
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
    NSMutableArray *items = [[NSMutableArray alloc] initWithCapacity:[dict count]];
    //Enumerate the dict which is filled with the filename(s) associated with a card-pinyin
    [dict enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
      //Construct the filename for its audioFilename filename
      //and instantiate the AVPlayerItem for it. 
      NSString *filename = (NSString *)obj;
      NSURL *url = [NSURL fileURLWithPath:[LWEFile createBundlePathWithFilename:filename]];
      [items addObject:url];
    }];
    //And create the player with the NSArray filled with the AVPlayerItem(s)
    q = [[LWEAudioQueue alloc] initWithItems:items];
  }

  [q play];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
  if ((object == self.player) && ([keyPath isEqualToString:kStatusAVPlayerKey]))
  {
    if ([self.player status] == AVPlayerStatusReadyToPlay)
    {
      [self.player play];
      [self.player removeObserver:self forKeyPath:@"status"];
    }
  }
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
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  self.player = nil;
  
	[_headword release];
	[headword_en release];
	[hw_reading release];
	[_meaning release];
	[super dealloc];
}

@end