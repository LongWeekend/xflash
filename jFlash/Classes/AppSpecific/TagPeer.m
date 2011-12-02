//
//  TagPeer.m
//  jFlash
//
//  Created by paul on 5/6/09.
//  Copyright 2009 Long Weekend LLC. All rights reserved.
//

#import "TagPeer.h"

NSString * const kTagPeerErrorDomain         = @"kTagPeerErrorDomain";
NSUInteger const kRemoveLastCardOnATagError  = 999;

NSString * const LWETagContentDidChange = @"LWETagContentDidChange";
NSString * const LWETagContentDidChangeTypeKey = @"LWETagContentDidChangeTypeKey";
NSString * const LWETagContentDidChangeCardKey = @"LWETagContentDidChangeCardKey";
NSString * const LWETagContentCardAdded = @"LWETagContentCardAdded";
NSString * const LWETagContentCardRemoved = @"LWETagContentCardRemoved";

@interface TagPeer ()
+ (NSArray*) _retrieveTagListWithSQL:(NSString*)sql;
+ (Tag*) _retrieveTagWithSQL:(NSString*)sql;
@end

//! Handles retrieval, creation, deletion, and updating of Tag objects in database
@implementation TagPeer

#pragma mark - Caching Methods

/** Recaches card counts for user tags */
+ (void) recacheCountsForUserTags
{
  LWEDatabase *db = [LWEDatabase sharedLWEDatabase];
  
  FMResultSet *userTagsRS = [db executeQuery:@"SELECT tag_id FROM tags WHERE editable = 1"];
  while ([userTagsRS next])
  {
    // Get the number of cards
    NSInteger tagId = [userTagsRS intForColumn:@"tag_id"];
    NSString *sql = [NSString stringWithFormat:@"SELECT card_id FROM card_tag_link WHERE tag_id = %d",tagId];
    FMResultSet *cardsInTagRS = [db executeQuery:sql];
    
    NSInteger numCards = 0;
    while ([cardsInTagRS next])
    {
      numCards = numCards + 1;
    }
    [cardsInTagRS close];
    
    // Now do the update
    Tag *tmpTag = [[Tag alloc] init]; // encapsulation is a bitch but one we should heed
    tmpTag.tagId = tagId;
    [TagPeer setCardCount:numCards forTag:tmpTag];
    [tmpTag release];
    
    [db executeUpdate:[NSString stringWithFormat:@"UPDATE tags SET count = %d WHERE tag_id = %d",numCards,tagId]];
    LWE_LOG(@"tag id %d has %d cards",tagId,numCards);
  }
  [userTagsRS close];
}

+ (void) setCardCount:(NSInteger)newCount forTag:(Tag*)tag
{
  LWEDatabase *db = [LWEDatabase sharedLWEDatabase];
  NSString *sql = [NSString stringWithFormat:@"UPDATE tags SET count = '%d' WHERE tag_id = '%d'",newCount,tag.tagId];
  [db executeUpdate:sql];
}

#pragma mark - Membership Methods

/**
 * \brief   Removes cardId from Tag indicated by parameter tagId
 * \details This method will also check regarding the last card on the active set. 
 *          and automatically remove that card from the active set card cache.
 *          Note that this method DOES update the tag count cache on the tags table.
 */
+ (BOOL)cancelMembership:(Card*)card fromTag:(Tag*)tag error:(NSError **)theError
{
  LWEDatabase *db = [LWEDatabase sharedLWEDatabase];
  
  // First check whether the removed card is in the active tag.
  // if the tagId supplied is the active card, check for last card cause we dont
  // want the last card being removed from a tag. 
  CurrentState *currentState = [CurrentState sharedCurrentState];
  if ([tag isEqual:currentState.activeTag])
  {
    LWE_LOG(@"Editing current set tags");

    NSString *countSql = [NSString stringWithFormat:@"SELECT count(card_id) AS total_card FROM card_tag_link WHERE tag_id = '%d'", tag.tagId];
    FMResultSet *rs = [db executeQuery:countSql];
    
    NSInteger totalCard = 0;
    while ([rs next])
    {
      totalCard = [rs intForColumn:@"total_card"];
    }
    
    if (totalCard <= 1)
    {
      LWE_LOG(@"Last card in set");
      //this is the last card, abort!
      //Construct the error object to be returned back to its caller.
      NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                NSLocalizedString(@"This set only contains the card you are currently studying.  To delete a set entirely, please change to a different set first.", @"AddTagViewController.AlertViewLastCardMessage"), NSLocalizedDescriptionKey,
                                nil];
      
      if (theError != NULL)
      {
        *theError = [NSError errorWithDomain:kTagPeerErrorDomain code:kRemoveLastCardOnATagError userInfo:userInfo];
      }
      return NO;
    }
  }

  // Now execute the deletion from card_tag_link
	NSString *sql = [NSString stringWithFormat:@"DELETE FROM card_tag_link WHERE card_id = '%d' AND tag_id = '%d'",card.cardId,tag.tagId];
  [db executeUpdate:sql];

  // Only update this stuff if not the active set
  if ([tag isEqual:currentState.activeTag] == NO)
  {
    // Update the tag's card count cache
    [db executeUpdate:[NSString stringWithFormat:@"UPDATE tags SET count = (count - 1) WHERE tag_id = %d",tag.tagId]];
    
    if (db.dao.hadError)
    {
      LWE_LOG(@"Err %d: %@", [db.dao lastErrorCode], [db.dao lastErrorMessage]);
      NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                db.dao.lastErrorMessage,NSLocalizedDescriptionKey,nil];
      
      //put the error information and send it back to whoever calls this function.
      if (theError != NULL)
      {
        *theError = [NSError errorWithDomain:kTagPeerErrorDomain code:db.dao.lastErrorCode userInfo:userInfo];
      }
      return NO;
    }
  }
  
  // Finally, send a system-wide notification that this tag changed. Interested objects can listen.
  NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                            LWETagContentCardRemoved,LWETagContentDidChangeTypeKey,
                            card,LWETagContentDidChangeCardKey,
                            nil];
  [[NSNotificationCenter defaultCenter] postNotificationName:LWETagContentDidChange
                                                      object:tag
                                                    userInfo:userInfo];
  return YES;
}

//! Checks if a passed tagId/cardId are matched
+ (BOOL) card:(Card*)card isMemberOfTag:(Tag*)tag
{
  BOOL returnVal = NO;
  LWEDatabase *db = [LWEDatabase sharedLWEDatabase];
	NSString *sql = [NSString stringWithFormat:@"SELECT * FROM card_tag_link WHERE card_id = '%d' AND tag_id = '%d'",card.cardId,tag.tagId];
	FMResultSet *rs = [db executeQuery:sql];
	while ([rs next])
  {
    returnVal = YES;
	}
	[rs close];
  return returnVal;
}

//! Returns an array of tag Ids this card is a member of
+ (NSArray*) membershipListForCard:(Card*)card
{
  LWEDatabase *db = [LWEDatabase sharedLWEDatabase];
  NSMutableArray *membershipListArray = [NSMutableArray array];
  NSInteger tmpTagId = 0;
	NSString *sql = [NSString stringWithFormat:@"SELECT t.tag_id AS tag_id FROM tags t, card_tag_link c WHERE t.tag_id = c.tag_id AND c.card_id = '%d'",card.cardId];
	FMResultSet *rs = [db executeQuery:sql];
	while ([rs next])
  {
    tmpTagId = [rs intForColumn:@"tag_id"];
    [membershipListArray addObject:[NSNumber numberWithInt:tmpTagId]];
	}
	[rs close];
  return (NSArray*)membershipListArray;
}



/**
 * Subscribes a Card to a given Tag based on parameter IDs
 * Note that this method DOES NOT update the tag count cache on the tags table
 */
+ (BOOL) subscribeCard:(Card*)card toTag:(Tag*)tag
{
  // Quick return on bad input
  if (tag == nil || card == nil || card.cardId <= 0)
  {
    return NO;
  }
  
  LWEDatabase *db = [LWEDatabase sharedLWEDatabase];

  // Insert tag link
	NSString *sql  = [NSString stringWithFormat:@"INSERT INTO card_tag_link (card_id,tag_id) VALUES (%d,%d)",card.cardId,tag.tagId];
  [db executeUpdate:sql];

  // Update tag count
	sql = [NSString stringWithFormat:@"UPDATE tags SET count = (count + 1) WHERE tag_id = %d",tag.tagId];
  [db executeUpdate:sql];

  if (db.dao.hadError)
  {
    LWE_LOG(@"Err %d: %@", db.dao.lastErrorCode, db.dao.lastErrorMessage);
    return NO;
  }
  
  // Finally, send a system-wide notification that this tag changed. Interested objects can listen.
  NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                            LWETagContentCardAdded,LWETagContentDidChangeTypeKey,
                            card,LWETagContentDidChangeCardKey,
                            nil];
  [[NSNotificationCenter defaultCenter] postNotificationName:LWETagContentDidChange
                                                      object:tag
                                                    userInfo:userInfo];
  return YES;
}

#pragma mark - Private Methods

//! Gets Tag array based on the SQL you give us
+ (NSArray*) _retrieveTagListWithSQL:(NSString*)sql
{
	NSMutableArray *tags = [NSMutableArray array];
  LWEDatabase *db = [LWEDatabase sharedLWEDatabase];
	FMResultSet *rs = [db executeQuery:sql];
	while ([rs next])
  {
		Tag *tmpTag = [[Tag alloc] init];
		[tmpTag hydrate:rs];
		[tags addObject:tmpTag];
		[tmpTag release];
	}
	[rs close];
	return (NSArray*)tags;
}

//! Gets a Tag based on SQL you give us
+ (Tag*) _retrieveTagWithSQL:(NSString*)sql
{
  LWEDatabase *db = [LWEDatabase sharedLWEDatabase];
	FMResultSet *rs = [db executeQuery:sql];
  // TODO: it would make more sense to return NIL if there were no tag, not an empty tag object.
  Tag *tmpTag = [[[Tag alloc] init] autorelease];
	while ([rs next])
  {
		[tmpTag hydrate:rs];
	}
	[rs close];
	return tmpTag;
}

#pragma mark - Convenience Methods to Abstract SQL

//! Gets system Tag objects as array
+ (NSArray*) retrieveSysTagList
{
  return [TagPeer _retrieveTagListWithSQL:@"SELECT *, UPPER(tag_name) as utag_name FROM tags WHERE editable = 0 ORDER BY utag_name ASC"];
}

//! Gets user Tag objects as array
+ (NSArray*) retrieveUserTagList
{
  return [TagPeer _retrieveTagListWithSQL:@"SELECT *, UPPER(tag_name) as utag_name FROM tags WHERE editable = 1 OR tag_id = 0 ORDER BY utag_name ASC"];
}

//! Gets system Tag objects that have card in them - as array
+ (NSArray*) retrieveSysTagListContainingCard:(Card*)card
{
	NSString *sql = [NSString stringWithFormat:@"SELECT *, UPPER(t.tag_name) as utag_name FROM card_tag_link l,tags t WHERE l.card_id = %d AND l.tag_id = t.tag_id AND t.editable = 0 ORDER BY utag_name ASC",card.cardId];
  return [TagPeer _retrieveTagListWithSQL:sql];
}

//! Returns array of Tag objects based on Group membership
+ (NSArray*) retrieveTagListByGroupId:(NSInteger)groupId
{
	NSString *sql = [NSString stringWithFormat:@"SELECT * FROM tags t, group_tag_link l WHERE t.tag_id = l.tag_id AND l.group_id = %d ORDER BY t.tag_name ASC",groupId];
	return [TagPeer _retrieveTagListWithSQL:sql];
}

//! Returns a Tag array containing any Tag with a title LIKE '%string%'
+ (NSArray*) retrieveTagListLike:(NSString*)string
{
	NSString *sql = [NSString stringWithFormat:@"SELECT * FROM tags WHERE tag_name LIKE '%%%@%%' ORDER BY tag_name ASC",string];
	return [TagPeer _retrieveTagListWithSQL:sql];
}

//! Gets a Tag by its id (PK)
+ (Tag*) retrieveTagById:(NSInteger)tagId
{
	NSString *sql = [NSString stringWithFormat:@"SELECT * FROM tags WHERE tag_id = %d LIMIT 1",tagId];
  return [TagPeer _retrieveTagWithSQL:sql];
}

//! Gets a Tag by its name
+ (Tag*) retrieveTagByName:(NSString*)tagName
{
	NSString *sql = [NSString stringWithFormat:@"SELECT * FROM tags WHERE tag_name like '%@' LIMIT 1",tagName];
  return [TagPeer _retrieveTagWithSQL:sql];
}

#pragma mark - Create & Delete

//! adds a new tag to the database, returns new tag object, nil in case of error
+ (Tag*) createTagNamed:(NSString*)tagName inGroup:(Group*)owner
{
  return [[self class] createTagNamed:tagName inGroup:owner withDescription:@""];
}

//! Adds a new tag to the database, returns new tag object, nil if error
+ (Tag*) createTagNamed:(NSString*)tagName inGroup:(Group*)owner withDescription:(NSString*)description;
{
  LWE_ASSERT_EXC([tagName isKindOfClass:[NSString class]],@"You must pass a string as the tag name");
  
  // Escape the string for SQLITE-style escapes (cannot use backslash!)
  tagName = [tagName stringByReplacingOccurrencesOfString:@"'" withString:@"''" options:NSLiteralSearch range:NSMakeRange(0, tagName.length)];
  NSString *sql = [NSString stringWithFormat:@"INSERT INTO tags (tag_name, description) VALUES ('%@', '%@')",tagName,description];
  LWEDatabase *db = [LWEDatabase sharedLWEDatabase];
  [db executeUpdate:sql];
  
  NSInteger lastTagId = (NSInteger)db.dao.lastInsertRowId;
  Tag *createdTag = nil;
  if (db.dao.hadError == NO)
  {
    // Link it & then update the tag card count cache
    [db executeUpdate:[NSString stringWithFormat:@"INSERT INTO group_tag_link (tag_id, group_id) VALUES ('%d','%d')",lastTagId,owner.groupId]];
    [db executeUpdate:[NSString stringWithFormat:@"UPDATE groups SET tag_count=(tag_count+1) WHERE group_id = '%d'",owner.groupId]];
    createdTag = [TagPeer retrieveTagById:lastTagId];
  }
  return createdTag;
}

//! Deletes a tag and all Card links
+ (BOOL) deleteTag:(Tag*)tag
{
  LWEDatabase *db = [LWEDatabase sharedLWEDatabase];
  
  // First get owner id of a tag
	NSString *sql4  = [NSString stringWithFormat:@"SELECT group_id FROM group_tag_link WHERE tag_id = %d",tag.tagId];
  FMResultSet *rs = [db executeQuery:sql4];
  NSInteger groupId = 0;
	while ([rs next])
  {
    groupId = [rs intForColumn:@"group_id"];
	}
  [rs close];
  
  // Now do everything
	NSString *sql  = [NSString stringWithFormat:@"DELETE FROM card_tag_link WHERE tag_id = %d",tag.tagId];
  NSString *sql2 = [NSString stringWithFormat:@"DELETE FROM tags WHERE tag_id = %d",tag.tagId];
  NSString *sql3 = [NSString stringWithFormat:@"UPDATE groups SET tag_count = (tag_count-1) WHERE group_id = '%d'",groupId];
  [db.dao beginTransaction];
  [db.dao executeUpdate:sql];
  [db.dao executeUpdate:sql2];
  [db.dao executeUpdate:sql3];
  [db.dao commit];
  
  if (db.dao.hadError)
  {
    LWE_LOG(@"Err %d: %@", db.dao.lastErrorCode, db.dao.lastErrorMessage);
    return NO;
  }
  return YES;
}

@end