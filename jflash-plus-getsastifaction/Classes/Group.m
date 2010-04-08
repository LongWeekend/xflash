//
//  Group.m
//  jFlash
//
//  Created by Mark Makdad on 10/10/09.
//  Copyright 2009 LONG WEEKEND INC.. All rights reserved.
//

#import "Group.h"

@implementation Group
@synthesize groupId, groupName, ownerId, tagCount, childGroupCount;


- (id) init
{
  [self setOwnerId:0];
  [self setTagCount:-1];
  [self setChildGroupCount:-1];
  [self setGroupId:0];
  [self setGroupName:nil];
  return self;
}

//takes a sqlite result set and populates the properties of tag
- (void) hydrate: (FMResultSet*) rs
{
	[self setGroupId:   [rs intForColumn:@"group_id"]];
  [self setGroupName: [rs stringForColumn:@"group_name"]];
  [self setOwnerId:   [rs intForColumn:@"owner_id"]];
  [self setTagCount:  [rs intForColumn:@"tag_count"]];
}

// Retrieves out a list of tags based on this group ID (direct children)
- (NSMutableArray*) getTags
{
  NSMutableArray* tags = nil;
  if (groupId >= 0)
  {
    tags = (NSMutableArray*)[TagPeer retrieveTagListByGroupId:groupId];
  }
  return tags;
}

// Gets a number of children groups
- (NSInteger) getChildGroupCount
{
  int returnVal = 0;
  if (childGroupCount >= 0)
  {
    returnVal = childGroupCount;
  }
  else
  {
    NSMutableArray* groups = (NSMutableArray*)[GroupPeer retrieveGroupsByOwner:self.groupId];
    [self setChildGroupCount:[groups count]];
    returnVal = [groups count];
  }
  return returnVal;
}

// Get number of children tags
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
