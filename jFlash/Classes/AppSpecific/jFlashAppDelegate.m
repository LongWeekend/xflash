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
#import "VersionManager.h"

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
  
  // This call initializes app settings in NSUserDefaults if not already done.  Important!  Do this FIRST!
  // Seriously.  If you don't call this before ANY jFlash user code, you run this risk of making jFlash's 
  // upgrade path ABSOLUTELY unstable.  Capiche?
  CurrentState *state = [CurrentState sharedCurrentState];
  [state initializeSettings];

  // Load root controller to show splash screen
  [self setRootViewController:[[RootViewController alloc] init]];
	[window addSubview:rootViewController.view];
  [window makeKeyAndVisible];
  
  // Add a delay here so that the UI has time to update
  [self performSelector:@selector(_prepareUserDatabase) withObject:nil afterDelay:0.0f];
}


//! Flurry exception handler (only installed in final app store version)
void uncaughtExceptionHandler(NSException *exception) {
  [FlurryAPI logError:@"Uncaught" message:@"Crash!" exception:exception];
}


/**
 * Checks whether or not to install the main database from the bundle
 */
- (void) _prepareUserDatabase
{
  // Determine if the MAIN database exists or not
  NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
  NSString *filename = JFLASH_CURRENT_USER_DATABASE;
  NSString *pathToDatabase = [LWEFile createDocumentPathWithFilename:filename];
  if (![LWEFile fileExists:pathToDatabase] || ![settings boolForKey:@"db_did_finish_copying"])
  {
    // Register a notification to wait here for the success, then do the DB copy
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_openUserDatabaseWithPlugins) name:@"DatabaseCopyFinished" object:nil];
    LWEDatabase *db = [LWEDatabase sharedLWEDatabase];
    [[self rootViewController] showDatabaseLoadingView];
    // Only ever copy the latest user database
    [db performSelectorInBackground:@selector(copyDatabaseFromBundle:) withObject:JFLASH_CURRENT_USER_DATABASE];
  }
  else
  {
    // Finished copying, and we have the database file - just open it
    [self _openUserDatabaseWithPlugins];
  }
}


/**
 * Loads & opens the databases and plugins, calls
 * RootViewController loadTabBar when finished
 */
- (void) _openUserDatabaseWithPlugins
{
  // Remove observer if we had one for first copy, also get rid of the loading page if we had one
  [[NSNotificationCenter defaultCenter] removeObserver:self name:@"DatabaseCopyFinished" object:nil];
  
  // Open the database - it already exists & is properly copied
  LWEDatabase *db = [LWEDatabase sharedLWEDatabase];
  NSString *filename = JFLASH_CURRENT_USER_DATABASE;
  if ([db openDatabase:[LWEFile createDocumentPathWithFilename:filename]])
  {
    // Then load plugins
    [[[CurrentState sharedCurrentState] pluginMgr] loadInstalledPlugins];
  }
  else
  {
    // Could not open database!
    [NSException raise:@"DatabaseFileNotFound" format:@"Looked for file: %@",[LWEFile createDocumentPathWithFilename:filename]];
  }
  [self.rootViewController loadTabBar];
}

#pragma mark -
#pragma mark UIApplication Delegate methods

/**
 * Called on iOS4 when the app is put into the background
 * We do not do anything special here.
 */
- (void) applicationDidEnterBackground:(UIApplication *) application
{
  LWE_LOG(@"Application did enter the background now");
}


/**
 * Called on iOS4 when the app comes back to life from background
 * We do not do anything special here.
 */
- (void) applicationWillEnterForeground:(UIApplication *)application
{
  LWE_LOG(@"Application will enter the foreground now");
}

/**
 UIDevice* device = [UIDevice currentDevice];
 
 BOOL backgroundSupported = NO;
 
 if ([device respondsToSelector:@selector(isMultitaskingSupported)])
 
 backgroundSupported = device.multitaskingSupported;
 */

/**
 * Delegate method from UIApplication - re-delegated to RootViewController
 */ 
- (void) applicationWillTerminate:(UIApplication *)application
{
  LWE_LOG(@"Application will terminate");
  [rootViewController applicationWillTerminate:application];
}

//! Standard dealloc
- (void)dealloc
{
	[self setRootViewController:nil];
	[self setWindow:nil];
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