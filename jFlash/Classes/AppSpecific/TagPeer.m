//
//  TagPeer.m
//  jFlash
//
//  Created by paul on 5/6/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "TagPeer.h"

//! Handles retrieval, creation, deletion, and updating of Tag objects in database
@implementation TagPeer

//! adds a new tag to the database, returns the tagId of the created tag, 0 in case of error
+ (int) createTag: (NSString*) tagName withOwner: (NSInteger) ownerId
{
  LWEDatabase *db = [LWEDatabase sharedLWEDatabase];
  NSString *sql = [[NSString alloc] initWithFormat:@"INSERT INTO tags (tag_name) VALUES ('%@')",tagName];
  [db executeUpdate:sql];
  [sql release];
  int lastTagId = (int)[db dao].lastInsertRowId;
  if ([db dao].hadError == NO)
  {
    // Link it
    sql = [[NSString alloc] initWithFormat:@"INSERT INTO group_tag_link (tag_id, group_id) VALUES ('%d','%d')",lastTagId,ownerId];
    [db executeUpdate:sql];
    [sql release];
    // Update the cache
    sql = [[NSString alloc] initWithFormat:@"UPDATE groups SET tag_count=(tag_count+1) WHERE group_id = '%d'",ownerId];
    [db executeUpdate:sql];
    [sql release];
  }
  else
  {
    //TODO: We should fail here.
    LWE_LOG(@"Unable to insert tag name: %@",tagName);
    lastTagId = 0;
  }
  return lastTagId;
}


/**
 * \brief Removes cardId from Tag indicated by parameter tagId
 * Note that this method DOES NOT update the tag count cache on the tags table
 */
+ (void) cancelMembership: (NSInteger) cardId tagId: (NSInteger) tagId
{
  LWEDatabase *db = [LWEDatabase sharedLWEDatabase];

	NSString *sql  = [[NSString alloc] initWithFormat:@"DELETE FROM card_tag_link WHERE card_id = '%d' AND tag_id = '%d'",cardId,tagId];
  [db executeUpdate:sql];
	[sql release];

  sql = [[NSString alloc] initWithFormat:@"UPDATE tags SET count = (count - 1) WHERE tag_id = %d",tagId];
  [db executeUpdate:sql];
  [sql release];
  
  if ([db.dao hadError])
  {
    LWE_LOG(@"Err %d: %@", [db.dao lastErrorCode], [db.dao lastErrorMessage]);
  }
}


//! Checks if a passed tagId/cardId are matched
+ (BOOL) checkMembership: (NSInteger) cardId tagId: (NSInteger) tagId
{
  LWEDatabase *db = [LWEDatabase sharedLWEDatabase];
	NSString *sql = [[NSString alloc] initWithFormat:@"SELECT * FROM card_tag_link WHERE card_id = '%d' AND tag_id = '%d'",cardId,tagId];
	FMResultSet *rs = [db executeQuery:sql];
  [sql release];
	while ([rs next])
  {
    [rs close];
    return YES;
	}
	[rs close];
  return NO;
}

/** Recaches card counts for user tags */
+ (void) recacheCountsForUserTags
{
  LWEDatabase *db = [LWEDatabase sharedLWEDatabase];
	NSString *sql = [[NSString alloc] initWithString:@"SELECT tag_id FROM tags WHERE editable = 1"];
  FMResultSet *rs = [db executeQuery:sql];
  [sql release];
  int numCards;
  int tmpTagId;
  while ([rs next])
  {
    tmpTagId = [rs intForColumn:@"tag_id"];
    // Get the number of cards
    sql = [[NSString alloc] initWithFormat:@"SELECT card_id FROM card_tag_link WHERE tag_id = %d",tmpTagId];
    FMResultSet *rs2 = [db executeQuery:sql];
    [sql release];
    numCards = 0;
    while ([rs2 next])
    {
      numCards = numCards + 1;
    }
    LWE_LOG(@"tag id %d has %d cards",tmpTagId,numCards);
    [rs2 close];
    
    // Now do the update
    sql = [[NSString alloc] initWithFormat:@"UPDATE tags SET count = %d WHERE tag_id = %d",numCards,tmpTagId];
    [db executeUpdate:sql];
    [sql release];
  }
  [rs close];
}


//! Returns an array of tag Ids this card is a member of
+ (NSMutableArray*) membershipListForCardId:(NSInteger)cardId
{
  LWEDatabase *db = [LWEDatabase sharedLWEDatabase];
  NSMutableArray *membershipListArray = [[[NSMutableArray alloc] init] autorelease];
  int tmpTagId = 0;
	NSString *sql = [[NSString alloc] initWithFormat:@"SELECT t.tag_id AS tag_id FROM tags t, card_tag_link c WHERE t.tag_id = c.tag_id AND c.card_id = '%d'",cardId];
	FMResultSet *rs = [db executeQuery:sql];
  [sql release];
	while ([rs next])
  {
    tmpTagId = [rs intForColumn:@"tag_id"];
    [membershipListArray addObject:[NSNumber numberWithInt:tmpTagId]];
	}
	[rs close];
  return membershipListArray;
}



/**
 * Subscribes a Card to a given Tag based on parameter IDs
 * Note that this method DOES NOT update the tag count cache on the tags table
 */
+ (void) subscribe: (NSInteger) cardId tagId: (NSInteger) tagId
{
  LWEDatabase *db = [LWEDatabase sharedLWEDatabase];
  // Insert tag link
	NSString *sql  = [[NSString alloc] initWithFormat:@"INSERT INTO card_tag_link (card_id,tag_id) VALUES (%d,%d)",cardId,tagId];
  [db executeUpdate:sql];
	[sql release];

  // Update tag count
	sql = [[NSString alloc] initWithFormat:@"UPDATE tags SET count = (count + 1) WHERE tag_id = %d",tagId];
  [db executeUpdate:sql];
  [sql release];

  if ([[db dao] hadError])
  {
    LWE_LOG(@"Err %d: %@", [[db dao] lastErrorCode], [[db dao] lastErrorMessage]);
  }
}


//! Gets Tag array based on the SQL you give us
+ (NSMutableArray*) retrieveTagListWithSQL: (NSString*) sql
{
	NSMutableArray* tags = [[[NSMutableArray alloc] init] autorelease];
  LWEDatabase *db = [LWEDatabase sharedLWEDatabase];
	FMResultSet *rs = [db executeQuery:sql];
	while ([rs next])
  {
		Tag* tmpTag = [[Tag alloc] init];
		[tmpTag hydrate:rs];
		[tags addObject:tmpTag];
		[tmpTag release];
	}
	[rs close];
	return tags;
}


//! Gets my Tag objects (ones created by the user) as array
+ (NSMutableArray*) retrieveMyTagList
{
  return [TagPeer retrieveTagListByGroupId:0];
}


//! Gets system Tag objects as array
+ (NSMutableArray*) retrieveSysTagList
{
	NSString *sql = [[NSString alloc] initWithFormat:@"SELECT *, UPPER(tag_name) as utag_name FROM tags WHERE editable = 0 ORDER BY utag_name ASC"];
  NSMutableArray* tmpTags = [TagPeer retrieveTagListWithSQL:sql];
	[sql release];
	return tmpTags;
}

//! Gets system Tag objects as array
+ (NSMutableArray*) retrieveUserTagList
{
	NSString *sql = [[NSString alloc] initWithFormat:@"SELECT *, UPPER(tag_name) as utag_name FROM tags WHERE editable = 1 OR tag_id = 0 ORDER BY utag_name ASC"];
  NSMutableArray* tmpTags = [TagPeer retrieveTagListWithSQL:sql];
	[sql release];
	return tmpTags;
}


//! Gets system Tag objects that have card in them - as array
+ (NSMutableArray*) retrieveSysTagListContainingCard:(Card*)card
{
  NSInteger cardId = card.cardId;
	NSString *sql = [[NSString alloc] initWithFormat:@"SELECT *, UPPER(t.tag_name) as utag_name FROM card_tag_link l,tags t WHERE l.card_id = %d AND l.tag_id = t.tag_id AND t.editable = 0 ORDER BY utag_name ASC",cardId];
  NSMutableArray* tmpTags = [TagPeer retrieveTagListWithSQL:sql];
	[sql release];
	return tmpTags;
}


//! Returns array of Tag objects based on Group membership
+ (NSMutableArray*) retrieveTagListByGroupId: (NSInteger)groupId
{
	NSString *sql = [[NSString alloc] initWithFormat:@"SELECT * FROM tags t, group_tag_link l WHERE t.tag_id = l.tag_id AND l.group_id = %d ORDER BY t.tag_name ASC",groupId];
	NSMutableArray* tmpTags = [TagPeer retrieveTagListWithSQL:sql];
	[sql release];
	return tmpTags;
}


//! Returns a Tag array containing any Tag with a title LIKE '%string%'
+ (NSMutableArray*) retrieveTagListLike: (NSString*)string
{
	NSString *sql = [[NSString alloc] initWithFormat:@"SELECT * FROM tags WHERE tag_name LIKE '%%%@%%' ORDER BY tag_name ASC",string];
	NSMutableArray* tmpTags = [TagPeer retrieveTagListWithSQL: sql];
	[sql release];
	return tmpTags;
}


//! Gets a Tag by its id (PK)
+ (Tag*) retrieveTagById: (NSInteger) tagId
{
  LWEDatabase *db = [LWEDatabase sharedLWEDatabase];
	NSString *sql = [[NSString alloc] initWithFormat:@"SELECT * FROM tags WHERE tag_id = %d LIMIT 1",tagId];
	FMResultSet *rs = [db executeQuery:sql];
  Tag* tmpTag = [[[Tag alloc] init] autorelease];
	while ([rs next])
  {
		[tmpTag hydrate:rs];
	}
	[rs close];
	[sql release];
	return tmpTag;  
}

//! Gets a Tag by its name
+ (Tag*) retrieveTagByName: (NSString*) tagName
{
  LWEDatabase *db = [LWEDatabase sharedLWEDatabase];
	NSString *sql = [[NSString alloc] initWithFormat:@"SELECT * FROM tags WHERE tag_name like '%@' LIMIT 1",tagName];
	FMResultSet *rs = [db executeQuery:sql];
  Tag* tmpTag = [[[Tag alloc] init] autorelease];
	while ([rs next])
  {
		[tmpTag hydrate:rs];
	}
	[rs close];
	[sql release];
	return tmpTag;  
}


//! Deletes a tag and all Card links
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
    LWE_LOG(@"Err %d: %@", [[db dao] lastErrorCode], [[db dao] lastErrorMessage]);
    return NO;
  }
  return YES;
}

@end