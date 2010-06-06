//
//  Group.h
//  jFlash
//
//  Created by Mark Makdad on 10/10/09.
//  Copyright 2009 LONG WEEKEND INC.. All rights reserved.
//

#import "FMResultSet.h"
@interface Group : NSObject
{
	NSInteger groupId;
	NSInteger ownerId;            //! groupId of the parent Group
	NSInteger tagCount;           //! cached number of Tag items in the Group
	NSInteger recommended;        //! Is a recommended Group?
  NSInteger childGroupCount;    //! cached number of children Group objects
	NSString *groupName;          //! Display name
}

- (void) hydrate:(FMResultSet*)rs;
- (NSMutableArray*) getTags;
- (NSInteger) getChildTagCount;
- (NSInteger) getChildGroupCount;

@property (nonatomic,retain) NSString *groupName;
@property NSInteger groupId;
@property NSInteger ownerId;
@property NSInteger tagCount;
@property NSInteger recommended;
@property NSInteger childGroupCount;

@end
