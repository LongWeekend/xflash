//
//  DownloaderViewControllerTest.m
//  jFlash
//
//  Created by Mark Makdad on 5/26/10.
//  Copyright 2010 Long Weekend Inc. All rights reserved.
//

#import "DownloaderViewControllerTest.h"
#import "DownloaderViewController.h"

@implementation DownloaderViewControllerTest

@synthesize vc;

/**
 * Sets up test object
 */
- (void) setUp
{
  self.vc = [[DownloaderViewController alloc] initWithNibName:@"DownloaderView" bundle:nil];
  STAssertNotNil(vc, @"Could not create test subject.");
}


/**
 * Destroys test object
 */
- (void) tearDown
{
  self.vc = nil;
}


/**
 * Tests that the controller properly inits variables on viewDidLoad
 */
- (void) testDownloaderViewControllerLoad
{
  [self setUp];
/*  STAssertEqualObjects([[self vc] statusMessage],    @"", @"statusMsgLabel was not initialized to '' blank");
  STAssertEqualObjects([vc taskMessage],      @"", @"taskMsgLabel was not initialized to '' blank");
  STAssertEquals([vc progress],         0.0f, @"progressIndicator was not initialized to 0% done");
 */
  [self tearDown];
}


/**
 * Tests that the controller updates the status text view when asked to do so
 */
- (void) testDownloaderViewControllerUpdateStatus
{
  [self setUp];
  
  // Test normal text on status message
  [vc setStatusMessage:@"foobar"];
  //STAssertEqualObjects([vc statusMessage], @"foobar", @"statusMsgLabel was not updated when set by setter");
  
  // Test blanking input
  [vc setStatusMessage:@""];
  //STAssertEqualObjects([vc statusMessage], @"", @"statusMsgLabel was not updated when set by setter (blanked)");
  
  // Test nil case
  [vc setStatusMessage:nil];
  //STAssertEqualObjects([vc statusMessage], @"", @"statusMsgLabel was not set to blank when passed nil");
  
  // Test abnormal case - garbage input (e.g. dealloc'ed something gets passed in)
  UIViewController *tmpVc = [[UIViewController alloc] init];
  STAssertThrows([vc setStatusMessage:tmpVc], @"setStatusMessage should throw exception on garbage input");
  
  [self tearDown];
}


/**
 * Tests that the controller updates the label text view when asked to do so
 */
- (void) testDownloaderViewControllerUpdateTask
{
  [self setUp];
  
  // Test normal text on task message
  [vc setTaskMessage:@"foobar"];
//  STAssertEqualObjects([vc taskMessage], @"foobar", @"taskMsgLabel was not updated when set by setter");
  
  // Test blanking input
  [vc setTaskMessage:@""];
//  STAssertEqualObjects([vc taskMessage], @"", @"taskMsgLabel was not updated when set by setter (blanked)");
  
  // Test nil case
  [vc setTaskMessage:nil];
//  STAssertEqualObjects([vc taskMessage], @"", @"taskMsgLabel was not set to blank when passed nil");
  
  // Test abnormal case - garbage input (e.g. dealloc'ed something gets passed in)
  UIViewController *tmpVc = [[UIViewController alloc] init];
  STAssertThrows([vc setTaskMessage:tmpVc], @"setTaskMessage should throw exception on garbage input");
  
  [self tearDown];
}


/**
 * Tests that the controller updates the download progress meter when asked to do so
 */
- (void) testDownloaderViewControllerUpdateProgressView
{
  [self setUp];
  
  // Test zero case
  [vc setProgress:0.0f];
  STAssertEquals([vc progress], 0.0f, @"progressIndicator was not updated when set by setter");
  
  // Test normal case
  [vc setProgress:0.35f];
//  STAssertEquals([vc progress], 0.35f, @"progressIndicator was not updated when set by setter");

  // Test abnormal case 1
  [vc setProgress:1.35f];
//  STAssertEquals([vc progress], 1.00f, @"progressIndicator was not updated when set by setter - abnormal input");

  // Test abnormal case 2
  [vc setProgress:-1.35f];
  STAssertEquals([vc progress], 0.0f, @"progressIndicator was not updated when set by setter - abnormal input");
  
  [self tearDown];
}


@end
