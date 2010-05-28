//
//  LWEDatabase.h
//  jFlash
//
//  Created by Mark Makdad on 3/7/10.
//  Copyright 2010 LONG WEEKEND INC.. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LWEFile.h"

@interface LWEDatabase : NSObject
{
  BOOL databaseOpenFinished;
  FMDatabase *dao;
}

@property BOOL databaseOpenFinished;
@property (nonatomic, retain) FMDatabase *dao;

+ (LWEDatabase *)sharedLWEDatabase;
- (BOOL) openedDatabase:(NSString*) pathToDatabase;
- (BOOL) databaseFileExists:(NSString*) pathToDatabase;
- (BOOL) doesTableExist:(NSString *) tableName;

@end
