//
//  JapaneseCardTest.m
//  jFlash
//
//  Copyright (c) 2026 Long Weekend LLC. All rights reserved.
//

#import "JapaneseCardTest.h"
#import "JapaneseCard.h"
#import "Constants.h"

@implementation JapaneseCardTest
{
  NSString *_savedReadingSetting;
}

- (void)setUp
{
  [super setUp];
  _savedReadingSetting = [[[NSUserDefaults standardUserDefaults] objectForKey:APP_READING] retain];
}

- (void)tearDown
{
  if (_savedReadingSetting)
    [[NSUserDefaults standardUserDefaults] setObject:_savedReadingSetting forKey:APP_READING];
  else
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:APP_READING];
  [_savedReadingSetting release];
  _savedReadingSetting = nil;
  [super tearDown];
}

#pragma mark - JapaneseCard.reading

- (void)testReadingKanaModeReturnsHwReading
{
  JapaneseCard *card = [[JapaneseCard alloc] init];
  card.hw_reading = @"ねこ";
  card.romaji = @"neko";
  [[NSUserDefaults standardUserDefaults] setObject:SET_READING_KANA forKey:APP_READING];

  NSString *result = [card reading];
  XCTAssertEqualObjects(@"ねこ", result, @"Kana mode should return hw_reading");
  [card release];
}

- (void)testReadingRomajiModeReturnsRomaji
{
  JapaneseCard *card = [[JapaneseCard alloc] init];
  card.hw_reading = @"ねこ";
  card.romaji = @"neko";
  [[NSUserDefaults standardUserDefaults] setObject:SET_READING_ROMAJI forKey:APP_READING];

  NSString *result = [card reading];
  XCTAssertEqualObjects(@"neko", result, @"Romaji mode should return romaji");
  [card release];
}

- (void)testReadingBothModeCombinesKanaAndRomaji
{
  JapaneseCard *card = [[JapaneseCard alloc] init];
  card.hw_reading = @"ねこ";
  card.romaji = @"neko";
  [[NSUserDefaults standardUserDefaults] setObject:SET_READING_BOTH forKey:APP_READING];

  NSString *result = [card reading];
  XCTAssertEqualObjects(@"ねこ - neko", result, @"Both mode should combine kana and romaji with ' - '");
  [card release];
}

- (void)testReadingDefaultModeWhenUnsetCombinesBoth
{
  JapaneseCard *card = [[JapaneseCard alloc] init];
  card.hw_reading = @"さる";
  card.romaji = @"saru";
  [[NSUserDefaults standardUserDefaults] removeObjectForKey:APP_READING];

  NSString *result = [card reading];
  XCTAssertEqualObjects(@"さる - saru", result, @"Default (unset) mode should combine kana and romaji");
  [card release];
}

@end
