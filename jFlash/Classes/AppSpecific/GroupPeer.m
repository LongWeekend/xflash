//
//  GroupPeer.m
//  jFlash
//
//  Created by Mark Makdad on 10/10/09.
//  Copyright 2009 LONG WEEKEND INC.. All rights reserved.
//

#import "GroupPeer.h"

//! Handles retrieval of Group objects from the database
@implementation GroupPeer


//! Returns a Group object hydrated based on groupId parameter
+ (Group*) retrieveGroupById:(NSInteger)groupId
{
  LWEDatabase *db = [LWEDatabase sharedLWEDatabase];
	NSString *sql = [[NSString alloc] initWithFormat:@"SELECT * FROM groups WHERE group_id = %d LIMIT 1",groupId];
	FMResultSet *rs = [db executeQuery:sql];
  Group *tmpGroup = nil;
  while ([rs next])
  {
    tmpGroup = [[[Group alloc] init] autorelease];
		[tmpGroup hydrate:rs];
	}
	[rs close];
	[sql release];
	return tmpGroup;  
}

//! Gets a tag's parent
+ (NSInteger) parentGroupIdOfTag:(Tag*)tag
{
  LWEDatabase *db = [LWEDatabase sharedLWEDatabase];
	NSString *sql = [[NSString alloc] initWithFormat:@"SELECT group_id FROM group_tag_link WHERE tag_id = %d LIMIT 1",tag.tagId];
	FMResultSet *rs = [db executeQuery:sql];
  NSInteger groupId = 0;
	while ([rs next]) 
  {
    groupId = [rs intForColumn:@"group_id"];
	}
	[rs close];
	[sql release];
  return groupId;
}

//! Returns an array of Group objects all owned by the id passed on ownerId parameter
+(NSArray*) retrieveGroupsByOwner:(NSInteger)ownerId
{
  LWEDatabase *db = [LWEDatabase sharedLWEDatabase];
	NSMutableArray *groups = [NSMutableArray array];
	NSString *sql = [[NSString alloc] initWithFormat:@"SELECT * FROM groups WHERE owner_id = '%d' ORDER BY recommended DESC, group_name ASC",ownerId];
	FMResultSet *rs = [db executeQuery:sql];
	while ([rs next])
  {
		Group *tmpGroup = [[[Group alloc] init] autorelease];
		[tmpGroup hydrate:rs];
		[groups addObject:tmpGroup];
	}
	[rs close];
	[sql release];
	return (NSArray*)groups;  
}

@end
