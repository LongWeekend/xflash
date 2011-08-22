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
