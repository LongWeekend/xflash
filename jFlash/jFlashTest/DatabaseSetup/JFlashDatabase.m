//
//  JFlashDatabase.m
//  jFlash
//
//  Created by Rendy Pranata on 20/07/11.
//  Copyright 2011 Long Weekend LLC. All rights reserved.
//

#import "JFlashDatabase.h"

#import "SynthesizeSingleton.h"
#import "LWEFile.h"
#import "LWEDatabase.h"
#import "Constants.h"

NSString * const JFLASH_CURRENT_USER_TEST_DATABASE  = @"jFlash-test.db";
NSString * const JFLASH_CURRENT_CARD_TEST_DATABASE  = @"jFlash-CARD-1.1-test.db";
NSString * const kJFlashDatabaseErrorDomain         = @"kJFlashDatabaseErrorDomain";
NSUInteger const kJFlashCannotOpenDatabaseErrorCode   = 999;
NSUInteger const kJFlashCannotCopyDatabaseErrorCode   = 888;
NSUInteger const kJFlashCannotRemoveDatabaseErrorCode = 777;

@interface JFlashDatabase ()
@end

@implementation JFlashDatabase

SYNTHESIZE_SINGLETON_FOR_CLASS(JFlashDatabase);

- (BOOL)setupTestDatabaseAndOpenConnectionWithError:(NSError **)error
{
  //copy it to the user documents folder
  BOOL result = [LWEFile copyFromBundleWithFilename:LWE_CURRENT_USER_DATABASE toDocumentsWithFilename:JFLASH_CURRENT_USER_TEST_DATABASE shouldOverwrite:YES];
  if (!result)
  {
    //Cannot copy database
    NSString *msg = [[NSString alloc] initWithFormat:@"Cannot copy database file from the main bundle to the test dictionary."];
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:msg, NSLocalizedDescriptionKey, nil];
    NSError *theError = [NSError errorWithDomain:kJFlashDatabaseErrorDomain code:kJFlashCannotCopyDatabaseErrorCode userInfo:dict];
    *error = theError;
    
    [msg release];
    return NO;
  }

  //Construct the test database filename
  NSString *filename = [NSString stringWithFormat:@"%@", JFLASH_CURRENT_USER_TEST_DATABASE];
  NSString *pathToDatabase = [LWEFile createDocumentPathWithFilename:filename];
  LWEDatabase *db = [LWEDatabase sharedLWEDatabase];

  //Create the connection for opening the database
  if ([db openDatabase:pathToDatabase])
  {
    [[[CurrentState sharedCurrentState] pluginMgr] loadInstalledPlugins];
    return YES;
  }
  else
  {
    // Could not open database!
    NSString *msg = [[NSString alloc] initWithFormat:@"DatabaseFileNotFound.\nLooked for file: %@", pathToDatabase];
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:msg, NSLocalizedDescriptionKey, nil];
    
    NSError *theError = [NSError errorWithDomain:kJFlashDatabaseErrorDomain code:kJFlashCannotOpenDatabaseErrorCode userInfo:dict];
    *error = theError;
    
    [msg release];
    return NO;
  }
}

- (BOOL)removeTestDatabaseWithError:(NSError **)error
{
  LWEDatabase *db = [LWEDatabase sharedLWEDatabase];
  BOOL result = [db closeDatabase];
  if (result)
  {
    NSString *testDatabasePath = [LWEFile createDocumentPathWithFilename:JFLASH_CURRENT_USER_TEST_DATABASE];
    result = [LWEFile deleteFile:testDatabasePath];
    if (result)
      return YES;
    else
    {
      NSString *msg = [NSString stringWithFormat:@"Test database cannot be removed from the user documents folder."];
      NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:msg, NSLocalizedDescriptionKey, nil];
      *error = [NSError errorWithDomain:kJFlashDatabaseErrorDomain code:kJFlashCannotRemoveDatabaseErrorCode userInfo:dict];
      return NO;
    }
  }
  else
  {
    NSString *msg = [NSString stringWithFormat:@"Test database cannot be closed for some reason."];
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:msg, NSLocalizedDescriptionKey, nil];
    *error = [NSError errorWithDomain:kJFlashDatabaseErrorDomain code:kJFlashCannotRemoveDatabaseErrorCode userInfo:dict];
    return NO;
  }
}

@end