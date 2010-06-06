//  jFlashAppDelegate.m
//  jFlash
//
//  Created by シャロット ロス on 5/4/09.
//  Copyright LONG WEEKEND INC 2009. All rights reserved.

#import "jFlashAppDelegate.h"
#import "RootViewController.h"
#import "FlurryAPI.h"

@implementation jFlashAppDelegate

@synthesize window, rootViewController;

- (void)applicationDidFinishLaunching:(UIApplication *)application
{   
  
#if defined(APP_STORE_FINAL)
  // add analytics if this is live
  NSSetUncaughtExceptionHandler(&uncaughtExceptionHandler);
  [FlurryAPI startSession:@"1ZHZ39TNG7GC3VT5PSW4"];
#endif
  
  // Seed random generator
  srandomdev();
  
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

  // Load root controller to handle initialization process
  self.rootViewController = [[RootViewController alloc] init];
	[window addSubview:rootViewController.view];
  [window makeKeyAndVisible];
  
  [pool release];
}

//! Flurry exception handler (only installed in final app store version)
void uncaughtExceptionHandler(NSException *exception) {
  [FlurryAPI logError:@"Uncaught" message:@"Crash!" exception:exception];
}

/**
 * Delegate method from UIApplication - re-delegated to RootViewController
 */ 
- (void) applicationWillTerminate:(UIApplication *)application
{
  [rootViewController applicationWillTerminate:application];
}

- (void)dealloc
{
	[rootViewController release];
	[window release];
	[super dealloc];
}

@end