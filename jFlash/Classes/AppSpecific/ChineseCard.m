//
//  ChineseCard.m
//  jFlash
//
//  Created by Mark Makdad on 8/21/11.
//  Copyright 2011 Long Weekend LLC. All rights reserved.
//

#import "ChineseCard.h"
#import <CoreText/CoreText.h>

@implementation ChineseCard

@synthesize headword_simp;

- (void) hydrate:(FMResultSet*)rs
{
  [self hydrate:rs simple:NO];
  self._headword = [rs stringForColumn:@"headword_trad"];
  self.headword_simp = [rs stringForColumn:@"headword_simp"];
}

- (void) hydrate:(FMResultSet*)rs simple:(BOOL)isSimple
{
  [super hydrate:rs simple:isSimple];
  self._headword = [rs stringForColumn:@"headword_trad"];
  self.headword_simp = [rs stringForColumn:@"headword_simp"];
}

/**
 * Takes something like "gao4" and converts it to "gáo"
 */
- (NSString*) _pinyinForNumberedPinyin:(NSString*)numberedPinyin
{
  // Quick return on bad string input/nil input
  if ([numberedPinyin length] == 0)
  {
    return nil;
  }

  // Another quick return if we don't have a valid tone number - we will use toneNumber later too
  NSInteger toneNumber = [[numberedPinyin substringFromIndex:([numberedPinyin length]-1)] integerValue];
  if (toneNumber == 0 || toneNumber > 5)
  {
    return numberedPinyin;
  }
  
  //Replace the u: with ü (u umlaud)
  numberedPinyin = [numberedPinyin stringByReplacingOccurrencesOfString:@"u:" withString:@"ü"];
  

  // Define some regexes that are going to help us
  NSError *error = NULL;
  NSRegularExpression *vocalRegex = [NSRegularExpression regularExpressionWithPattern:@"[aeiouü]" options:NSRegularExpressionCaseInsensitive error:&error];
  NSRegularExpression *diacriticRegex1 = [NSRegularExpression regularExpressionWithPattern:@"[ae]" options:NSRegularExpressionCaseInsensitive error:&error];
  NSRegularExpression *diacriticRegex2 = [NSRegularExpression regularExpressionWithPattern:@"[ou]" options:NSRegularExpressionCaseInsensitive error:&error];
  
  // Now get the number of vowels in the reading to determine where the diacritic mark goes
  NSString *reading = [numberedPinyin substringToIndex:([numberedPinyin length]-1)];
  NSRange readingRange = NSMakeRange(0,[reading length]);
  NSString *vowel = nil;
  NSArray *vowels = [vocalRegex matchesInString:reading options:0 range:readingRange];
  if ([vowels count] == 1)
  {
    vowel = [reading substringWithRange:[[vowels objectAtIndex:0] range]];
  }
  else if ([vowels count] > 1)
  {
    // OK, so there is more than one vowel, so we need to figure out which one to add the diacritic
    NSArray *patternVowels = [diacriticRegex1 matchesInString:reading options:0 range:readingRange];
    if ([patternVowels count] > 0)
    {
      // OK, we matched the first diacritic Regex
      vowel = [reading substringWithRange:[[patternVowels objectAtIndex:0] range]];
    }
    else
    {
      // Nope, let's try the second one.
      patternVowels = [diacriticRegex2 matchesInString:reading options:0 range:readingRange];
      if ([patternVowels count] > 0)
      {
        vowel = [reading substringWithRange:[[patternVowels objectAtIndex:0] range]];
      }
    }
    
    // Assuming we have a vowel now, get the first letter.
    if (vowel)
    {
      vowel = [vowel substringToIndex:1];
    }
    else
    {
      vowel = [vowels objectAtIndex:1];
    }
  }
  
  // OK, now swap the vowel if we have one.
  if (vowel)
  {
    // TODO: consider caching this dictionary, it's probably expensive.
    NSDictionary *diacriticDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                   @"ā",@"a1",@"ē",@"e1",@"ī",@"i1",@"ō",@"o1",@"ū",@"u1",@"ǖ",@"ü1",
                                   @"á",@"a2",@"é",@"e2",@"í",@"i2",@"ó",@"o2",@"ú",@"u2",@"ǘ",@"ü2",
                                   @"ǎ",@"a3",@"ě",@"e3",@"ǐ",@"i3",@"ǒ",@"o3",@"ǔ",@"u3",@"ǚ",@"ü3",
                                   @"à",@"a4",@"è",@"e4",@"ì",@"i4",@"ò",@"o4",@"ù",@"u4",@"ǜ",@"ü4",
                                   nil];
    if (toneNumber < 5)
    {
      NSString *key = [NSString stringWithFormat:@"%@%d",[vowel lowercaseString],toneNumber];
      NSString *newVowel = [diacriticDict objectForKey:key];
      reading = [reading stringByReplacingOccurrencesOfString:vowel withString:newVowel];
    }
  }
  return reading;
}

- (NSArray *) readingComponents
{
  NSMutableArray *components = [NSMutableArray array];
  // From Wikipedia:
  // the de facto standard has been to use red (tone 1), orange (tone 2), green (tone 3), blue (tone 4) and black (tone 5).[24]
  NSDictionary *colorDict = [NSDictionary dictionaryWithObjectsAndKeys:
                             [UIColor redColor],@"1",
                             [UIColor orangeColor],@"2",
                             [UIColor greenColor],@"3",
                             [UIColor cyanColor],@"4",nil];
  
  NSArray *pinyinSegments = [self.reading componentsSeparatedByString:@" "];
  for (NSString *pinyinSegment in pinyinSegments)
  {
    // Are we using color?  If not...
    UIColor *theColor = nil;
    NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
    BOOL useColor = [[settings objectForKey:APP_PINYIN_COLOR] isEqualToString:SET_PINYIN_COLOR_ON];
    
    if (useColor)
    {
      // First determine the color we need (default to white)
      theColor = [UIColor whiteColor];
      for (NSString *toneNumber in colorDict)
      {
        NSRange range = [pinyinSegment rangeOfString:toneNumber];
        if (range.location != NSNotFound)
        {
          theColor = (UIColor*)[colorDict objectForKey:toneNumber];
          break;
        }
      }
    }
    else
    {
      theColor = [UIColor whiteColor];
    }
    
    // Now pinyin-ify the string
    pinyinSegment = [self _pinyinForNumberedPinyin:pinyinSegment];
    
    NSDictionary *pinyinHash = [NSDictionary dictionaryWithObjectsAndKeys:theColor,@"color",pinyinSegment,@"pinyin",nil];
    [components addObject:pinyinHash];
  }
  return components;
}

- (NSString *) pinyinReading
{
  NSArray *pinyinSegments = [self.reading componentsSeparatedByString:@" "];
  NSUInteger resultLength = [self.reading length] - [pinyinSegments count] + 1;
  NSMutableString *result = [NSMutableString stringWithCapacity:resultLength];
                             
  for (NSString *pinyinSegment in pinyinSegments)
  {
    // Now pinyin-ify the string
    pinyinSegment = [self _pinyinForNumberedPinyin:pinyinSegment];
    [result appendFormat:@"%@ ", pinyinSegment];
  }
  
  NSRange lastCharacter = (NSRange){[result length]-1,1};
  [result deleteCharactersInRange:lastCharacter];
  return result;
}

- (NSDictionary *) audioFilenames
{
  //TODO: This method is a stub mock (live mock, really) for Rendy - by MMA 10.25.2011
  //NSMutableDictionary *dict = [[[super audioFilenames] mutableCopy] autorelease];
  NSArray *pinyinSegments = [self.reading componentsSeparatedByString:@" "];
  NSMutableDictionary *dict = [[[NSMutableDictionary alloc] initWithCapacity:pinyinSegments.count] autorelease];
  for (NSString *pinyin in pinyinSegments)
  {
    [dict setObject:@"foo.mp3" forKey:pinyin];
  }
  
  return (NSDictionary*)dict;
}



- (NSString *) headword
{
  NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
  NSString *type = [settings objectForKey:APP_HEADWORD_TYPE];

  NSString *hw = nil;
  
  // TODO: ALSO PUT ENGLISH HEADWORD IN HERE
  
  if ([type isEqualToString:SET_HEADWORD_TYPE_TRAD])
  {
    hw = self._headword;
  } 
  else if ([type isEqualToString:SET_HEADWORD_TYPE_SIMP])
  {
    hw = self.headword_simp;
  }
  return hw;
}

- (void) dealloc
{
  [headword_simp release];
  [super dealloc];
}


@end
