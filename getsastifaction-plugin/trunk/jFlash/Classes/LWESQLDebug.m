//
//  LWESQLDebug.m
//  jFlash
//
//  Created by Ross Sharrott on 2/20/10.
//  Copyright 2010 LONG WEEKEND LLC. All rights reserved.
//

#import "LWESQLDebug.h"

@implementation LWESQLDebug

+ (void) profileSQLStatements: (NSArray*) statements
{
  for(int i = 0; i < [statements count]; i++)
  {
     [self runSQL:[statements objectAtIndex:i]];
  }
}

+ (void) runSQL: (NSString*) sql
{
  ApplicationSettings *appSettings = [ApplicationSettings sharedApplicationSettings];
  LWE_LOG(@"************************** BEGIN executeQuery ****************************");
  FMResultSet *rs = [[appSettings dao] executeQuery:sql];
  LWE_LOG(@"************************** FINISH executeQuery ***************************");
  while ([rs next])
   {
     //just iterate the rs like we would
   }
  LWE_LOG(@"************************** FINISH rs iteration ***************************");
  [rs close];
  
  LWE_LOG(@"************************** BEGIN executeQuery WITH TRANSACTIONS ****************************");
  [[appSettings dao] executeUpdate:@"BEGIN TRANSACTION;"];
  rs = [[appSettings dao] executeQuery:sql];
  LWE_LOG(@"************************** FINISH executeQuery ***************************");
  while ([rs next])
   {
     //just iterate the rs like we would
   }
  [[appSettings dao] executeUpdate:@"END TRANSACTION;"];
  LWE_LOG(@"************************** FINISH rs iteration WITH TRANSACTIONS ***************************");  
  [rs close];
  return;
}

@end
