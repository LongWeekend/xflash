//
//  TagPeer.m
//  jFlash
//
//  Created by paul on 5/6/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "TagPeer.h"

@implementation TagPeer

// void createTag
// adds a new tag to the database
+ (int) createTag: (NSString*) tagName withOwner: (NSInteger) ownerId
{
  LWEDatabase *db = [LWEDatabase sharedLWEDatabase];
  NSString *sql = [[NSString alloc] initWithFormat:@"INSERT INTO tags (tag_name) VALUES ('%@')",tagName];
  [[db dao] executeUpdate:sql];
  [sql release];
  int lastTagId = (int)[db dao].lastInsertRowId;
  if ([db dao].hadError == NO)
  {
    // Link it
    sql = [[NSString alloc] initWithFormat:@"INSERT INTO group_tag_link (tag_id, group_id) VALUES ('%d','%d')",lastTagId,ownerId];
    [[db dao] executeUpdate:sql];
    [sql release];
    // Update the cache
    sql = [[NSString alloc] initWithFormat:@"UPDATE groups SET tag_count=(tag_count+1) WHERE group_id = '%d'",ownerId];
    [[db dao] executeUpdate:sql];
    [sql release];
  }
  else
  {
    // We should fail here.
    NSLog(@"Unable to insert tag name: %@",tagName);
    lastTagId = 0;
  }
  return lastTagId;
}


// void cancelMembership
// Checks if a passed tagId/cardId are matched
+ (void) cancelMembership: (NSInteger) cardId tagId: (NSInteger) tagId
{
  LWEDatabase *db = [LWEDatabase sharedLWEDatabase];
	FMDatabase *dao = [db dao];
	NSString *sql  = [[NSString alloc] initWithFormat:@"DELETE FROM card_tag_link WHERE card_id = '%d' AND tag_id = '%d'",cardId,tagId];
  NSString *sql2 = [[NSString alloc] initWithFormat:@"UPDATE tags SET count=(count-1) WHERE tag_id = '%d'",tagId];
  [dao beginTransaction];
  [dao executeUpdate:sql];
  [dao executeUpdate:sql2];
  [dao commit];
	[sql release];
	[sql2 release];
  if ([dao hadError])
  {
    NSLog(@"Err %d: %@", [dao lastErrorCode], [dao lastErrorMessage]);
  }
}


// void checkMembership
// Checks if a passed tagId/cardId are matched
+ (BOOL) checkMembership: (NSInteger) cardId tagId: (NSInteger) tagId
{
  LWEDatabase *db = [LWEDatabase sharedLWEDatabase];
	FMDatabase *dao = [db dao];
	NSString *sql = [[NSString alloc] initWithFormat:@"SELECT * FROM card_tag_link WHERE card_id = '%d' AND tag_id = '%d'",cardId,tagId];
	FMResultSet *rs = [dao executeQuery:sql];
  [sql release];
	while ([rs next])
  {
    [rs close];
    return YES;
	}
	[rs close];
  return NO;
}


// Returns an array of tag Ids this card is a member of
+ (NSMutableArray*) membershipListForCardId:(NSInteger)cardId
{
  LWEDatabase *db = [LWEDatabase sharedLWEDatabase];
	FMDatabase *dao = [db dao];
  NSMutableArray *membershipListArray = [[[NSMutableArray alloc] init] autorelease];
  int tmpTagId = 0;
	NSString *sql = [[NSString alloc] initWithFormat:@"SELECT t.tag_id AS tag_id FROM tags t, card_tag_link c WHERE t.tag_id = c.tag_id AND c.card_id = '%d'",cardId];
	FMResultSet *rs = [dao executeQuery:sql];
  [sql release];
	while ([rs next])
  {
    tmpTagId = [rs intForColumn:@"tag_id"];
    [membershipListArray addObject:[NSNumber numberWithInt:tmpTagId]];
	}
	[rs close];
  return membershipListArray;
}



// void subscribe: cardId tagId: tagId
// Subscribes a card to a given tag
+ (void) subscribe: (NSInteger) cardId tagId: (NSInteger) tagId
{
  LWEDatabase *db = [LWEDatabase sharedLWEDatabase];
	NSString *sql  = [[NSString alloc] initWithFormat:@"INSERT INTO card_tag_link (card_id,tag_id) VALUES (%d,%d)",cardId,tagId];
  NSString *sql2 = [[NSString alloc] initWithFormat:@"UPDATE tags SET count=(count+1) WHERE tag_id = %d",tagId];
  [[db dao] beginTransaction];
  [[db dao] executeUpdate:sql];
  [[db dao] executeUpdate:sql2];
  [[db dao] commit];
	[sql release];
	[sql2 release];
  if ([[db dao] hadError])
  {
    NSLog(@"Err %d: %@", [[db dao] lastErrorCode], [[db dao] lastErrorMessage]);
  }
}


// NSMutableArray retrieveTagListWithSQL: sql
// Gets tags based on the SQL you give us
+ (NSMutableArray*) retrieveTagListWithSQL: (NSString*) sql
{
	NSMutableArray* tags = [[[NSMutableArray alloc] init] autorelease];
  LWEDatabase *db = [LWEDatabase sharedLWEDatabase];
	FMResultSet *rs = [[db dao] executeQuery:sql];
	while ([rs next]) {
		Tag* tmpTag = [[Tag alloc] init];
		[tmpTag hydrate:rs];
		[tags addObject:tmpTag];
		[tmpTag release];
	}
	[rs close];
	return tags;
}


// NSMutableArray retrieveMyTagList
// Gets my tags (ones created by the user)
+ (NSMutableArray*) retrieveMyTagList
{
	NSString *sql = [[NSString alloc] initWithFormat:@"SELECT *, UPPER(tag_name) as utag_name FROM tags WHERE editable = 1 ORDER BY utag_name ASC"];
  NSMutableArray* tmpTags = [TagPeer retrieveTagListWithSQL: sql];
	[sql release];
	return tmpTags;
}


// NSMutableArray retrieveSysTagList
// Gets my tags (ones created by the system)
+ (NSMutableArray*) retrieveSysTagList
{
	NSString *sql = [[NSString alloc] initWithFormat:@"SELECT *, UPPER(tag_name) as utag_name FROM tags WHERE editable = 0 ORDER BY utag_name ASC"];
  NSMutableArray* tmpTags = [TagPeer retrieveTagListWithSQL: sql];
	[sql release];
	return tmpTags;
}


// NSMutableArray retrieveTagListByGroupId
// Gets my tags (ones created by the system)
+ (NSMutableArray*) retrieveTagListByGroupId: (NSInteger)groupId
{
	NSString *sql = [[NSString alloc] initWithFormat:@"SELECT * FROM tags t, group_tag_link l WHERE t.tag_id = l.tag_id AND l.group_id = %d ORDER BY t.tag_name ASC",groupId];
	NSMutableArray* tmpTags = [TagPeer retrieveTagListWithSQL: sql];
	[sql release];
	return tmpTags;
}

// Tag retrieveTagListLike: tagId
// Gets a tag with a title LIKE '%string%'
+ (NSMutableArray*) retrieveTagListLike: (NSString*)string
{
	NSString *sql = [[NSString alloc] initWithFormat:@"SELECT * FROM tags WHERE tag_name LIKE '%%%@%%' ORDER BY tag_name ASC",string];
	NSMutableArray* tmpTags = [TagPeer retrieveTagListWithSQL: sql];
	[sql release];
	return tmpTags;
}


// Tag retrieveTagById: tagId
// Gets a tag by its id (PK)
+ (Tag*) retrieveTagById: (NSInteger) tagId
{
  LWEDatabase *db = [LWEDatabase sharedLWEDatabase];
	NSString *sql = [[NSString alloc] initWithFormat:@"SELECT * FROM tags WHERE tag_id = %d LIMIT 1",tagId];
	FMResultSet *rs = [[db dao] executeQuery:sql];
  Tag* tmpTag = [[[Tag alloc] init] autorelease];
	while ([rs next])
  {
		[tmpTag hydrate:rs];
	}
	[rs close];
	[sql release];
	return tmpTag;  
}


// BOOL deleteTag: tagId
// Deletes a tag and all word links
+ (BOOL) deleteTag:(NSInteger) tagId
{
  LWEDatabase *db = [LWEDatabase sharedLWEDatabase];
  // First get owner id of a tag
	NSString *sql4  = [[NSString alloc] initWithFormat:@"SELECT group_id FROM group_tag_link WHERE tag_id = %d",tagId];
  FMResultSet *rs = [[db dao] executeQuery:sql4];
  [sql4 release];
  int groupId = 0;
	while ([rs next])
  {
    groupId = [rs intForColumn:@"group_id"];
	}
  [rs close];
  // Now do everything
	NSString *sql  = [[NSString alloc] initWithFormat:@"DELETE FROM card_tag_link WHERE tag_id = %d",tagId];
  NSString *sql2 = [[NSString alloc] initWithFormat:@"DELETE FROM tags WHERE tag_id = %d",tagId];
  NSString *sql3 = [[NSString alloc] initWithFormat:@"UPDATE groups SET tag_count = (tag_count-1) WHERE group_id = '%d'",groupId];
  [[db dao] beginTransaction];
  [[db dao] executeUpdate:sql];
  [[db dao] executeUpdate:sql2];
  [[db dao] executeUpdate:sql3];
  [[db dao] commit];
	[sql release];
	[sql2 release];
	[sql3 release];
  if ([[db dao] hadError])
  {
    NSLog(@"Err %d: %@", [[db dao] lastErrorCode], [[db dao] lastErrorMessage]);
    return NO;
  }
  return YES;
}

@end
