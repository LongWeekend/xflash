//
//  User.m
//  jFlash
//
//  Created by Paul Chapman on 28/01/10.
//  Copyright 2010 LONG WEEKEND INC.. All rights reserved.
//

#import "User.h"

@implementation User
@synthesize userId, userNickname, avatarImagePath, dateCreated;

// Takes a sqlite result set and populates the properties of user
- (void) hydrate: (FMResultSet*) rs
{
  self.userId          = [rs intForColumn:@"user_id"];
  self.userNickname    = [rs stringForColumn:@"nickname"];
  self.avatarImagePath = [rs stringForColumn:@"avatar_image_path"];
  if([self.avatarImagePath length] == 0) self.avatarImagePath = DEFAULT_USER_AVATAR_PATH;
  self.dateCreated     = [rs stringForColumn:@"date_created"];
}

- (void) save
{
  LWEDatabase *db = [LWEDatabase sharedLWEDatabase];
  NSString *sql;
  if(self.userId > 0){
    sql = [NSString stringWithFormat:@"UPDATE users SET nickname ='%@', avatar_image_path='%@' WHERE user_id = %d", userNickname, avatarImagePath, userId];
  } else {
    sql = [NSString stringWithFormat:@"INSERT INTO users (nickname, avatar_image_path) VALUES ('%@','%@')", userNickname, avatarImagePath];
  }
  [[db dao] executeUpdate:sql];
}

- (void) deleteUser
{
  LWEDatabase *db = [LWEDatabase sharedLWEDatabase];
  NSString *sql = [[NSString alloc] initWithFormat:@"DELETE FROM users WHERE user_id = %d", userId];
  [[db dao] executeUpdate:sql];
  [sql release];
  sql = [[NSString alloc] initWithFormat:@"DELETE FROM user_history WHERE user_id = %d", userId];
  [[db dao] executeUpdate:sql];
  [sql release];
}



#pragma mark - Class plumbing

- (id) init
{
  self = [super init];
  if (self)
  {
    self.userId          = 0;
    self.userNickname    = nil;
    self.avatarImagePath = DEFAULT_USER_AVATAR_PATH;
    self.dateCreated     = nil;
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
