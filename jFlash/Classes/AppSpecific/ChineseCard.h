//
//  ChineseCard.h
//  jFlash
//
//  Created by Mark Makdad on 8/21/11.
//  Copyright 2011 Long Weekend LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Card.h"

@interface ChineseCard : Card

typedef enum
{
  noToneState = 0,
  toneIsOther = 1,
  toneIsSecondAfterOther = 2,
  toneIsThird = 3,
  toneIsFourth = 4,
} ToneStates;

- (NSArray *) readingComponents;
- (NSString *) pinyinReading;
- (NSString *) sandhiReading;

@property (nonatomic, retain) NSString *headword_simp;

@end
