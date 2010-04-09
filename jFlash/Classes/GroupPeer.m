//
//  GroupPeer.m
//  jFlash
//
//  Created by Mark Makdad on 10/10/09.
//  Copyright 2009 LONG WEEKEND INC.. All rights reserved.
//

#import "GroupPeer.h"

@implementation GroupPeer

+ (Group*) retrieveGroupById: (NSInteger)groupId
{
  LWEDatabase *db = [LWEDatabase sharedLWEDatabase];
	NSString *sql = [[NSString alloc] initWithFormat:@"SELECT * FROM groups WHERE group_id = %d LIMIT 1",groupId];
	FMResultSet *rs = [[db dao] executeQuery:sql];
  Group* tmpGroup = [[[Group alloc] init] autorelease];
	while ([rs next]) {
		[tmpGroup hydrate:rs];
	}
	[rs close];
	[sql release];
	return tmpGroup;  
}

+(NSMutableArray*) retrieveGroupsByOwner: (NSInteger)ownerId
{
  LWEDatabase *db = [LWEDatabase sharedLWEDatabase];
	NSMutableArray* groups = [[[NSMutableArray alloc] init] autorelease];
	NSString *sql = [[NSString alloc] initWithFormat:@"SELECT * FROM groups WHERE owner_id = '%d' ORDER BY recommended DESC, group_name ASC",ownerId];
	FMResultSet *rs = [[db dao] executeQuery:sql];
	while ([rs next]) {
		Group* tmpGroup = [[[Group alloc] init] autorelease];
		[tmpGroup hydrate:rs];
		[groups addObject:tmpGroup];
	}
	[rs close];
	[sql release];
	return groups;  
}

@end
