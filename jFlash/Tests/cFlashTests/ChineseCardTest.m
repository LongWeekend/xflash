//
//  ChineseCardTest.m
//  xFlash
//
//  Created by Mark Makdad on 2/28/12.
//  Copyright (c) 2012 Long Weekend LLC. All rights reserved.
//

#import "ChineseCardTest.h"
#import "ChineseCard.h"
#import "CardPeer.h"
#import "SetupDatabaseHelper.h"

@implementation ChineseCardTest

#pragma mark - Helpers

- (ChineseCard *) _cardForKeyword:(NSString *)keyword
{
  // TECHNICALLY we shouldn't be using CardPeer to search for a UNIT test, but it's SO DAMN CONVENIENT.
  NSArray *cards = [CardPeer searchCardsForKeyword:keyword];
  if ([cards count] > 0)
  {
    ChineseCard *card = [cards objectAtIndex:0];
    [card hydrate];
    return card;
  }
  return nil;
}

#pragma mark - Tone Change Tests

#pragma mark 3rd Tone Tests

- (void) testTone3Repeated
{
  /**
   1. A 3rd tone followed by another 3rd tone becomes a 2nd tone
   [3] [3] ⇒ [2] [3]
   你好 (hello): nǐhǎo ⇒ ‘níhǎo’
   很远 (very far): hěnyuǎn ⇒ ‘hényuǎn’
   好久 (a long time): hǎojiǔ ⇒ ‘háojiǔ’
   */

  ChineseCard *card = [self _cardForKeyword:@"你好"];
  STAssertNotNil(card, @"Card could not be found: 你好");
  STAssertEqualObjects(@"ni3 hao3", card.reading, @"Regular reading should not change"); 
  STAssertEqualObjects(@"nǐ hǎo", card.attributedReading.string, @"Regular reading should not change"); 
  STAssertEqualObjects(@"ní hǎo", card.sandhiReading, @"Tone sandhi reading should change"); 

  card = [self _cardForKeyword:@"好久"];
  STAssertNotNil(card, @"Card could not be found: 好久");
  STAssertEqualObjects(@"hao3 jiu3", card.reading, @"Regular reading should not change"); 
  STAssertEqualObjects(@"hǎo jiǔ", card.attributedReading.string, @"Regular reading should not change"); 
  STAssertEqualObjects(@"háo jiǔ", card.sandhiReading, @"Tone sandhi reading should change"); 
}

- (void) testTone3FollowedByNonTone3
{
  /**
   
   2. A 3rd tone becomes a ‘low tone’ if followed by any other tone
   Again, this is confusing at first. It’s probably easier to approach these two rules as “if a third tone isn’t on its own, it changes”. This ‘low tone’ is a low-pitch tone that falls slightly.
   As symbols:
   [3] [!3] ⇒ [low tone] [3]
   (here the ! represents ‘not’)
   Examples:
   
   考试 (exam): kǎoshì ⇒ kaoshì
   语言 (language): yǔyán ⇒ yuyán
   马车 (cart): mǎchē ⇒ machē
   */
}

#pragma mark Rules for "一" (one)

- (void) testYi1BecomesYi2WhenFollowedByTone4
{
  /**
   3. 一 is 2nd tone when followed by a 4th tone
   As symbols:
   [一] [4] ⇒ [一2] [4]
   Examples:
   一个 (one …): yī gè ⇒ ‘yí gè’
   一半 (one half): yī bàn ⇒ ‘yí bàn’
   一步 (one step): yī bù ⇒ ‘yí bù’
   */

  ChineseCard *card = [self _cardForKeyword:@"一个"];
  STAssertNotNil(card, @"Card could not be found: 一个");
  STAssertEqualObjects(@"yi1 ge4", card.reading, @"Regular reading should not change"); 
  STAssertEqualObjects(@"yī gè", card.attributedReading.string, @"Regular reading should not change"); 
  STAssertEqualObjects(@"yí gè", card.sandhiReading, @"Tone sandhi reading should change"); 

  card = [self _cardForKeyword:@"一半"];
  STAssertNotNil(card, @"Card could not be found: 一半");
  STAssertEqualObjects(@"yi1 ban4", card.reading, @"Regular reading should not change"); 
  STAssertEqualObjects(@"yī bàn", card.attributedReading.string, @"Regular reading should not change"); 
  STAssertEqualObjects(@"yí bàn", card.sandhiReading, @"Tone sandhi reading should change"); 
  
  card = [self _cardForKeyword:@"一步"];
  STAssertNotNil(card, @"Card could not be found: 一步");
  STAssertEqualObjects(@"yi1 bu4", card.reading, @"Regular reading should not change"); 
  STAssertEqualObjects(@"yī bù", card.attributedReading.string, @"Regular reading should not change"); 
  STAssertEqualObjects(@"yí bù", card.sandhiReading, @"Tone sandhi reading should change"); 
}

- (void) testYi1BecomesYi4WhenFollowedByNonTone4
{
  /**
   4. 一 is 4th tone when followed by a 1st, 2nd or 3rd tone
   As symbols:
   [一] [1 | 2 | 3] ⇒ [一4] [1 | 2 | 3]
   (here the | represents ‘or’)
   Examples
   一般 (normally): yībān ⇒ ‘yìbān’
   一直 (continuously): yīzhí ⇒ ‘yìzhí’
   一起 (together): yīqǐ ⇒ ‘yìqǐ’
   */
  ChineseCard *card = [self _cardForKeyword:@"一般"];
  STAssertNotNil(card, @"Card could not be found: 一般");
  STAssertEqualObjects(@"yi1 ban1", card.reading, @"Regular reading should not change"); 
  STAssertEqualObjects(@"yī bān", card.attributedReading.string, @"Regular reading should not change"); 
  STAssertEqualObjects(@"yì bān", card.sandhiReading, @"Tone sandhi reading should change");

  card = [self _cardForKeyword:@"一直"];
  STAssertNotNil(card, @"Card could not be found: 一直");
  STAssertEqualObjects(@"yi1 zhi2", card.reading, @"Regular reading should not change"); 
  STAssertEqualObjects(@"yī zhí", card.attributedReading.string, @"Regular reading should not change"); 
  STAssertEqualObjects(@"yì zhí", card.sandhiReading, @"Tone sandhi reading should change"); 
  
  card = [self _cardForKeyword:@"一起"];
  STAssertNotNil(card, @"Card could not be found: 一起");
  STAssertEqualObjects(@"yi1 qi3", card.reading, @"Regular reading should not change"); 
  STAssertEqualObjects(@"yī qǐ", card.attributedReading.string, @"Regular reading should not change"); 
  STAssertEqualObjects(@"yì qǐ", card.sandhiReading, @"Tone sandhi reading should change"); 
}

#pragma mark Rules for "不" (non-, no)

- (void) testBu4BecomesBu2WhenFollowedByTone4
{
  /**
   不 is normally 4th tone (bù), but there is one situation where this changes.
   5. 不 is 2nd tone when followed by a 4th tone
   As symbols:
   [不] [4] ⇒ [不2] [4]
   Examples:
   不是 (is not): bù shì ⇒ ‘bú shì’
   不会 (will not, cannot): bù huì ⇒ ‘bú huì’
   不错 (not bad): bù cuò ⇒ ‘bú cuò’
   */
  ChineseCard *card = [self _cardForKeyword:@"不是"];
  STAssertNotNil(card, @"Card could not be found: 不是");
  STAssertEqualObjects(@"bu4 shi4", card.reading, @"Regular reading should not change"); 
  STAssertEqualObjects(@"bù shì", card.attributedReading.string, @"Regular reading should not change"); 
  STAssertEqualObjects(@"bú shì", card.sandhiReading, @"Tone sandhi reading should change");
  
  card = [self _cardForKeyword:@"不会"];
  STAssertNotNil(card, @"Card could not be found: 不会");
  STAssertEqualObjects(@"bu4 hui4", card.reading, @"Regular reading should not change"); 
  STAssertEqualObjects(@"bù huì", card.attributedReading.string, @"Regular reading should not change"); 
  STAssertEqualObjects(@"bú huì", card.sandhiReading, @"Tone sandhi reading should change"); 
  
  card = [self _cardForKeyword:@"不错"];
  STAssertNotNil(card, @"Card could not be found: 不错");
  STAssertEqualObjects(@"bu4 cuo4", card.reading, @"Regular reading should not change"); 
  STAssertEqualObjects(@"bù cuò", card.attributedReading.string, @"Regular reading should not change"); 
  STAssertEqualObjects(@"bú cuò", card.sandhiReading, @"Tone sandhi reading should change");
}

#pragma mark Rules for 2nd Tone

- (void) test2Becomes1WhenPrecededBy1Or2AndFollowedByOther
{
  /**
   6. A 2nd tone preceded by a 1st or 2nd tone and followed by another tone becomes a 1st tone
   This one will probably start to feel natural after a lot of listening practice and exposure.
   Written down, however, it looks fairly crazy.
   
   As symbols:
   [1 | 2] [2] [*] ⇒ [1 | 2] [1] [*]
   (here the | represents ‘or’, and the * represents any tone)
   
   Examples:
   三年级 (third grade): sān niánjí ⇒ ‘sān niānjí’
   谁来吃？ (who’s coming to eat?): shéi lái chī? ⇒ shéi lāi chī?
   特别难看 (especially ugly): tèbié nánkàn ⇒ tèbié nānkàn
   */
  ChineseCard *card = [self _cardForKeyword:@"三年级"];
  STAssertNotNil(card, @"Card could not be found: 三年级");
  STAssertEqualObjects(@"bu4 shi4", card.reading, @"Regular reading should not change"); 
  STAssertEqualObjects(@"bù shì", card.attributedReading.string, @"Regular reading should not change"); 
  STAssertEqualObjects(@"bú shì", card.sandhiReading, @"Tone sandhi reading should change");
  
  card = [self _cardForKeyword:@"不会"];
  STAssertNotNil(card, @"Card could not be found: 不会");
  STAssertEqualObjects(@"bu4 hui4", card.reading, @"Regular reading should not change"); 
  STAssertEqualObjects(@"bù huì", card.attributedReading.string, @"Regular reading should not change"); 
  STAssertEqualObjects(@"bú huì", card.sandhiReading, @"Tone sandhi reading should change"); 
  
  card = [self _cardForKeyword:@"不错"];
  STAssertNotNil(card, @"Card could not be found: 不错");
  STAssertEqualObjects(@"bu4 cuo4", card.reading, @"Regular reading should not change"); 
  STAssertEqualObjects(@"bù cuò", card.attributedReading.string, @"Regular reading should not change"); 
  STAssertEqualObjects(@"bú cuò", card.sandhiReading, @"Tone sandhi reading should change");
}


#pragma mark - Setup & Teardown

- (void)setUp
{
  //get the cloned database as a test database.
  NSError *error = nil;
  JFlashDatabase *db = [JFlashDatabase sharedJFlashDatabase];
  BOOL result = [db setupTestDatabaseAndOpenConnectionWithError:&error];
  STAssertTrue(result, @"Failed in setup the test database with error: %@", [error localizedDescription]);
  
  //Setup FTS
  result = [db setupAttachedDatabase:CURRENT_FTS_TEST_DATABASE asName:@"fts"];
  STAssertTrue(result, @"Failed to setup search database");
  
  //Setup Cards
  result = [db setupAttachedDatabase:CURRENT_CARD_TEST_DATABASE asName:@"cards"];
  STAssertTrue(result, @"Failed to setup cards database");
}

- (void)tearDown
{
  JFlashDatabase *db = [JFlashDatabase sharedJFlashDatabase];
  NSError *error = nil;
  BOOL result = [db removeTestDatabaseWithError:&error];
  STAssertTrue(result, @"Test database cannot be removed for some reason.\nError: %@", [error localizedDescription]);
}


@end
