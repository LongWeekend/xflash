//
//  User.h
//  jFlash
//
//  Created by Paul Chapman on 28/01/10.
//  Copyright 2010 LONG WEEKEND INC.. All rights reserved.
//

#define DEFAULT_USER_AVATAR_PATH @"/avatars/default00.png"

#import "FMResultSet.h"

@interface User : NSObject

- (void)hydrate: (FMResultSet*) rs;
- (void)save;
- (void)deleteUser;

@property (nonatomic) NSInteger userId;
@property (nonatomic,retain) NSString *userNickname;
@property (nonatomic,retain) NSString *avatarImagePath;
@property (nonatomic,retain) NSString *dateCreated;

@end
