//
//  UserPeer.m
//  jFlash
//
//  Created by Mark Makdad on 6/13/10.
//  Copyright 2010 Long Weekend Inc. All rights reserved.
//

#import "UserPeer.h"

/**
 * Peer class for User class - operates on User objects (retrieval, storage, et al)
 */
@implementation UserPeer

/** Gets all users from the DB into an array of User objects */
+ (NSMutableArray*) getUsers
{
  LWEDatabase *db = [LWEDatabase sharedLWEDatabase];
  FMResultSet *rs = [db executeQuery:@"SELECT * FROM users ORDER by user_id ASC"];
  
  User *tmpUser = nil;
  NSMutableArray *userList = [NSMutableArray array];
	while ([rs next])
  {
		tmpUser = [[User alloc] init];
		[tmpUser hydrate:rs];
		[userList addObject:tmpUser];
    [tmpUser release];
  }
  [rs close];
  return userList;
}


/** Creates a new user in the database */
+ (User*)createUserWithNickname:(NSString*)name avatarImagePath:(NSString*)path
{  
  User* tmpUser = [[[User alloc] init] autorelease];
  tmpUser.userNickname = name;
  tmpUser.avatarImagePath = path;
  
  LWEDatabase *db = [LWEDatabase sharedLWEDatabase];
  NSString *sql = [[NSString alloc] initWithFormat:@"INSERT INTO users (nickname, avatar_image_path, date_created) VALUES ('%@','%@',NOW())", name, path];
  [db executeUpdate:sql];
  [sql release];
  return tmpUser;  
}


/** Gets a user by user Id */
+ (User*) getUserByPK: (NSInteger)userId
{
  LWEDatabase *db = [LWEDatabase sharedLWEDatabase];
  NSString *sql = [[NSString alloc] initWithFormat:@"SELECT * FROM users WHERE user_id = %d", userId];
  FMResultSet *rs = [db executeQuery:sql];
  [sql release];
  User* tmpUser = [[[User alloc] init] autorelease];
  while ([rs next])
  {
    [tmpUser hydrate:rs];
  }
  [rs close];
  return tmpUser;
}

@end
