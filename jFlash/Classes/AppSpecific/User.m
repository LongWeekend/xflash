//
//  User.m
//  jFlash
//
//  Created by Paul Chapman on 28/01/10.
//  Copyright 2010 LONG WEEKEND INC.. All rights reserved.
//

#import "User.h"

NSInteger const kLWEUninitializedUserId = -1;

@implementation User
@synthesize userId, userNickname, avatarImagePath, dateCreated;

// Takes a sqlite result set and populates the properties of user
- (void) hydrate:(FMResultSet*)rs
{
  self.userId          = [rs intForColumn:@"user_id"];
  self.userNickname    = [rs stringForColumn:@"nickname"];
  self.avatarImagePath = [rs stringForColumn:@"avatar_image_path"];
  if ([self.avatarImagePath length] == 0)
  {
    self.avatarImagePath = DEFAULT_USER_AVATAR_PATH;
  }
  self.dateCreated     = [rs stringForColumn:@"date_created"];
}

- (void) save
{
  LWEDatabase *db = [LWEDatabase sharedLWEDatabase];
  if(self.userId != kLWEUninitializedUserId)
  {
    [db.dao executeUpdate:@"UPDATE users SET nickname = ?, avatar_image_path = ? WHERE user_id = ?",self.userNickname,self.avatarImagePath,[NSNumber numberWithInt:self.userId]];
  }
  else
  {
    [db.dao executeUpdate:@"INSERT INTO users (nickname, avatar_image_path) VALUES (?,?)",self.userNickname,self.avatarImagePath];
  }
}

- (void) deleteUser
{
  LWEDatabase *db = [LWEDatabase sharedLWEDatabase];
  [db.dao executeUpdate:@"DELETE FROM users WHERE user_id = ?",[NSNumber numberWithInt:self.userId]];
  [db.dao executeUpdate:@"DELETE FROM user_history WHERE user_id = ?",[NSNumber numberWithInt:self.userId]];
}

#pragma mark - Class plumbing

- (id) init
{
  self = [super init];
  if (self)
  {
    self.userId          = kLWEUninitializedUserId;
    self.avatarImagePath = DEFAULT_USER_AVATAR_PATH;
  }
  return self;
}

- (void) dealloc
{
  [userNickname release];
  [avatarImagePath release];
  [dateCreated release];
	[super dealloc];
}

@end
