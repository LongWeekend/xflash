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

@interface JFlashDatabase : NSObject
{
    
}

+ (JFlashDatabase *)sharedJFlashDatabase;

- (BOOL)setupTestDatabaseAndOpenConnectionWithError:(NSError **)error;
- (BOOL)removeTestDatabase;

@end