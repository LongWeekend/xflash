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
  self = [super init];
  if (self)
  {
    self.tagCount = -1;
    self.childGroupCount = -1;
  }
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
- (NSArray*) childTags
{
  if (self.groupId >= 0)
  {
    return [TagPeer retrieveTagListByGroupId:groupId];
  }
  else
  {
    return nil;
  }
}

- (void) setChildGroupCount:(NSInteger)newChildGroupCount
{
  childGroupCount = newChildGroupCount;
}

//! Gets a number of children group objects
- (NSInteger) childGroupCount
{
  if (childGroupCount < 0)
  {
    NSArray *groups = [GroupPeer retrieveGroupsByOwner:self.groupId];
    childGroupCount = [groups count];
  }
  return childGroupCount;
}

#pragma mark -

- (void) dealloc
{
  [groupName release];
	[super dealloc];
}

@end
