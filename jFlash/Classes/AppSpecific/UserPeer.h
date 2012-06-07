//
//  UserPeer.h
//  jFlash
//
//  Created by Mark Makdad on 6/13/10.
//  Copyright 2010 Long Weekend Inc. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface UserPeer : NSObject

//! Returns a User object based on its ID
+ (User *)userWithUserId:(NSInteger)userId;

//! Returns all the users objects in the local database
+ (NSArray *)allUsers;

@end
