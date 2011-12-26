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

+ (Group*) topLevelGroup
{
  NSArray *groups = [[self class] retrieveGroupsByOwner:-1];
  LWE_ASSERT_EXC([groups count] == 1,@"There should be 1 and only 1 group in the DB with owner -1");
  return (Group*)[groups objectAtIndex:0];
}

//! Returns a Group object hydrated based on groupId parameter
+ (Group*) retrieveGroupById:(NSInteger)groupId
{
  LWEDatabase *db = [LWEDatabase sharedLWEDatabase];
	FMResultSet *rs = [db.dao executeQuery:@"SELECT * FROM groups WHERE group_id = ? LIMIT 1",[NSNumber numberWithInt:groupId]];
  Group *tmpGroup = nil;
  while ([rs next])
  {
    tmpGroup = [[[Group alloc] init] autorelease];
		[tmpGroup hydrate:rs];
	}
	[rs close];
	return tmpGroup;  
}

//! Gets a tag's parent
+ (NSInteger) parentGroupIdOfTag:(Tag*)tag
{
  LWEDatabase *db = [LWEDatabase sharedLWEDatabase];
	FMResultSet *rs = [db.dao executeQuery:@"SELECT group_id FROM group_tag_link WHERE tag_id = ? LIMIT 1",[NSNumber numberWithInt:tag.tagId]];
  NSInteger groupId = 0;
	while ([rs next]) 
  {
    groupId = [rs intForColumn:@"group_id"];
	}
	[rs close];
  return groupId;
}

//! Returns an array of Group objects all owned by the id passed on ownerId parameter
+(NSArray*) retrieveGroupsByOwner:(NSInteger)ownerId
{
  LWEDatabase *db = [LWEDatabase sharedLWEDatabase];
	FMResultSet *rs = [db.dao executeQuery:@"SELECT * FROM groups WHERE owner_id = ? ORDER BY recommended DESC, group_name ASC",[NSNumber numberWithInt:ownerId]];
	NSMutableArray *groups = [NSMutableArray array];
	while ([rs next])
  {
		Group *tmpGroup = [[[Group alloc] init] autorelease];
		[tmpGroup hydrate:rs];
		[groups addObject:tmpGroup];
	}
	[rs close];
	return (NSArray*)groups;  
}

@end
