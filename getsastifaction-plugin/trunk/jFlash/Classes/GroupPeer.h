//
//  GroupPeer.h
//  jFlash
//
//  Created by Mark Makdad on 10/10/09.
//  Copyright 2009 LONG WEEKEND INC.. All rights reserved.
//


#import "Group.h"


@interface GroupPeer : NSObject {
}

+ (Group*) retrieveGroupById: (NSInteger)groupId;
+ (NSMutableArray*) retrieveGroupsByOwner: (NSInteger)ownerId;

@end
