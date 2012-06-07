//
//  UpdateManager.m
//  jFlash
//
//  Created by Mark Makdad on 10/13/10.
//  Copyright 2010 Long Weekend Inc. All rights reserved.
//

#import "UpdateManager.h"

@implementation UpdateManager

#pragma mark - Shared Private Methods

+ (BOOL) _runMultipleSQLStatements:(NSString*)filePath inDB:(LWEDatabase*)db
{
  // Init variables
  BOOL success = YES;
  FILE *fh = NULL;
  char str_buf[1024];
  
  // Get SQL statement file ready
  fh = fopen([filePath UTF8String],"r");
  if (fh == NULL)
  {
    [NSException raise:@"SQLStatementFileNotOpened" format:@"Unable to open/read SQL statement file"];
  }
  
  [db.dao beginDeferredTransaction];
  
  LWE_LOG(@"Starting SQL statement loop");
  while (!feof(fh))
  {
    fgets(str_buf,1024,fh); // get me a line of the file    
    if (![db.dao executeUpdate:[NSString stringWithCString:str_buf encoding:NSUTF8StringEncoding]])
    {
      success = NO;
      LWE_LOG(@"Unable to do SQL: %@",[NSString stringWithCString:str_buf encoding:NSUTF8StringEncoding]);
      break;
    }
  }
  if (success)
  {
    success = success && [db.dao commit];
  }
  else
  {
    [db.dao rollback];
  }
  
  // Close the file
  fclose(fh);
  
  return success;
}

//! a simple runner of SQL statements in a file and set the new version name
+ (void) _upgradeDBtoVersion:(NSString*)newVersionName withSQLStatements:(NSString*)pathToSQL forSettings:(NSUserDefaults *)settings  
{
  // Open the database!
  LWEDatabase *db = [LWEDatabase sharedLWEDatabase];
  NSString *filename = LWE_CURRENT_USER_DATABASE;
  if ([db openDatabase:[LWEFile createDocumentPathWithFilename:filename]])
  {
    // Cool, we are open - run the SQL
    if ([UpdateManager _runMultipleSQLStatements:[LWEFile createBundlePathWithFilename:pathToSQL] inDB:db])
    {
      // Now change the app version
      [settings setValue:newVersionName forKey:APP_DATA_VERSION];
    }
    else
    {
      // TODO: do something better here?
      LWE_LOG(@"Failed to update database in UpdateManager");
    }
    
    // In any case close the DB so that jFlash can open it
    [db closeDatabase];
  }
}

#pragma mark - Public Methods

+ (BOOL) performMigrations:(NSUserDefaults*)settings
{
  return NO;
}

+ (void) showUpgradeAlertView:(NSUserDefaults *)settings delegate:(id<UIAlertViewDelegate>)alertDelegate
{
}

@end
