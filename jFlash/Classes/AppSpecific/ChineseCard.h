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

- (NSArray *) readingComponents;
- (NSString *) pinyinReading;
- (NSString *) sandhiReading;

@property (nonatomic, retain) NSString *headword_simp;

@end
