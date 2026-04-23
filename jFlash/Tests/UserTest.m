//
//  UserTest.m
//  jFlash
//
//  Tests for User model and UserPeer retrieval/storage methods.
//

#import "UserTest.h"
#import "SetupDatabaseHelper.h"
#import "UserPeer.h"
#import "User.h"

static NSString * const kUserTestNickname        = @"TestUser";
static NSString * const kUserTestUpdatedNickname = @"UpdatedNickname";

@implementation UserTest

#pragma mark - User model tests

- (void)testInitDefaultsToUninitializedUserId
{
  User *user = [[[User alloc] init] autorelease];
  STAssertEquals(user.userId, kLWEUninitializedUserId, @"New User should start with kLWEUninitializedUserId");
}

- (void)testHistoryArchiveKeyFormat
{
  User *user = [UserPeer userWithUserId:DEFAULT_USER_ID];
  NSString *expectedKey = [NSString stringWithFormat:@"history_for_user_id_%d", DEFAULT_USER_ID];
  STAssertEqualObjects([user historyArchiveKey], expectedKey, @"historyArchiveKey should embed the user ID");
}

- (void)testSaveInsertsNewUser
{
  NSArray *before = [UserPeer allUsers];
  User *newUser = [[[User alloc] init] autorelease];
  newUser.userNickname = kUserTestNickname;
  [newUser save];

  NSArray *after = [UserPeer allUsers];
  STAssertEquals([after count], [before count] + 1, @"Saving a new User should insert one row");
}

- (void)testSaveUpdatesExistingUserNickname
{
  User *user = [UserPeer userWithUserId:DEFAULT_USER_ID];
  user.userNickname = kUserTestUpdatedNickname;
  [user save];

  User *reloaded = [UserPeer userWithUserId:DEFAULT_USER_ID];
  STAssertEqualObjects(reloaded.userNickname, kUserTestUpdatedNickname, @"Saved nickname should persist to DB");
}

- (void)testDeleteDefaultUserFails
{
  User *defaultUser = [UserPeer userWithUserId:DEFAULT_USER_ID];
  NSError *error = nil;
  BOOL result = [defaultUser deleteUser:&error];
  STAssertFalse(result, @"Deleting the default user should return NO");
  STAssertNotNil(error, @"Deleting the default user should populate the error parameter");
}

- (void)testDeleteNonDefaultUserSucceeds
{
  User *newUser = [[[User alloc] init] autorelease];
  newUser.userNickname = kUserTestNickname;
  [newUser save];

  NSArray *allUsers = [UserPeer allUsers];
  User *insertedUser = nil;
  for (User *u in allUsers)
  {
    if (u.userId != DEFAULT_USER_ID)
    {
      insertedUser = u;
      break;
    }
  }
  STAssertNotNil(insertedUser, @"Should find the newly inserted non-default user");

  NSError *error = nil;
  BOOL result = [insertedUser deleteUser:&error];
  STAssertTrue(result, @"Deleting a non-default user should return YES");
  STAssertNil(error, @"Deleting a non-default user should not produce an error");

  NSArray *afterDelete = [UserPeer allUsers];
  for (User *u in afterDelete)
  {
    STAssertFalse(u.userId == insertedUser.userId, @"Deleted user should no longer appear in allUsers");
  }
}

- (void)testDeleteNonDefaultUserAlsoRemovesHistory
{
  User *newUser = [[[User alloc] init] autorelease];
  newUser.userNickname = kUserTestNickname;
  [newUser save];

  NSArray *allUsers = [UserPeer allUsers];
  User *insertedUser = nil;
  for (User *u in allUsers)
  {
    if (u.userId != DEFAULT_USER_ID) { insertedUser = u; break; }
  }
  STAssertNotNil(insertedUser, @"Should find inserted user");

  NSError *error = nil;
  [insertedUser deleteUser:&error];

  LWEDatabase *db = [LWEDatabase sharedLWEDatabase];
  FMResultSet *rs = [db.dao executeQuery:@"SELECT * FROM user_history WHERE user_id = ?",
                     [NSNumber numberWithInteger:insertedUser.userId]];
  NSInteger rowCount = 0;
  while ([rs next]) { rowCount++; }
  [rs close];
  STAssertEquals(rowCount, 0, @"Deleting a user should also delete their user_history rows");
}

- (void)testStudyHistoriesReturnsArray
{
  User *user = [UserPeer userWithUserId:DEFAULT_USER_ID];
  NSArray *histories = [user studyHistories];
  STAssertNotNil(histories, @"studyHistories should never return nil");
  STAssertTrue([histories isKindOfClass:[NSArray class]], @"studyHistories should return an NSArray");
}

#pragma mark - UserPeer tests

- (void)testAllUsersIncludesDefaultUser
{
  NSArray *users = [UserPeer allUsers];
  STAssertTrue([users count] >= 1, @"allUsers should return at least the default user");
  BOOL foundDefault = NO;
  for (User *u in users)
  {
    if (u.userId == DEFAULT_USER_ID) { foundDefault = YES; break; }
  }
  STAssertTrue(foundDefault, @"allUsers should include the default user (id %d)", DEFAULT_USER_ID);
}

- (void)testUserWithUserIdReturnsCorrectUserId
{
  User *user = [UserPeer userWithUserId:DEFAULT_USER_ID];
  STAssertEquals(user.userId, (NSInteger)DEFAULT_USER_ID, @"userWithUserId should return a user whose userId matches the argument");
}

- (void)testUserWithNonExistentIdHasUninitializedUserId
{
  User *user = [UserPeer userWithUserId:99999];
  STAssertEquals(user.userId, kLWEUninitializedUserId,
                 @"userWithUserId with an unknown ID should return a user with kLWEUninitializedUserId");
}

#pragma mark - Setup / teardown

- (void)setUp
{
  NSError *error = nil;
  JFlashDatabase *db = [JFlashDatabase sharedJFlashDatabase];
  BOOL result = [db setupTestDatabaseAndOpenConnectionWithError:&error];
  STAssertTrue(result, @"Failed to set up test database: %@", [error localizedDescription]);
}

- (void)tearDown
{
  JFlashDatabase *db = [JFlashDatabase sharedJFlashDatabase];
  NSError *error = nil;
  BOOL result = [db removeTestDatabaseWithError:&error];
  STAssertTrue(result, @"Failed to remove test database: %@", [error localizedDescription]);
}

@end
