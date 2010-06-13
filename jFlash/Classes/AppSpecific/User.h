//
//  User.h
//  jFlash
//
//  Created by Paul Chapman on 28/01/10.
//  Copyright 2010 LONG WEEKEND INC.. All rights reserved.
//

#define DEFAULT_USER_AVATAR_PATH @"/avatars/default00.png"
#define DOCSFOLDER [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"]

#import "FMResultSet.h"

@interface User : NSObject
{
	NSInteger userId;
	NSString * userNickname;
	NSString * avatarImagePath;
  NSString * dateCreated;
}

- (void)hydrate: (FMResultSet*) rs;
- (void)save;
- (void)deleteUser;
- (void)activateUser;
- (NSString *)saveAvatarImage:(UIImage*) userImage;
- (UIImage *)getImageFromPath;
- (UIImage *)getUserThumbnail;
- (UIImage *)getUserThumbnailLarge;

@property (nonatomic) NSInteger userId;
@property (nonatomic,retain) NSString *userNickname;
@property (nonatomic,retain) NSString *avatarImagePath;
@property (nonatomic,retain) NSString *dateCreated;

@end
