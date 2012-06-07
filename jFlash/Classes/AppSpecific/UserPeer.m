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
+ (NSArray *)allUsers
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
  return (NSArray *)userList;
}

/** Gets a user by user Id */
+ (User *)userWithUserId:(NSInteger)userId
{
  LWEDatabase *db = [LWEDatabase sharedLWEDatabase];
  FMResultSet *rs = [db.dao executeQuery:@"SELECT * FROM users WHERE user_id = ?",[NSNumber numberWithInt:userId]];
  User *tmpUser = [[[User alloc] init] autorelease];
  while ([rs next])
  {
    [tmpUser hydrate:rs];
  }
  [rs close];
  return tmpUser;
}

@end
