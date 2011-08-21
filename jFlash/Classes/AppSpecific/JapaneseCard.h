//
//  JapaneseCard.h
//  jFlash
//
//  Created by Mark Makdad on 8/21/11.
//  Copyright 2011 Long Weekend LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Card.h"

@interface JapaneseCard : Card

- (NSString*) reading; //combinedReadingForSettings;
- (NSString*) readingBasedonSettingsForExpandedSampleSentences;

//! Romanized reading
@property (nonatomic, retain) NSString *romaji;

@end
