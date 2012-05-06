//
//  User.m
//  jFlash
//
//  Created by Paul Chapman on 28/01/10.
//  Copyright 2010 LONG WEEKEND INC.. All rights reserved.
//

#import "User.h"
#import "UserHistoryPeer.h"
#import "UserPeer.h"

NSInteger const kLWEUninitializedUserId = -1;

@implementation User
@synthesize userId, userNickname, dateCreated;

+ (User *)defaultUser
{
  return [UserPeer userWithUserId:DEFAULT_USER_ID];
}

// Takes a sqlite result set and populates the properties of user
- (void) hydrate:(FMResultSet*)rs
{
  self.userId          = [rs intForColumn:@"user_id"];
  self.userNickname    = [rs stringForColumn:@"nickname"];
  self.dateCreated     = [rs stringForColumn:@"date_created"];
}

- (void) save
{
  LWEDatabase *db = [LWEDatabase sharedLWEDatabase];
  if(self.userId != kLWEUninitializedUserId)
  {
    [db.dao executeUpdate:@"UPDATE users SET nickname = ? WHERE user_id = ?",self.userNickname,[NSNumber numberWithInt:self.userId]];
  }
  else
  {
    [db.dao executeUpdate:@"INSERT INTO users (nickname) VALUES (?,?)",self.userNickname];
  }
}

- (BOOL) deleteUser:(NSError **)error
{
  LWE_ASSERT_EXC((self.userId != kLWEUninitializedUserId),@"Can't call this until -hydrate has been called.");
  if (self.userId == DEFAULT_USER_ID)
  {
    *error = [NSError errorWithDomain:@"LWEErrorDomain" code:31337 userInfo:nil];
    return NO;
  }

  LWEDatabase *db = [LWEDatabase sharedLWEDatabase];
  [db.dao executeUpdate:@"DELETE FROM users WHERE user_id = ?",[NSNumber numberWithInt:self.userId]];
  [db.dao executeUpdate:@"DELETE FROM user_history WHERE user_id = ?",[NSNumber numberWithInt:self.userId]];
  return YES;
}

- (NSString *)historyArchiveKey
{
  LWE_ASSERT_EXC((self.userId != kLWEUninitializedUserId),@"Can't call this unless the user has been hydrated");
  return [NSString stringWithFormat:@"history_for_user_id_%d",self.userId];  
}

- (NSArray *) studyHistories
{
  LWE_ASSERT_EXC((self.userId != kLWEUninitializedUserId),@"Can't call this unless the user has been hydrated");
  return [UserHistoryPeer userHistoriesForUserId:self.userId];
}

#pragma mark - Class plumbing

- (id) init
{
  self = [super init];
  if (self)
  {
    self.userId          = kLWEUninitializedUserId;
  }
  return self;
}

- (void) dealloc
{
  [userNickname release];
  [dateCreated release];
	[super dealloc];
}

@end
