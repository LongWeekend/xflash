//
//  UserHistoryTest.m
//  jFlash
//
//  Tests for UserHistory model (including NSCoding) and UserHistoryPeer
//  card-recording / history-retrieval methods.
//

#import "UserHistoryTest.h"
#import "SetupDatabaseHelper.h"
#import "UserHistory.h"
#import "UserHistoryPeer.h"
#import "TagPeer.h"

// Expose private factory and level-progression methods for testing.
@interface UserHistory (Testing)
- (id)_init;
@end

@interface UserHistoryPeer (Testing)
+ (NSInteger)_nextAfterLevel:(NSInteger)level gotItRight:(BOOL)gotItRight;
@end

static NSString * const kLWEFavoriteTagName = @"Long Weekend Favorites";
static const NSInteger kTestCardId          = 88888;
static const NSInteger kTestCardId2         = 88889;
static const NSInteger kTestCardId3         = 88890;

@implementation UserHistoryTest

#pragma mark - UserHistory model tests

- (void)testDirectInitRaisesException
{
  STAssertThrows([[UserHistory alloc] init],
                 @"Calling -init directly on UserHistory should raise NSInternalInconsistencyException");
}

- (void)testNSCodingRoundTrip
{
  UserHistory *original = [[[UserHistory alloc] _init] autorelease];
  original.cardId     = 42;
  original.rightCount = 7;
  original.wrongCount = 3;
  original.cardLevel  = 4;
  NSDate *now = [NSDate date];
  original.lastUpdated = now;
  original.createdAt   = now;

  NSData *data = [NSKeyedArchiver archivedDataWithRootObject:original];
  STAssertNotNil(data, @"Archiving should produce non-nil NSData");

  UserHistory *decoded = [NSKeyedUnarchiver unarchiveObjectWithData:data];
  STAssertNotNil(decoded, @"Unarchiving should produce a non-nil UserHistory");
  STAssertEquals(decoded.cardId,     original.cardId,     @"cardId should survive NSCoding round-trip");
  STAssertEquals(decoded.rightCount, original.rightCount, @"rightCount should survive NSCoding round-trip");
  STAssertEquals(decoded.wrongCount, original.wrongCount, @"wrongCount should survive NSCoding round-trip");
  STAssertEquals(decoded.cardLevel,  original.cardLevel,  @"cardLevel should survive NSCoding round-trip");
  STAssertEqualObjects(decoded.lastUpdated, original.lastUpdated, @"lastUpdated should survive NSCoding round-trip");
  STAssertEqualObjects(decoded.createdAt,   original.createdAt,   @"createdAt should survive NSCoding round-trip");
}

- (void)testSaveToUserIdPersists
{
  UserHistory *history = [[[UserHistory alloc] _init] autorelease];
  history.cardId     = kTestCardId;
  history.rightCount = 3;
  history.wrongCount = 1;
  history.cardLevel  = 2;
  history.lastUpdated = [NSDate date];
  history.createdAt   = [NSDate date];

  BOOL saved = [history saveToUserId:DEFAULT_USER_ID];
  STAssertTrue(saved, @"saveToUserId should return YES on success");

  NSArray *histories = [UserHistoryPeer userHistoriesForUserId:DEFAULT_USER_ID];
  BOOL found = NO;
  for (UserHistory *h in histories)
  {
    if (h.cardId == kTestCardId)
    {
      STAssertEquals(h.rightCount, 3, @"Saved rightCount should be retrievable");
      STAssertEquals(h.wrongCount, 1, @"Saved wrongCount should be retrievable");
      STAssertEquals(h.cardLevel,  2, @"Saved cardLevel should be retrievable");
      found = YES;
      break;
    }
  }
  STAssertTrue(found, @"Saved UserHistory should appear in userHistoriesForUserId results");
}

#pragma mark - UserHistoryPeer retrieval tests

- (void)testUserHistoriesForUserIdReturnsKnownEntries
{
  UserHistory *h1 = [[[UserHistory alloc] _init] autorelease];
  h1.cardId = kTestCardId; h1.rightCount = 5; h1.wrongCount = 0; h1.cardLevel = 3;
  h1.lastUpdated = [NSDate date]; h1.createdAt = [NSDate date];
  [h1 saveToUserId:DEFAULT_USER_ID];

  UserHistory *h2 = [[[UserHistory alloc] _init] autorelease];
  h2.cardId = kTestCardId2; h2.rightCount = 1; h2.wrongCount = 4; h2.cardLevel = 1;
  h2.lastUpdated = [NSDate date]; h2.createdAt = [NSDate date];
  [h2 saveToUserId:DEFAULT_USER_ID];

  NSArray *results = [UserHistoryPeer userHistoriesForUserId:DEFAULT_USER_ID];
  STAssertNotNil(results, @"userHistoriesForUserId should never return nil");
  STAssertTrue([results isKindOfClass:[NSArray class]], @"Should return an NSArray");

  NSInteger foundCount = 0;
  for (UserHistory *h in results)
  {
    if (h.cardId == kTestCardId || h.cardId == kTestCardId2)
    {
      foundCount++;
    }
  }
  STAssertEquals(foundCount, 2, @"Both saved UserHistory entries should appear in the results");
}

- (void)testUserHistoriesForNonExistentUserReturnsEmptyArray
{
  NSArray *results = [UserHistoryPeer userHistoriesForUserId:99999];
  STAssertNotNil(results, @"Should return an empty array, not nil, for an unknown user");
  STAssertEquals([results count], (NSUInteger)0, @"Unknown user should have zero history entries");
}

#pragma mark - Level-progression logic tests

- (void)testNextAfterLevelWrongAlwaysReturnsOne
{
  for (NSInteger level = 0; level <= 5; level++)
  {
    NSInteger next = [UserHistoryPeer _nextAfterLevel:level gotItRight:NO];
    STAssertEquals(next, (NSInteger)1, @"Getting a card wrong at level %d should always return level 1", level);
  }
}

- (void)testNextAfterLevel0RightReturnsTwo
{
  NSInteger next = [UserHistoryPeer _nextAfterLevel:0 gotItRight:YES];
  STAssertEquals(next, (NSInteger)2,
                 @"An unseen card (level 0) answered correctly should go to level 2, not 1");
}

- (void)testNextAfterLevels1to4RightIncrementsLevel
{
  for (NSInteger level = 1; level <= 4; level++)
  {
    NSInteger next = [UserHistoryPeer _nextAfterLevel:level gotItRight:YES];
    STAssertEquals(next, level + 1,
                   @"Getting level %d right should advance to level %d", level, level + 1);
  }
}

- (void)testNextAfterLevel5RightClampsAtFive
{
  NSInteger next = [UserHistoryPeer _nextAfterLevel:5 gotItRight:YES];
  STAssertEquals(next, (NSInteger)5, @"Level 5 is the maximum; getting it right should stay at 5");
}

#pragma mark - DB-backed recording tests

- (void)testRecordCorrectIncrementsRightCountInDB
{
  [[NSUserDefaults standardUserDefaults] setInteger:DEFAULT_USER_ID forKey:@"user_id"];

  Tag *tag = [TagPeer retrieveTagByName:kLWEFavoriteTagName];
  [tag populateCardIds];
  NSArray *faultedCards = [CardPeer retrieveFaultedCardsForTag:tag];
  STAssertTrue([faultedCards count] > 0, @"Favorites tag must contain at least one card");

  Card *faultedCard = [faultedCards objectAtIndex:0];
  Card *card = [CardPeer retrieveCardByPK:faultedCard.cardId];
  STAssertNotNil(card, @"retrieveCardByPK should return a valid card");

  NSInteger originalRightCount = card.rightCount;
  [UserHistoryPeer recordCorrectForCard:card inTag:tag];

  Card *updated = [CardPeer retrieveCardByPK:card.cardId];
  STAssertEquals(updated.rightCount, originalRightCount + 1,
                 @"recordCorrectForCard should increment right_count by 1 in user_history");
}

- (void)testRecordWrongIncrementsWrongCountInDB
{
  [[NSUserDefaults standardUserDefaults] setInteger:DEFAULT_USER_ID forKey:@"user_id"];

  Tag *tag = [TagPeer retrieveTagByName:kLWEFavoriteTagName];
  [tag populateCardIds];
  NSArray *faultedCards = [CardPeer retrieveFaultedCardsForTag:tag];
  STAssertTrue([faultedCards count] > 0, @"Favorites tag must contain at least one card");

  Card *faultedCard = [faultedCards objectAtIndex:0];
  Card *card = [CardPeer retrieveCardByPK:faultedCard.cardId];
  STAssertNotNil(card, @"retrieveCardByPK should return a valid card");

  NSInteger originalWrongCount = card.wrongCount;
  [UserHistoryPeer recordWrongForCard:card inTag:tag];

  Card *updated = [CardPeer retrieveCardByPK:card.cardId];
  STAssertEquals(updated.wrongCount, originalWrongCount + 1,
                 @"recordWrongForCard should increment wrong_count by 1 in user_history");
}

- (void)testBuryCardSetsLevelToFiveInDB
{
  [[NSUserDefaults standardUserDefaults] setInteger:DEFAULT_USER_ID forKey:@"user_id"];

  Tag *tag = [TagPeer retrieveTagByName:kLWEFavoriteTagName];
  [tag populateCardIds];
  NSArray *faultedCards = [CardPeer retrieveFaultedCardsForTag:tag];
  STAssertTrue([faultedCards count] > 0, @"Favorites tag must contain at least one card");

  Card *faultedCard = [faultedCards objectAtIndex:0];
  Card *card = [CardPeer retrieveCardByPK:faultedCard.cardId];
  STAssertNotNil(card, @"retrieveCardByPK should return a valid card");

  [UserHistoryPeer buryCard:card inTag:tag];

  LWEDatabase *db = [LWEDatabase sharedLWEDatabase];
  FMResultSet *rs = [db.dao executeQuery:
                     @"SELECT card_level FROM user_history WHERE card_id = ? AND user_id = ?",
                     [NSNumber numberWithInteger:card.cardId],
                     [NSNumber numberWithInteger:DEFAULT_USER_ID]];
  NSInteger cardLevel = -1;
  if ([rs next])
  {
    cardLevel = [rs intForColumn:@"card_level"];
  }
  [rs close];
  STAssertEquals(cardLevel, (NSInteger)5, @"buryCard should set card_level to 5 in user_history");
}

#pragma mark - Setup / teardown

- (void)setUp
{
  NSError *error = nil;
  JFlashDatabase *db = [JFlashDatabase sharedJFlashDatabase];
  BOOL result = [db setupTestDatabaseAndOpenConnectionWithError:&error];
  STAssertTrue(result, @"Failed to set up test database: %@", [error localizedDescription]);

  result = [db setupAttachedDatabase:CURRENT_CARD_TEST_DATABASE asName:@"cards"];
  STAssertTrue(result, @"Failed to attach cards database");
}

- (void)tearDown
{
  JFlashDatabase *db = [JFlashDatabase sharedJFlashDatabase];
  NSError *error = nil;
  BOOL result = [db removeTestDatabaseWithError:&error];
  STAssertTrue(result, @"Failed to remove test database: %@", [error localizedDescription]);
}

@end
