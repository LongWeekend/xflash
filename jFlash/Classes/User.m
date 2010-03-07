//
//  User.m
//  jFlash
//
//  Created by Paul Chapman on 28/01/10.
//  Copyright 2010 LONG WEEKEND INC.. All rights reserved.
//

#import "User.h"

// Pseudo Private Functions (not in .h file)
@interface User ()
  - (UIImage *)makeUserThumbnail:(UIImage *)image atRatio:(CGFloat)imgRatio;
@end


@implementation User
@synthesize userId, userNickname, avatarImagePath, dateCreated;

+ (NSMutableArray*) getUsers
{
  int i = 0;
  LWEDatabase *db = [LWEDatabase sharedLWEDatabase];
  while ([db dao].inUse && i < 5)
  {
    NSLog(@"Database is busy %d",i);
    usleep(100);
    i++;
  }

  NSString *sql = [[NSString alloc] initWithFormat:@"SELECT * FROM users ORDER BY upper(nickname) ASC"];

  FMResultSet *rs = [[db dao] executeQuery:sql];
  NSMutableArray* userList = [[[NSMutableArray alloc] init] autorelease];
	while ([rs next]) {
		User* tmpUser = [[[User alloc] init] autorelease];
		[tmpUser hydrate:rs];
    NSLog(@"User loaded: %@", [tmpUser userNickname]);
		[userList addObject: tmpUser];
  }
	
  [rs close];
	[sql release];
  return userList;
}

+ (User*)createUserWithNickname:(NSString*)name avatarImagePath:(NSString*)path{

  User* tmpUser = [[[User alloc] init] autorelease];
  tmpUser.userNickname = name;
  tmpUser.avatarImagePath = path;

  LWEDatabase *db = [LWEDatabase sharedLWEDatabase];
  NSString *sql = [[NSString alloc] initWithFormat:@"INSERT INTO users (nickname, avatar_image_path, date_created) VALUES ('%@','%@',NOW())", name, path];
  [[db dao] executeUpdate:sql];
  [sql release];
  return tmpUser;  
}

+ (User*) getUser: (NSInteger)userId
{
  int i = 0;
  LWEDatabase *db = [LWEDatabase sharedLWEDatabase];
  while ([db dao].inUse && i < 5)
  {
    NSLog(@"Database is busy %d",i);
    usleep(100);
    i++;
  }

  NSString *sql = [NSString stringWithFormat:@"SELECT * FROM users WHERE user_id = %d", userId];
  FMResultSet *rs = [[db dao] executeQuery:sql];
  User* tmpUser = [[[User alloc] init] autorelease];
  while ([rs next])
  {
    [tmpUser hydrate:rs];
  }
	
  [rs close];
  return tmpUser;
}

// Takes a sqlite result set and populates the properties of user
- (void) hydrate: (FMResultSet*) rs
{
  self.userId          = [rs intForColumn:@"user_id"];
  self.userNickname    = [rs stringForColumn:@"nickname"];
  self.avatarImagePath = [rs stringForColumn:@"avatar_image_path"];
  if([self.avatarImagePath length] == 0) self.avatarImagePath = DEFAULT_USER_AVATAR_PATH;
  self.dateCreated     = [rs stringForColumn:@"date_created"];
}

- (void) save
{
  LWEDatabase *db = [LWEDatabase sharedLWEDatabase];
  NSString *sql;
  if(self.userId > 0){
    sql = [NSString stringWithFormat:@"UPDATE users SET nickname ='%@', avatar_image_path='%@' WHERE user_id = %d", userNickname, avatarImagePath, userId];
  } else {
    sql = [NSString stringWithFormat:@"INSERT INTO users (nickname, avatar_image_path) VALUES ('%@','%@')", userNickname, avatarImagePath];
  }
  [[db dao] executeUpdate:sql];
}

- (void) deleteUser
{
  // Delete the avatar image
  if(![[avatarImagePath substringToIndex:1] isEqualToString:@"/"]){
    NSString* filePath = [NSString stringWithFormat:@"%@/%@", DOCSFOLDER, [self avatarImagePath]];
    [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
  }
  
  LWEDatabase *db = [LWEDatabase sharedLWEDatabase];
  NSString *sql = [NSString stringWithFormat:@"DELETE FROM users WHERE user_id = %d", userId];
  [[db dao] executeUpdate:sql];
}

- (void) activateUser{
  // User activation code here 
  NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
  [settings setInteger:userId forKey:@"user_id"];
}

- (NSString *)saveAvatarImage:(UIImage*) userImage
{
  NSDateFormatter* dateFormat = [[NSDateFormatter alloc] init];
  [dateFormat setDateFormat: @"yyyyMMdd-HHmmss"];
  NSString* dateString = [dateFormat stringFromDate: [NSDate date]];

  // Store file relative to DOCSFOLDER in DB
  NSString* fileName = [NSString stringWithFormat:@"user-avatar-%@.png", dateString];

  NSString* absFilePath = [NSString stringWithFormat:@"%@/%@", DOCSFOLDER, fileName];
  [UIImagePNGRepresentation(userImage) writeToFile:absFilePath atomically:YES];

  //Delete old avatar file
  if(![[avatarImagePath substringToIndex:1] isEqualToString:@"/"]){
    NSString* oldFileName = [NSString stringWithFormat:@"%@/%@", DOCSFOLDER, [self avatarImagePath]];
    [[NSFileManager defaultManager] removeItemAtPath:oldFileName error:nil];
  }
  [self setAvatarImagePath:fileName];
  [dateFormat release];
  return absFilePath;
}

# pragma mark Thumbnail Functions

- (UIImage *) getImageFromPath{
  if([[avatarImagePath substringToIndex:1] isEqualToString:@"/"]){
    // Default avatar icon path relative to app bundle root
    return [UIImage imageNamed:avatarImagePath];
  }
  else 
  {
    // User saved icons are stored in DOCSFOLDER path
    NSString* absFilePath = [NSString stringWithFormat:@"%@/%@", DOCSFOLDER, avatarImagePath];
    return [UIImage imageWithContentsOfFile:absFilePath];
  }
}

- (UIImage *) getUserThumbnailLarge{
  UIImage *cellImage = [self getImageFromPath];
  return [self makeUserThumbnail:cellImage atRatio:(CGFloat)80.0];
}

- (UIImage *) getUserThumbnail{
  UIImage *cellImage = [self getImageFromPath];
  return [self makeUserThumbnail:cellImage atRatio:(CGFloat)30.0];
}

- (UIImage *) makeUserThumbnail:(UIImage *)image atRatio:(CGFloat)imgRatio{
  // Create a thumbnail version of the image for the event object.
  CGSize size = image.size;
  CGSize croppedSize;
  //CGFloat ratio = 30.0;
  CGFloat ratio = imgRatio;
  CGFloat offsetX = 0.0;
  CGFloat offsetY = 0.0;
  
  // check the size of the image, we want to make it
  // a square with sides the size of the smallest dimension
  if (size.width && size.height) {
    offsetX = (size.height - size.width) / 2;
    croppedSize = CGSizeMake(size.height, size.height);
  } else {
    offsetY = (size.width - size.height) / 2;
    croppedSize = CGSizeMake(size.width, size.width);
  }
  
  // Crop the image before resize
  CGRect clippedRect = CGRectMake(offsetX * -1, offsetY * -1, croppedSize.width, croppedSize.height);
  CGImageRef imageRef = CGImageCreateWithImageInRect([image CGImage], clippedRect);
  // Done cropping
  
  // Resize the image
  CGRect rect = CGRectMake(0.0, 0.0, ratio, ratio);
  
  UIGraphicsBeginImageContext(rect.size);
  [[UIImage imageWithCGImage:imageRef] drawInRect:rect];
  UIImage *thumbnail = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  // Done Resizing
  
  return thumbnail;
}


- (id) init
{
  self = [super init];
  if (self)
  {
    self.userId          = 0;
    self.userNickname    = nil;
    self.avatarImagePath = DEFAULT_USER_AVATAR_PATH;
    self.dateCreated     = nil;
  }
  return self;
}

- (void) dealloc
{
  [userNickname release];
  [avatarImagePath release];
  [dateCreated release];
	[super dealloc];
}

@end
