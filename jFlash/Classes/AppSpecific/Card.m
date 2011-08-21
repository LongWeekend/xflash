#import "Card.h"

@implementation Card 

@synthesize cardId, userId, levelId, _headword, headword_en, hw_reading, meaning, wrongCount, rightCount, isBasicCard;

/** Returns the meaning field w/o any HTML markup */
- (NSString*) meaningWithoutMarkup
{
  //Remove HTML from cards.meaning field ... messy!
  NSString *txtStr = nil;
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

- (NSString *) headword
{
  return self._headword;
}

- (NSString *) reading
{
  return self.hw_reading;
}

- (BOOL) hasExampleSentences
{
  return NO;
}

/** Takes a sqlite result set and populates the properties of card WITHOUT the maning of the card */
- (void) simpleHydrate: (FMResultSet*) rs
{
	[self hydrate:rs simple:YES];
}

/** Takes a sqlite result set and populates the properties of card icluding the maning of the card */
- (void) hydrate: (FMResultSet*) rs
{
	[self hydrate:rs simple:NO];
}


/** Takes a sqlite result set and populates the properties of card. Gives the freedom of not including the meaning */
- (void) hydrate:(FMResultSet*)rs simple:(BOOL)isSimple
{
	self.cardId      = [rs intForColumn:@"card_id"];
	self._headword    = [rs stringForColumn:@"headword"];
	self.hw_reading  = [rs stringForColumn:@"reading"];
	if (isSimple == NO)
	{
		self.headword_en = [rs stringForColumn:@"headword_en"];
		self.meaning  = [rs stringForColumn:@"meaning"];
	}
		
	// Get additional stuff if we're going to have it
	if (self.isBasicCard == NO)
	{
		self.levelId  =    [rs intForColumn:@"card_level"];
		self.userId   =    [rs intForColumn:@"user_id"];
		self.rightCount =  [rs intForColumn:@"right_count"];
		self.wrongCount =  [rs intForColumn:@"wrong_count"];
	}
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
	[_headword release];
	[headword_en release];
	[hw_reading release];
	[meaning release];
	[super dealloc];
}

@end