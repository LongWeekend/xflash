//
//  GroupPeer.h
//  jFlash
//
//  Created by Mark Makdad on 10/10/09.
//  Copyright 2009 LONG WEEKEND INC.. All rights reserved.
//


#import "Group.h"
#import "Tag.h"
#import "FMResultSet.h"

@interface GroupPeer : NSObject 

+ (Group*) retrieveGroupById:(NSInteger)groupId;
+ (NSInteger) parentGroupIdOfTag:(Tag*)tag;
+ (NSArray*) retrieveGroupsByOwner:(NSInteger)ownerId;

@end
