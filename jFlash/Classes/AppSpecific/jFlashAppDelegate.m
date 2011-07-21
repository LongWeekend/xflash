//  jFlashAppDelegate.m
//  jFlash
//
//  Created by シャロット ロス on 5/4/09.
//  Copyright LONG WEEKEND INC 2009. All rights reserved.

#import "jFlashAppDelegate.h"
#import "RootViewController.h"
#import "CurrentState.h"
#import "LWEFile.h"
#import "LWEDatabase.h"
#import "ThemeManager.h"
#import "DatabaseUpdateManager.h"
#import "NSURL+IFUnicodeURL.h"
#import "TapjoyConnect.h"

#if defined(LWE_RELEASE_APP_STORE) || defined(LWE_RELEASE_AD_HOC)
#import "FlurryAPI.h"
#endif

@implementation jFlashAppDelegate

@synthesize window, rootViewController, backgroundSupported;

#pragma mark -
#pragma mark URL Handling

// handles URL openings from other apps
- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
  NSString *searchTerm = [url unicodeAbsoluteString];
  if ([searchTerm isEqualToString:@""] || [searchTerm isEqualToString:@"jflash://"])
  {
    searchTerm = [[url absoluteString] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
  }
  searchTerm = [searchTerm stringByReplacingOccurrencesOfString:@"jflash://" withString:@""];
  if ([self.rootViewController isFinishedLoading])
  {
    [self.rootViewController switchToSearchWithTerm:searchTerm];
  }
  else
  {
    // Add an observer to wait for the loading of the Tab Bar, stash the term so we have it later
    // This is private among these two methods so we are manually managing memory here instead of synthesizers
    [self.rootViewController addObserver:self forKeyPath:@"isFinishedLoading" options:NSKeyValueObservingOptionNew context:NULL];
    _searchedTerm = [searchTerm retain];
  }
  return YES;
}

- (void) observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void *)context
{
  if ([keyPath isEqualToString:@"isFinishedLoading"] && [[change objectForKey:NSKeyValueChangeNewKey] boolValue])
  {
    // Now be done with it, get rid of the observer too
    [self.rootViewController switchToSearchWithTerm:_searchedTerm];
    [self.rootViewController removeObserver:self forKeyPath:@"isFinishedLoading"];
    [_searchedTerm release];
  }
}

//! For compatibility
- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url
{
  return [self application:application openURL:url sourceApplication:nil annotation:nil];
}

#pragma mark -
#pragma mark appDidFinishingLaunching

/** App delegate method, point of entry for the app */
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)userInfo
{
  #if defined(LWE_RELEASE_APP_STORE) || defined(LWE_RELEASE_AD_HOC)
    // add analytics if this is live
    NSSetUncaughtExceptionHandler(&uncaughtExceptionHandler);
    [FlurryAPI startSession:@"1ZHZ39TNG7GC3VT5PSW4"];
  
    // Connect to Tapjoy for CPI ads
    [TapjoyConnect requestTapjoyConnectWithAppId:@"6f0f78d1-f4bf-437b-befc-977b317f7b04"];
  #endif
  
  // Find out if we are a multitasking environment
  UIDevice* device = [UIDevice currentDevice];
  if ([device respondsToSelector:@selector(isMultitaskingSupported)])
  {
	  //self.backgroundSupported = device.multitaskingSupported;
  }
  else
  {
	  self.backgroundSupported = NO;
  }
  
  // Seed random generator
  srandomdev();
  
  // This call initializes app settings in NSUserDefaults if not already done.  Important!  Do this FIRST!
  // Seriously.  If you don't call this before ANY jFlash user code, you run this risk of making jFlash's 
  // upgrade path ABSOLUTELY unstable.  Capiche?
  CurrentState *state = [CurrentState sharedCurrentState];
  [state initializeSettings];

  // Load root controller to show splash screen
  [self setRootViewController:[[[RootViewController alloc] init] autorelease]];
	[window addSubview:self.rootViewController.view];
  [window makeKeyAndVisible];
  
  // Finally check to see if we launched via URL (this is for non iOS4)
  // On iOS4, the delegate is called back directly
  // See: http://stackoverflow.com/questions/3612460/lauching-app-with-url-via-uiapplicationdelegates-handleopenurl-working-under-i
  NSURL *aUrl = [userInfo objectForKey:UIApplicationLaunchOptionsURLKey];
  if (aUrl && [[[UIDevice currentDevice] systemVersion] hasPrefix:@"3"])
  {
    // Add an observer to wait for the loading of the Tab Bar, stash the term so we have it later
    // This is private among these two methods so we are manually managing memory here instead of synthesizers
    // REVIEW: This is copy pasted code Mark, very bad. Should create a method to do this instead that gets called
    // from both locations - RSH
    NSString* searchTerm = [aUrl absoluteString];
    searchTerm = [searchTerm stringByReplacingOccurrencesOfString:@"jflash://" withString:@""];
    [self.rootViewController addObserver:self forKeyPath:@"isFinishedLoading" options:NSKeyValueObservingOptionNew context:NULL];
    _searchedTerm = [searchTerm retain];
  }
  
  // Add a delay here so that the UI has time to update
  [self performSelector:@selector(_prepareUserDatabase) withObject:nil afterDelay:0.0f];
  
  return YES;
}

#if defined(LWE_RELEASE_APP_STORE) || defined(LWE_RELEASE_AD_HOC)
//! Flurry exception handler (only installed in final app store version)
void uncaughtExceptionHandler(NSException *exception)
{
  NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
  CurrentState *currentState = [CurrentState sharedCurrentState];
  jFlashAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
  NSInteger tabIndex = appDelegate.rootViewController.tabBarController.selectedIndex;
  NSString *debugInfo = [NSString stringWithFormat:
                         @"DEBUG - Active Tab: %d, Data: %@, Settings: %@, Active Tag: %d, Browse: %@",
                         tabIndex,
                         [settings valueForKey:APP_DATA_VERSION],
                         [settings valueForKey:APP_SETTINGS_VERSION],
                         [[currentState activeTag] tagId],
                         [settings valueForKey:APP_MODE]];
  LWE_LOG(@"%@",debugInfo);
  [FlurryAPI logError:@"Uncaught" message:debugInfo exception:exception];
}
#endif

/**
 * Checks whether or not to install the main database from the bundle
 */
- (void) _prepareUserDatabase
{
  // Determine if the MAIN database exists or not
  NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];

#if APP_TARGET == APP_TARGET_JFLASH
  NSString *filename = JFLASH_CURRENT_USER_DATABASE;
#else
  NSString *filename = CFLASH_CURRENT_USER_DATABASE;
#endif
  
  NSString *pathToDatabase = [LWEFile createDocumentPathWithFilename:filename];
  if (![LWEFile fileExists:pathToDatabase] || ![settings boolForKey:@"db_did_finish_copying"])
  {
    // Register a notification to wait here for the success, then do the DB copy
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_openUserDatabaseWithPlugins) name:LWEDatabaseCopyDatabaseDidSucceed object:nil];
    LWEDatabase *db = [LWEDatabase sharedLWEDatabase];
    [[self rootViewController] showDatabaseLoadingView];
    // Only ever copy the latest user database
    [db performSelectorInBackground:@selector(copyDatabaseFromBundle:) withObject:filename];
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
  [[NSNotificationCenter defaultCenter] removeObserver:self name:LWEDatabaseCopyDatabaseDidSucceed object:nil];
  
  // Open the database - it already exists & is properly copied
  LWEDatabase *db = [LWEDatabase sharedLWEDatabase];

#if APP_TARGET == APP_TARGET_JFLASH
  NSString *filename = JFLASH_CURRENT_USER_DATABASE;
#else
  NSString *filename = CFLASH_CURRENT_USER_DATABASE;
#endif

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

// TODO: not in use. Waiting for next release
//- (void) scheduleLocalNotification 
//{
//  // get rid of old notifications
//  [[UIApplication sharedApplication] cancelAllLocalNotifications];
//  
//  // should we set up a new one
//  NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
//  id reminderSetting = [settings objectForKey:APP_REMINDERS];
//  if (reminderSetting == nil || [reminderSetting intValue] == 0)
//  {
//    return;
//  }
//  
//  // create a notification to study again
//  UILocalNotification* localNotification = [[UILocalNotification alloc] init];
//  
//  NSTimeInterval secondsToNextReminder = 24 * 60 * 60 * [reminderSetting intValue];
//
//  localNotification.fireDate = [NSDate dateWithTimeIntervalSinceNow:secondsToNextReminder];
//  localNotification.timeZone = [NSTimeZone localTimeZone];
//  localNotification.alertBody = @"It's time to learn some more words! This is your study reminder.";
//  localNotification.alertAction = @"Study Now";
//  localNotification.soundName = UILocalNotificationDefaultSoundName;
//
//  // schedule it
//  [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
//  
//  // the application retains the notification
//  [localNotification release];
//}

/**
 * Called on iOS4 when the app is put into the background
 * We ask Tag to freeze its current state to a plist so if the app is killed
 * while in the background, we can get it back!
 */
- (void) applicationDidEnterBackground:(UIApplication *) application
{
  LWE_LOG(@"Application did enter the background now");
  // Get current card from StudyViewController - this is REALLY BAD for coupling!
  // TODO: put the current card into current state
  StudyViewController* studyCtl = [rootViewController.tabBarController.viewControllers objectAtIndex:STUDY_VIEW_CONTROLLER_TAB_INDEX];
  
  // Only freeze if we have a database
  if ([[[LWEDatabase sharedLWEDatabase] dao] goodConnection])
  {
    // Save current card, user, and set, update cache
    CurrentState *state = [CurrentState sharedCurrentState];
    NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
    [settings setInteger:studyCtl.currentCard.cardId forKey:@"card_id"];
    [settings setInteger:state.activeTag.tagId forKey:@"tag_id"];
    [settings setInteger:state.activeTag.currentIndex forKey:@"current_index"];
    [settings synchronize];
    [[state activeTag] freezeCardIds];
  }
  
  // TODO: not in use for this version
  //[self scheduleLocalNotification];
}


/**
 * Called on iOS4 when the app comes back to life from background
 * Here, we delete the plist file created in the background
 * because the cards should still be in memory.
 */
- (void) applicationWillEnterForeground:(UIApplication *)application
{
  // the plist is only made in case we are terminated.  If not terminated, no need for this - it will mess stuff up in tag -> populateCardIds
  if ([LWEFile fileExists:[LWEFile createDocumentPathWithFilename:@"ids.plist"]])
  {
    LWE_LOG(@"After entering foreground, found plist, deleting plist (we have cards in memory instead)");
    [LWEFile deleteFile:[LWEFile createDocumentPathWithFilename:@"ids.plist"]];
  }
  
  // We need to do this so that way this code knows to get a new card when loading 2nd or later set in one session
  NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
  [settings setInteger:0 forKey:@"card_id"];
}


/**
 * Delegate method from UIApplication - re-delegated to RootViewController
 */ 
- (void) applicationWillTerminate:(UIApplication *)application
{
  // Just pass it on to the new iOS4 delegate
  LWE_LOG(@"Application will terminate");
  [self applicationDidEnterBackground:application];
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