//  jFlashAppDelegate.m
//  jFlash
//
//  Created by シャロット ロス on 5/4/09.
//  Copyright LONG WEEKEND INC 2009. All rights reserved.

#import "jFlashAppDelegate.h"
#import "RootViewController.h"

@implementation jFlashAppDelegate

@synthesize window, rootViewController;

- (void)applicationDidFinishLaunching:(UIApplication *)application
{  
  // Seed random generator
  srandomdev();
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

  // Load root controller to handle initialization process
  self.rootViewController = [[RootViewController alloc] init];
	[window addSubview:rootViewController.view];
  [window makeKeyAndVisible];
  
  [pool release];
}

// Pass termination to rootViewController
- (void) applicationWillTerminate:(UIApplication *)application
{
  [rootViewController applicationWillTerminate];
}

- (void)dealloc
{
	[rootViewController release];
	[window release];
	[super dealloc];
}

@end