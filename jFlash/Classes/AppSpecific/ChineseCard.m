//
//  ChineseCard.m
//  jFlash
//
//  Created by Mark Makdad on 8/21/11.
//  Copyright 2011 Long Weekend LLC. All rights reserved.
//

#import "ChineseCard.h"
#import <CoreText/CoreText.h>
#import "Plugin.h"
#import "PluginManager.h"

@interface ChineseCard ()
- (NSArray *) _pinyinAudioFilenamesWithPlugin:(Plugin *)pinyinPlugin;
- (NSString *) _fullAudioFilenameWithPlugin:(Plugin *)hskPlugin;
@end

@implementation ChineseCard

@synthesize headword_simp;

- (void) hydrateWithResultSet:(FMResultSet*)rs
{
  [self hydrateWithResultSet:rs simpleHydrate:NO];
  self._headword = [rs stringForColumn:@"headword_trad"];
  self.headword_simp = [rs stringForColumn:@"headword_simp"];
}

- (void) hydrateWithResultSet:(FMResultSet*)rs simpleHydrate:(BOOL)isSimple
{
  [super hydrateWithResultSet:rs simpleHydrate:isSimple];
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

- (NSAttributedString *) attributedReading
{
  NSMutableAttributedString *attrString = [[[[NSAttributedString alloc] init] autorelease] mutableCopy];
  NSArray *readingHashes = [self readingComponents];
  for (NSDictionary *readingHash in readingHashes)
  {
    NSString *stringToAppend = [NSString stringWithFormat:@"%@ ",[readingHash objectForKey:@"pinyin"]];
    NSMutableAttributedString *tmpAttrString = [[[[NSAttributedString alloc] initWithString:stringToAppend] autorelease] mutableCopy];
    NSRange allRange = NSMakeRange(0, [stringToAppend length]);
    [tmpAttrString addAttribute:(NSString *)kCTForegroundColorAttributeName
                          value:(id)[(UIColor*)[readingHash objectForKey:@"color"] CGColor]
                          range:allRange];
    [attrString appendAttributedString:tmpAttrString];
    [tmpAttrString release];
  }
  
  return [attrString autorelease];
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

#pragma mark - Audio Related

- (BOOL) hasAudioWithPluginManager:(PluginManager *)pluginManager
{
  // Quick return if they have pinyin installed, saves us from searching for their card in HSK
  if ([pluginManager pluginKeyIsLoaded:AUDIO_PINYIN_KEY])
  {
    return YES;
  }
  else
  {
    // If have a filename we have audio -- TODO maybe cache this value?
    Plugin *hskPlugin = [pluginManager pluginForKey:AUDIO_HSK_KEY];
    return ([self _fullAudioFilenameWithPlugin:hskPlugin] != nil);
  }
}

- (NSDictionary *) audioFilenamesWithPluginManager:(PluginManager *)mgr
{
  Plugin *pinyinPlugin = [mgr pluginForKey:AUDIO_PINYIN_KEY];
  Plugin *hskPlugin = [mgr pluginForKey:AUDIO_HSK_KEY];
  NSMutableDictionary *audioFilenames = [NSMutableDictionary dictionaryWithCapacity:2];
  [audioFilenames setValue:[self _pinyinAudioFilenamesWithPlugin:pinyinPlugin] forKey:kLWESegmentedReadingKey];
  [audioFilenames setValue:[self _fullAudioFilenameWithPlugin:hskPlugin] forKey:kLWEFullReadingKey];
  return (NSDictionary*)audioFilenames;
}

- (NSString *) _fullAudioFilenameWithPlugin:(Plugin *)hskPlugin
{
  // Quick return if we don't have the full audio plugin
  if (hskPlugin == nil)
  {
    return nil;
  }
  
  // OK, we have it, so search for the file
  NSString *filename = [[hskPlugin fullPath] stringByAppendingFormat:@"%@.mp3",self.headword_simp];
  if ([LWEFile fileExists:filename])
  {
    return filename;
  }
  else
  {
    return nil;
  }
}

- (NSArray *) _pinyinAudioFilenamesWithPlugin:(Plugin *)pinyinPlugin
{
  LWE_ASSERT_EXC(pinyinPlugin, @"We shouldn't be asking for filenames if the plugin isn't loaded");
  NSArray *pinyinSegments = [self.reading componentsSeparatedByString:@" "];
  NSMutableArray *audioArray = [NSMutableArray array];
  for (NSString *pinyin in pinyinSegments)
  {
    // Note there is no checking here for whether the file exists
    NSString *filename = [[pinyinPlugin fullPath] stringByAppendingFormat:@"%@.mp3",[pinyin lowercaseString]];
    [audioArray addObject:filename];
  }
  return (NSArray *)audioArray;
}

#pragma mark -

// -headword will call this automatically with a value of NO
- (NSString *) headwordIgnoringMode:(BOOL)ignoreMode
{
  NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
  NSString *type = [settings objectForKey:APP_HEADWORD_TYPE];

  NSString *hw = nil;
  if ([type isEqualToString:SET_HEADWORD_TYPE_TRAD])
  {
    hw = self._headword;
  } 
  else if ([type isEqualToString:SET_HEADWORD_TYPE_SIMP])
  {
    hw = self.headword_simp;
  }
  
  // Only run this code if we're not ignoring
  if (ignoreMode == NO)
  {
    if([[settings objectForKey:APP_HEADWORD] isEqualToString:SET_E_TO_J])
    {
      hw = self.headword_en;
    }
  }
  
  return hw;
}


#pragma mark - Class Plumbing

- (void) dealloc
{
  [headword_simp release];
  [super dealloc];
}


@end
