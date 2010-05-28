//
//  LWEDatabase.m
//  jFlash
//
//  Created by Mark Makdad on 3/7/10.
//  Copyright 2010 LONG WEEKEND INC.. All rights reserved.
//

#import "LWEDatabase.h"
#import "SynthesizeSingleton.h"

@implementation LWEDatabase

@synthesize dao,databaseOpenFinished;

SYNTHESIZE_SINGLETON_FOR_CLASS(LWEDatabase);

/** 
 * Returns true if the database file specified by 'pathToDatabase' exists
 */
- (BOOL) databaseFileExists:(NSString*)pathToDatabase
{
  NSFileManager *fileManager = [NSFileManager defaultManager];
  if([fileManager fileExistsAtPath:pathToDatabase])
  {
    LWE_LOG(@"Database file found at specified location: %@",pathToDatabase);
    return YES;
  }
  else
  {
    LWE_LOG(@"No database file located at specified location: %@",pathToDatabase);
    return NO;
  }
}


/** 
 * Returns true if the database file specified by 'pathToDatabase' was successfully opened
 * Also posts a 'databaseIsOpen' notification on success
 */
- (BOOL) openedDatabase:(NSString*)pathToDatabase
{
  self.databaseOpenFinished = NO;
  BOOL success = NO;
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  self.dao = [FMDatabase databaseWithPath:pathToDatabase];
  self.dao.logsErrors = YES;
#if (PROFILE_SQL_STATEMENTS)
  self.dao.traceExecution = YES;
#endif
  if ([self.dao open])
  {
    success = YES;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"databaseIsOpen" object:self];
  }
  else
  {
    LWE_LOG(@"FAIL - Could not open DB - error code: %d",[[self dao] lastErrorCode]);
  }
  [pool release];
  // So other threads can query whether we are done or not
  self.databaseOpenFinished = YES;
  return success;
}


/**
 * Attaches another database onto the existing open connection
 */
- (BOOL) attachDatabase:(NSString*) pathToDatabase withName:(NSString*) name
{
  BOOL returnVal = NO;
  if ([self _databaseIsOpen])
  {
    NSString *sql = [[NSString alloc] initWithFormat:@"ATTACH DATABASE '%@' AS '%@'",pathToDatabase,name];
    FMResultSet *rs = [[self dao] executeQuery:sql];
    if (![[self dao] hadError])
    {
      returnVal = YES;
    }
    [rs close];
  }
  else
  {
    // When called with no DB, throw exception
    [NSException raise:@"Invalid database object in 'dao'" format:@"dao object is: %@",[self dao]];
  }
  return returnVal;
}


/**
 * Checks for the existence of a table name in the sqlite_master table
 * If database is not open, throws an exception
 */
- (BOOL) doesTableExist:(NSString *) tableName
{
  BOOL returnVal = NO;
  if ([self _databaseIsOpen])
  {
    NSString *sql = [[NSString alloc] initWithFormat:@"SELECT name FROM sqlite_master WHERE name=%@", tableName];
    FMResultSet *rs = [[self dao] executeQuery:sql];
    if ([rs next]) returnVal = YES;
    [rs close];
    [sql release];
  }
  else
  {
    // When called with no DB, throw exception
    [NSException raise:@"Invalid database object in 'dao'" format:@"dao object is: %@",[self dao]];
  }
  return returnVal;
}


/**
 * Helper method to determine if database is open
 * This method is private and other method calls in this class rely on it
 */
- (BOOL) _databaseIsOpen
{
  if ([[self dao] isKindOfClass:[FMDatabase class]])
    return YES;
  else
    return NO;
}

@end
