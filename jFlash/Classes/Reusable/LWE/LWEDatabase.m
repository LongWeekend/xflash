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
 * Returns true if file was able to be copied from the bundle - overwrites
 * Intended to be run in the background
 */
- (BOOL) copyDatabaseFromBundle:(NSString*)filename
{
  BOOL returnVal;
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  if (![LWEFile copyFromMainBundleToDocuments:filename shouldOverwrite:YES])
  {
    LWE_LOG(@"Unable to copy database from bundle: %@",filename);
    returnVal = NO;
  }
  else
  {
    NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
    [settings setBool:YES forKey:@"db_did_finish_copying"];
    returnVal = YES;
    
    NSNotification *aNotification = [NSNotification notificationWithName:@"DatabaseCopyFinished" object:self];
    [self performSelectorOnMainThread:@selector(_postNotification:) withObject:aNotification waitUntilDone:NO];
  }
  [pool release];
  return returnVal;
}


/** 
 * Returns true if the database file specified by 'pathToDatabase' was successfully opened
 * Also posts a 'databaseIsOpen' notification on success
 */
- (BOOL) openDatabase:(NSString*)pathToDatabase
{
  BOOL success = NO;
  BOOL fileExists = [LWEFile fileExists:pathToDatabase];
  NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
  if (fileExists && [settings boolForKey:@"db_did_finish_copying"])
  {
    self.databaseOpenFinished = NO;
    self.dao = [FMDatabase databaseWithPath:pathToDatabase];
    self.dao.logsErrors = YES;
    self.dao.traceExecution = YES;
    if ([self.dao open])
    {
      success = YES;
      [[NSNotificationCenter defaultCenter] postNotificationName:@"databaseIsOpen" object:self];
    }
    else
    {
      LWE_LOG(@"FAIL - Could not open DB - error code: %d",[[self dao] lastErrorCode]);
    }

    // So other threads can query whether we are done or not
    self.databaseOpenFinished = YES;
  }
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
    NSString *sql = [[NSString alloc] initWithFormat:@"ATTACH DATABASE \"%@\" AS %@;",pathToDatabase,name];
    LWE_LOG(@"%@",sql);
    [[self dao] executeUpdate:sql];
    if (![[self dao] hadError])
    {
      returnVal = YES;
    }
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
 * detaches a database on the open connection with "name"
 */
- (BOOL) detachDatabase:(NSString*) name
{
  BOOL returnVal = NO;
  if ([self _databaseIsOpen])
  {
    NSString *sql = [[NSString alloc] initWithFormat:@"DETACH DATABASE \"%@\";",name];
    LWE_LOG(@"%@",sql);
    [[self dao] executeUpdate:sql];
    if (![[self dao] hadError])
    {
      returnVal = YES;
    }
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
 * Passthru for dao - executeQuery
 */
- (FMResultSet*) executeQuery:(NSString*)sql
{
  return [[self dao] executeQuery:sql];
}


/**
 * Passthru for dao - executeUpdate
 */
- (BOOL) executeUpdate:(NSString*)sql
{
  return [[self dao] executeUpdate:sql];
}


/**
 * Checks for the existence of a table name in the sqlite_master table
 * If database is not open, throws an exception
 */
- (BOOL) tableExists:(NSString *) tableName
{
  BOOL returnVal = NO;
  if ([self _databaseIsOpen])
  {
    NSString *sql = [[NSString alloc] initWithFormat:@"SELECT name FROM sqlite_master WHERE type='table' AND name='%@'", tableName];
    FMResultSet *rs = [self executeQuery:sql];
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


//! Helper method for threading - posts a notification
- (void) _postNotification:(NSNotification *)aNotification
{
  [[NSNotificationCenter defaultCenter] postNotification:aNotification];
}

@end
