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

- (void) simpleHydrate: (FMResultSet*) rs
{
  [super simpleHydrate:rs];
  self._headword = [rs stringForColumn:@"headword_trad"];
  self.headword_simp = [rs stringForColumn:@"headword_simp"];
}

- (void) hydrate:(FMResultSet*)rs simple:(BOOL)isSimple
{
  [super hydrate:rs simple:isSimple];
  self._headword = [rs stringForColumn:@"headword_trad"];
  self.headword_simp = [rs stringForColumn:@"headword_simp"];
}

- (void) hydrate:(FMResultSet*)rs
{
  [super hydrate:rs];
  self._headword = [rs stringForColumn:@"headword_trad"];
  self.headword_simp = [rs stringForColumn:@"headword_simp"];
}


- (NSAttributedString*) attributedReading
{
  // From Wikipedia:
  // the de facto standard has been to use red (tone 1), orange (tone 2), green (tone 3), blue (tone 4) and black (tone 5).[24]
  NSDictionary *colorDict = [NSDictionary dictionaryWithObjectsAndKeys:[UIColor redColor],@"1",[UIColor orangeColor],@"2",[UIColor greenColor],@"3",[UIColor blueColor],@"4",nil];
  
  NSMutableAttributedString *coloredString = [[[[NSAttributedString alloc] initWithString:@""] autorelease] mutableCopy];
  NSArray *pinyinSegments = [self.reading componentsSeparatedByString:@" "];
  for (NSString *pinyinSegment in pinyinSegments)
  {
    // First determine the color we need (default to black)
    UIColor *theColor = [UIColor blackColor];
    for (NSString *toneNumber in colorDict)
    {
      NSRange range = [pinyinSegment rangeOfString:toneNumber];
      if (range.location != NSNotFound)
      {
        theColor = (UIColor*)[colorDict objectForKey:toneNumber];
        break;
      }
    }
    
    // Now append the string and the color to the total string
    NSDictionary *attributesDict = [NSDictionary dictionaryWithObjectsAndKeys:(void*)theColor.CGColor,(NSString*)kCTForegroundColorAttributeName, nil];
    NSAttributedString *tempStr = [[NSAttributedString alloc] initWithString:pinyinSegment attributes:attributesDict];
    [coloredString appendAttributedString:tempStr];
    [tempStr release];
  }
  return [coloredString autorelease];
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
