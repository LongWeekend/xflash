//
//  Group.h
//  jFlash
//
//  Created by Mark Makdad on 10/10/09.
//  Copyright 2009 LONG WEEKEND INC.. All rights reserved.
//


@interface Group : NSObject
{
	NSInteger groupId;
	NSInteger ownerId;
	NSInteger tagCount;
  NSInteger childGroupCount;
	NSString *groupName;
}

- (void) hydrate:(FMResultSet*)rs;
- (NSMutableArray*) getTags;
- (NSInteger) getChildTagCount;
- (NSInteger) getChildGroupCount;

@property (nonatomic,retain) NSString *groupName;
@property NSInteger groupId;
@property NSInteger ownerId;
@property NSInteger tagCount;
@property NSInteger childGroupCount;

@end
