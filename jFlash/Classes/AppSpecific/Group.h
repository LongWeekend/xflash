//
//  Group.h
//  jFlash
//
//  Created by Mark Makdad on 10/10/09.
//  Copyright 2009 LONG WEEKEND INC.. All rights reserved.
//

#import "FMResultSet.h"
@interface Group : NSObject

- (void) hydrate:(FMResultSet*)rs;
- (NSArray*) childTags;
- (NSInteger) getChildTagCount;
- (NSInteger) getChildGroupCount;

@property (retain) NSString *groupName;   //! Display name
@property NSInteger groupId;              //! groupId of the parent Group
@property NSInteger ownerId;
@property NSInteger tagCount;             //! cached number of Tag items in the Group
@property NSInteger recommended;          //! Is a recommended Group?
@property NSInteger childGroupCount;      //! cached number of children Group objects

@end
