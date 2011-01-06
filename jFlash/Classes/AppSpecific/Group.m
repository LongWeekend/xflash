//
//  Group.m
//  jFlash
//
//  Created by Mark Makdad on 10/10/09.
//  Copyright 2009 LONG WEEKEND INC.. All rights reserved.
//

#import "Group.h"

//! Group contains Tag objects for display to the user in categorical hierarchies
@implementation Group
@synthesize groupId, groupName, ownerId, tagCount, childGroupCount, recommended;


- (id) init
{
  [self setOwnerId:0];
  [self setTagCount:-1];
  [self setChildGroupCount:-1];
  [self setGroupId:0];
  [self setGroupName:nil];
  [self setRecommended:0];
  return self;
}

//!takes a sqlite result set and populates the properties of tag
- (void) hydrate: (FMResultSet*) rs
{
	[self setGroupId:    [rs intForColumn:@"group_id"]];
  [self setGroupName:  [rs stringForColumn:@"group_name"]];
  [self setOwnerId:    [rs intForColumn:@"owner_id"]];
  [self setTagCount:   [rs intForColumn:@"tag_count"]];
  [self setRecommended:[rs intForColumn:@"recommended"]];
}

//! Retrieves out a list of Tag objects based on this Group ID (direct children)
- (NSMutableArray*) getTags
{
  NSMutableArray* tags = nil;
  if (groupId >= 0)
  {
    tags = [TagPeer retrieveTagListByGroupId:groupId];
  }
  return tags;
}

//! Gets a number of children group objects
- (NSInteger) getChildGroupCount
{
  int returnVal = 0;
  if (childGroupCount >= 0)
  {
    returnVal = childGroupCount;
  }
  else
  {
    NSMutableArray* groups = [GroupPeer retrieveGroupsByOwner:self.groupId];
    [self setChildGroupCount:[groups count]];
    returnVal = [groups count];
  }
  return returnVal;
}

//! Get number of children tags
- (NSInteger) getChildTagCount
{
  return [self tagCount];
}

- (void) dealloc
{
  [groupName release];
	[super dealloc];
}

@end
