//
//  User.h
//  jFlash
//
//  Created by Paul Chapman on 28/01/10.
//  Copyright 2010 LONG WEEKEND INC.. All rights reserved.
//

#import "FMResultSet.h"

extern NSInteger const kLWEUninitializedUserId;

@interface User : NSObject

//! Returns the default user.
+ (User *)defaultUser;

- (void)hydrate: (FMResultSet*) rs;

//! Updates an existing user or inserts a new user.
- (void)save;

//! Deletes this user from the database, returning YES or NO, if NO, check "error".
- (BOOL)deleteUser:(NSError **)error;

//! Returns a unique key that can be used to archive this user's history
- (NSString *) historyArchiveKey;

//! Returns an array of all UserHistory objects associated with this User
- (NSArray *) studyHistories;

@property (nonatomic) NSInteger userId;
@property (nonatomic,retain) NSString *userNickname;

@end
