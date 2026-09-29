//
//  ChineseCardPeerTest.m
//  jFlash
//
//  Created by Mark Makdad on 12/7/11.
//  Copyright (c) 2011 Long Weekend LLC. All rights reserved.
//

#import "CardPeerTest.h"
#import "CardPeer.h"

@implementation CardPeerTest

#pragma mark - Test Search Helper Methods

- (void) testDetectKeywordMayBePinyin
{
  XCTAssertTrue([CardPeer keywordIsReading:@"gong1"],@"Should be considered pinyin");
  XCTAssertTrue([CardPeer keywordIsReading:@"gong1 ying4"],@"Should be considered pinyin");
  XCTAssertTrue([CardPeer keywordIsReading:@"gong3 yi?"],@"Should be considered pinyin");
  XCTAssertTrue([CardPeer keywordIsReading:@"gong? yi?"],@"Should be considered pinyin");
  
  // No number is 5, so even if there is no number, match -- very loose
  XCTAssertTrue([CardPeer keywordIsReading:@"gong? yi"],@"Should be considered pinyin");
  
  // For example, I don't think "tong" is proper pinyin, but it could be, so we can match.
  // Then, if the search doesn't return anything, we can run it as a general search.
  XCTAssertTrue([CardPeer keywordIsReading:@"tong"],@"Should be considered pinyin");
}

// If the word is longer & has no numbers
- (void) testDetectKeywordIsNotPinyin
{
  XCTAssertFalse([CardPeer keywordIsReading:@"dictionary"],@"Should NOT be considered pinyin");
  XCTAssertFalse([CardPeer keywordIsReading:@"baseball"],@"Should NOT be considered pinyin");
  XCTAssertFalse([CardPeer keywordIsReading:@"baseball?"],@"Should NOT be considered pinyin");
}

// Any character with only whitespace + question marks should be YES
- (void) testDetectKeywordIsHeadword
{
  XCTAssertTrue([CardPeer keywordIsHeadword:@"納バ"],@"Should be considered headword");
  XCTAssertTrue([CardPeer keywordIsHeadword:@"納 "],@"Should be considered headword");
  XCTAssertTrue([CardPeer keywordIsHeadword:@"納　"],@"Should be considered headword");
  XCTAssertTrue([CardPeer keywordIsHeadword:@"納?"],@"Should be considered headword");
  XCTAssertTrue([CardPeer keywordIsHeadword:@"人"],@"Should be considered headword");
  XCTAssertTrue([CardPeer keywordIsHeadword:@"人?"],@"Should be considered headword");
  XCTAssertTrue([CardPeer keywordIsHeadword:@"人? "],@"Should be considered headword");
  XCTAssertTrue([CardPeer keywordIsHeadword:@"人? 馬?"],@"Should be considered headword");
  XCTAssertTrue([CardPeer keywordIsHeadword:@"人?馬?"],@"Should be considered headword");
  XCTAssertTrue([CardPeer keywordIsHeadword:@"人?馬"],@"Should be considered headword");
  XCTAssertTrue([CardPeer keywordIsHeadword:@"人馬?"],@"Should be considered headword");
  XCTAssertTrue([CardPeer keywordIsHeadword:@"人 馬?"],@"Should be considered headword");
  XCTAssertTrue([CardPeer keywordIsHeadword:@"人納 "],@"Should be considered headword");
}

// Any keyword that contains any ASCII along with non-ASCII should be NO.
- (void) testDetectKeywordIsNotHeadword
{
  XCTAssertFalse([CardPeer keywordIsHeadword:@"foobar"],@"Should NOT be considered headword");
  XCTAssertFalse([CardPeer keywordIsHeadword:@"場? gong"],@"Should NOT be considered headword");
  XCTAssertFalse([CardPeer keywordIsHeadword:@"gong1 yi1"],@"Should NOT be considered headword");
  XCTAssertFalse([CardPeer keywordIsHeadword:@"gong1 場?"],@"Should NOT be considered headword");
}

@end