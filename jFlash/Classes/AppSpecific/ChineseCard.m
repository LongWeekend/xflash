//
//  ChineseCard.m
//  jFlash
//
//  Created by Mark Makdad on 8/21/11.
//  Copyright 2011 Long Weekend LLC. All rights reserved.
//

#import "ChineseCard.h"


@implementation ChineseCard

@synthesize headword_simp;

- (NSString *) headword
{
  NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
  NSString *hw = nil;
  
  if ([[settings objectForKey:APP_READING] isEqualToString:SET_READING_KANA])
  {
    hw = self._headword;
  } 
  else if ([[settings objectForKey:APP_READING] isEqualToString: SET_READING_ROMAJI])
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
