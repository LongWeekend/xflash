//
//  UserPeer.h
//  jFlash
//
//  Created by Mark Makdad on 6/13/10.
//  Copyright 2010 Long Weekend Inc. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface UserPeer : NSObject
{

}

+ (User*)createUserWithNickname:(NSString*)name avatarImagePath:(NSString*)path;
+ (User*)getUserByPK: (NSInteger)userId;
+ (NSMutableArray*)getUsers;

@end
