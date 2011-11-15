//
//  JFlashDatabase.h
//  jFlash
//
//  Created by Rendy Pranata on 20/07/11.
//  Copyright 2011 Long Weekend LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const kJFlashDatabaseErrorDomain;
extern NSUInteger const kJFlashCannotOpenDatabaseErrorCode;
extern NSString * const CURRENT_USER_TEST_DATABASE;
extern NSString * const CURRENT_CARD_TEST_DATABASE;
extern NSString * const CURRENT_FTS_TEST_DATABASE;

@interface JFlashDatabase : NSObject

+ (JFlashDatabase *)sharedJFlashDatabase;

- (BOOL)setupTestDatabaseAndOpenConnectionWithError:(NSError **)error;
- (BOOL)removeTestDatabaseWithError:(NSError **)error;
- (BOOL)setupAttachedDatabase:(NSString*)filename asName:(NSString*)name;

@end