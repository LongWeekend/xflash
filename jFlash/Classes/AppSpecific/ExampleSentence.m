//
//  ExampleSentences.m
//  jFlash
//
//  Created by シャロット ロス on 6/6/10.
//  Copyright 2010 LONG WEEKEND INC. All rights reserved.
//

#import "ExampleSentence.h"

/*!
    @class ExampleSentence
    @abstract Represents a single example sentence in both English and Japanese
    @discussion Also has the "checked" flag to indicate whether or not the sentence
    has been checked by a human after submission to the corpus.
*/
@implementation ExampleSentence
@synthesize sentenceId, sentenceJa, sentenceEn, checked;

#pragma mark -
#pragma mark Core Methods

/** Takes a sqlite result set \param rs and populates the properties of example sentence */
- (void) hydrate: (FMResultSet*) rs
{
  [self setSentenceId: [rs intForColumn:@"sentence_id"]];
  [self setSentenceJa: [rs stringForColumn:@"sentence_ja"]];
  [self setSentenceEn: [rs stringForColumn:@"sentence_en"]];
  [self setChecked: [rs intForColumn:@"checked"]];
}

#pragma mark -
#pragma mark Class Plumbing

- (void) dealloc
{
  [sentenceJa release];
  [sentenceEn release];
	[super dealloc];
}

@end
