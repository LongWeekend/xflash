//  jFlashAppDelegate.m
//  jFlash
//
//  Created by シャロット ロス on 5/4/09.
//  Copyright LONG WEEKEND INC 2009. All rights reserved.

#import "jFlashAppDelegate.h"
#import "RootViewController.h"
#import "FlurryAPI.h"
#import "CurrentState.h"
#import "LWEFile.h"
#import "LWEDatabase.h"
#import "ThemeManager.h"

@implementation jFlashAppDelegate

@synthesize window, rootViewController;

/** App delegate method, point of entry for the app */
- (void)applicationDidFinishLaunching:(UIApplication *)application
{   
  
#if defined(APP_STORE_FINAL)
  // add analytics if this is live
  NSSetUncaughtExceptionHandler(&uncaughtExceptionHandler);
  [FlurryAPI startSession:@"1ZHZ39TNG7GC3VT5PSW4"];
#endif
  
  // Seed random generator
  srandomdev();
  
  // This call initializes app settings in NSUserDefaults if not already done.  Important!
  CurrentState *state = [CurrentState sharedCurrentState];
  [state initializeSettings];

  // Load root controller to handle initialization process
  self.rootViewController = [[RootViewController alloc] init];
	[window addSubview:rootViewController.view];
  [window makeKeyAndVisible];
  
  // Add a delay here so that the UI has time to update
  [self performSelector:@selector(_prepareDatabase) withObject:nil afterDelay:0.0f];
}

//! Flurry exception handler (only installed in final app store version)
void uncaughtExceptionHandler(NSException *exception) {
  [FlurryAPI logError:@"Uncaught" message:@"Crash!" exception:exception];
}


/**
 * Checks whether or not to install the main database from the bundle
 */
- (void) _prepareDatabase
{
  // Determine if the MAIN database exists or not
  NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
  NSString* pathToDatabase = [LWEFile createDocumentPathWithFilename:@"jFlash.db"];
  if (![LWEFile fileExists:pathToDatabase] || ![settings boolForKey:@"db_did_finish_copying"])
  {
    // Register a notification to wait here for the success, then do the DB copy
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_openDatabaseWithPlugins) name:@"DatabaseCopyFinished" object:nil];
    LWEDatabase *db = [LWEDatabase sharedLWEDatabase];
    [db performSelectorInBackground:@selector(copyDatabaseFromBundle:) withObject:@"jFlash.db"];
  }
  else
  {
    // Finished copying, and we have the database file - just open it
    [self _openDatabaseWithPlugins];
  }
}


/**
 * Loads & opens the databases and plugins, calls
 * RootViewController loadTabBar when finished
 */
- (void) _openDatabaseWithPlugins
{
  // Remove observer if we had one for first copy, also get rid of the loading page if we had one
  [[NSNotificationCenter defaultCenter] removeObserver:self name:@"DatabaseCopyFinished" object:nil];
  
  // Open the database - it already exists & is properly copied
  LWEDatabase *db = [LWEDatabase sharedLWEDatabase];
  if ([db openDatabase:[LWEFile createDocumentPathWithFilename:@"jFlash.db"]])
  {
    // Then load plugins
    [[[CurrentState sharedCurrentState] pluginMgr] loadInstalledPlugins];
  }
  else
  {
    // Could not open database!
  }
  [self.rootViewController loadTabBar];
}


/**
 * Delegate method from UIApplication - re-delegated to RootViewController
 */ 
- (void) applicationWillTerminate:(UIApplication *)application
{
  [rootViewController applicationWillTerminate:application];
}

//! Standard dealloc
- (void)dealloc
{
	[rootViewController release];
	[window release];
	[super dealloc];
  
  // Handle all singletons
  CurrentState* state = [CurrentState sharedCurrentState];
  LWEDatabase *db = [LWEDatabase sharedLWEDatabase];
  ThemeManager *tm = [ThemeManager sharedThemeManager];
  [db release];
  [state release];
  [tm release];
}

@end