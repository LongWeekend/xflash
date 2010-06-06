//
//  LWEDatabase.h
//  jFlash
//
//  Created by Mark Makdad on 3/7/10.
//  Copyright 2010 LONG WEEKEND INC.. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FMDatabase.h"
#import "FMDatabaseAdditions.h"
#import "LWEFile.h"

//! LWE Database singleton, maintains active connections
@interface LWEDatabase : NSObject
{
  BOOL databaseOpenFinished;
  NSMutableDictionary *attachedDatabases;
  FMDatabase *dao;
}

+ (LWEDatabase *)sharedLWEDatabase;
- (BOOL) databaseFileExists:(NSString*) pathToDatabase;
- (BOOL) openDatabase:(NSString*) pathToDatabase;
- (BOOL) attachDatabase:(NSString*) pathToDatabase withName:(NSString*) name;
- (BOOL) detachDatabase:(NSString*) name;
- (BOOL) doesTableExist:(NSString*) tableName;

// Semiprivate method
- (BOOL) _databaseIsOpen;

@property BOOL databaseOpenFinished;
@property (nonatomic, retain) FMDatabase *dao;
@property (nonatomic, retain) NSMutableDictionary *attachedDatabases;

@end
