//
//  ChineseCardPeerTest.m
//  jFlash
//
//  Created by Mark Makdad on 12/7/11.
//  Copyright (c) 2011 Long Weekend LLC. All rights reserved.
//

#import "ChineseCardPeerTest.h"
#import "CardPeer.h"

@implementation ChineseCardPeerTest

- (void) testDetectKeywordMayBePinyin
{
  STAssertTrue([CardPeer keywordIsReading:@"gong1"],@"Should be considered pinyin");
  STAssertTrue([CardPeer keywordIsReading:@"gong1 ying4"],@"Should be considered pinyin");
  STAssertTrue([CardPeer keywordIsReading:@"gong3 yi?"],@"Should be considered pinyin");
  STAssertTrue([CardPeer keywordIsReading:@"gong? yi?"],@"Should be considered pinyin");
  
  // No number is 5, so even if there is no number, match -- very loose
  STAssertTrue([CardPeer keywordIsReading:@"gong? yi"],@"Should be considered pinyin");
  
  // For example, I don't think "tong" is proper pinyin, but it could be, so we can match.
  // Then, if the search doesn't return anything, we can run it as a general search.
  STAssertTrue([CardPeer keywordIsReading:@"tong"],@"Should be considered pinyin");
}

// If the word is longer & has no numbers
- (void) testDetectKeywordIsNotPinyin
{
  STAssertFalse([CardPeer keywordIsReading:@"dictionary"],@"Should NOT be considered pinyin");
  STAssertFalse([CardPeer keywordIsReading:@"baseball"],@"Should NOT be considered pinyin");
  STAssertFalse([CardPeer keywordIsReading:@"baseball?"],@"Should NOT be considered pinyin");
}

// Any character with only whitespace + question marks should be YES
- (void) testDetectKeywordIsHeadword
{
  STAssertTrue([CardPeer keywordIsHeadword:@"人"],@"Should be considered headword");
  STAssertTrue([CardPeer keywordIsHeadword:@"人?"],@"Should be considered headword");
  STAssertTrue([CardPeer keywordIsHeadword:@"人? 馬?"],@"Should be considered headword");
}

// Any keyword that contains any ASCII along with non-ASCII should be NO.
- (void) testDetectKeywordIsNotHeadword
{
  STAssertFalse([CardPeer keywordIsHeadword:@"foobar"],@"Should NOT be considered headword");
  STAssertFalse([CardPeer keywordIsHeadword:@"場? gong"],@"Should NOT be considered headword");
  STAssertFalse([CardPeer keywordIsHeadword:@"gong1 yi1"],@"Should NOT be considered headword");
  STAssertFalse([CardPeer keywordIsHeadword:@"gong1 場?"],@"Should NOT be considered headword");
}

@end