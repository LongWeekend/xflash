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

- (BOOL) databaseFileExists
{
  NSFileManager *fileManager = [NSFileManager defaultManager];
  NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
  NSString *documentsDirectory = [paths objectAtIndex:0];
  NSString *path = [documentsDirectory stringByAppendingPathComponent:@"jFlash.db"];	
  if(![fileManager fileExistsAtPath:path])
  {
    // This means it is a fresh install
    LWE_LOG(@"No database located at normal location, must be fresh install.");
    return NO;
  }
  return YES;
}

- (BOOL) openedDatabase
{
  self.databaseOpenFinished = NO;
  BOOL success = NO;
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
  NSString *documentsDirectory = [paths objectAtIndex:0];
  NSString *path = [documentsDirectory stringByAppendingPathComponent:@"jFlash.db"];	
  self.dao = [FMDatabase databaseWithPath:path];
  self.dao.logsErrors = YES;
  self.dao.traceExecution = YES;
  if ([self.dao open])
  {
    success = YES;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"databaseIsOpen" object:self];
  }
  else
  {
    LWE_LOG(@"FAIL - Could not open DB.");
  }
  [pool release];
  // So other threads can query whether we are done or not
  self.databaseOpenFinished = YES;
  return success;
}



@end
