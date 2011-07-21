//
//  CardTagTest.m
//  jFlash
//
//  Created by Rendy Pranata on 19/07/11.
//  Copyright 2011 Long Weekend LLC. All rights reserved.
//

#import "CardTagTest.h"
#import "AppDelegate.h"

#import "TagPeer.h"
#import "JFlashDatabase.h"

static NSString * const kTagTestDefaultName = @"TestTag";

@implementation CardTagTest

#if USE_APPLICATION_UNIT_TEST     // all code under test is in the iPhone Application

- (void)testAppDelegate 
{
  jFlashAppDelegate *myApplicationDelegate = [AppDelegate delegate];
  STAssertNotNil(myApplicationDelegate, @"UIApplication failed to find the AppDelegate");
}

#endif

#pragma mark -
#pragma mark Setting up

- (void)setUp
{
  NSError *error = nil;
  JFlashDatabase *db = [JFlashDatabase sharedJFlashDatabase];
  BOOL result = [db setupTestDatabaseAndOpenConnectionWithError:&error];
  STAssertTrue(result, @"Failed in setup the test database with error: %@", [error localizedDescription]);
  
  NSUInteger createdTagId = [TagPeer createTag:kTagTestDefaultName withOwner:0];
  STAssertTrue(createdTagId != 0, @"Failed in creating new tag (Study Set) for some reason.\nCreated TagId: %d", createdTagId);
}

- (void)tearDown
{
  JFlashDatabase *db = [JFlashDatabase sharedJFlashDatabase];
  NSError *error = nil;
  BOOL result = [db removeTestDatabaseWithError:&error];
  STAssertTrue(result, @"Test database cannot be removed for some reason.\nError: %@", [error localizedDescription]);
}

@end