//  jFlashAppDelegate.m
//  jFlash
//
//  Created by シャロット ロス on 5/4/09.
//  Copyright LONG WEEKEND INC 2009. All rights reserved.

#import "jFlashAppDelegate.h"
#import "RootViewController.h"

@implementation jFlashAppDelegate

@synthesize window, rootViewController, launchTimeURL;

- (void)applicationDidFinishLaunching:(UIApplication *)application
{  
/*
  // Use this loop to debug when app is launched from a URL
  // App starts from URL click > Attach Xcode debugger to app's process ID > Change value of 'more' to NO > Continue to Debug
  // DANGER! This is an inifinite loop for break-in debugging
    BOOL more = YES;
    while (more) {
      [NSThread sleepForTimeInterval:1.0]; // Set break point on this line
    }
*/
  // Seed random generator
  srandomdev();
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

  // Load root controller to handle initialization process
  self.rootViewController = [[RootViewController alloc] init];
	[window addSubview:rootViewController.view];
  [window makeKeyAndVisible];

  [pool release];
}

// Save URL app is launched from
// This is called AFTER all the rootViewCon handlers!
- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
  [self setLaunchTimeURL:url];
	return YES;
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
  [launchTimeURL release];
	[super dealloc];
}

@end