//  jFlashAppDelegate.m
//  jFlash
//
//  Created by シャロット ロス on 5/4/09.
//  Copyright LONG WEEKEND INC 2009. All rights reserved.

#import "jFlashAppDelegate.h"

#import "DSActivityView.h"
#import "TapjoyConnect.h"
#import "AudioSessionManager.h"
#import "Appirater.h"

#import "SettingsViewController.h"
#import "SearchViewController.h"

#if defined(LWE_RELEASE_APP_STORE) || defined(LWE_RELEASE_AD_HOC)
#import "FlurryAPI.h"
#endif

@interface jFlashAppDelegate ()
- (void) _registerObservers;
- (void) _showModalWithViewController:(UIViewController*)vc useNavController:(BOOL)useNavController;
- (void) _showModal:(NSNotification *)notification;
- (BOOL) _needToCopyDatabase;
- (void) _openUserDatabaseWithPlugins;
@property (retain) NSMutableArray *observerArray;
@end

@implementation jFlashAppDelegate

@synthesize observerArray;
@synthesize window, tabBarController, splashView;
@synthesize isFinishedLoading, loadSearchOnBoot;
@synthesize downloadManager, pluginManager, externalAppManager;

#pragma mark - URL Handling

//! For compatibility with iOS2.0 through iOS4.2, when it was deprecated in favor of the below.
- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url
{
  return [self application:application openURL:url sourceApplication:nil annotation:nil];
}

// handles URL openings from other apps
- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
  [self.externalAppManager configureManagerForURL:url sourceBundleId:sourceApplication];
  if (self.isFinishedLoading)
  {
    // If we have finished loading our database, et al, we can jump straight to search.
    [self.externalAppManager runSearch];

    // Now set the index so the search shows up
    self.tabBarController.selectedIndex = SEARCH_VIEW_CONTROLLER_TAB_INDEX;
  }
  else
  {
    self.loadSearchOnBoot = YES;
  }
  return YES;
}

#pragma mark - UITabBarControllerDelegate

/**
 * Delegate callback from UITabBarController.  We use it to find out when we navigate away from search in the event we 
 * came via an external app
 *
 * The external app manager himself COULD be the delegate of tab bar, thus negating the need for this "forwarding" code,
 * but it seems silly that the app manager should care entirely about the state of the tab bar across all tabs.
 */
- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController
{
  // If we are an external start, and the user navigates away from the Search tab, we tell the external manager to reset
  if (self.externalAppManager.appLaunchedFromURL)
  {
    UINavigationController *searchNav = [self.tabBarController.viewControllers objectAtIndex:SEARCH_VIEW_CONTROLLER_TAB_INDEX];
    if (searchNav != viewController)
    {
      [self.externalAppManager resetState];
    }
  }
}

#pragma mark - appDidFinishingLaunching

/** App delegate method, point of entry for the app */
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)userInfo
{
  NSSetUncaughtExceptionHandler(&LWEUncaughtExceptionHandler);  // in case we crash, we can log it
  srandomdev();    // Seed random generator

  // Log user sessions on release builds & connect to Tapjoy for CPI ads
  [LWEAnalytics startSessionWithKey:LWE_FLURRY_API_KEY];
  [TapjoyConnect requestTapjoyConnectWithAppId:LWE_TAPJOY_APP_ID];
  
  // 1. This call initializes app settings in NSUserDefaults if not already done.  Important!  Do this FIRST!
  [[CurrentState sharedCurrentState] initializeSettings];
  
  // 2. Check for plugin updates if it's time for that
	if ([self.pluginManager isTimeForCheckingUpdate])
	{
    [self.pluginManager checkNewPluginsAsynchronous:YES notifyOnNetworkFail:NO];
	}
  
  // 3. Initialize audio session manager - start with audio session "playback" first
  AudioSessionManager *audioManager = [AudioSessionManager sharedAudioSessionManager];
  [audioManager setSessionCategory:AVAudioSessionCategoryPlayback];
  [audioManager setSessionActive:NO];
  
  // 4. Show the splash view
  self.splashView.image = [UIImage imageNamed:LWE_APP_SPLASH_IMAGE];
  [self.window makeKeyAndVisible];
  
  // 5. If we need to copy the xFlash user database (e.g. this is first load), schedule that.
  if ([self _needToCopyDatabase])
  {
    // Show a spinny so the user knows what's up.
    [DSBezelActivityView newActivityViewForView:self.splashView withLabel:NSLocalizedString(@"Setting up...\nThis will take a moment.",@"FirstLoadModalText")];

    LWEDatabase *db = [LWEDatabase sharedLWEDatabase];
    [db asynchCopyDatabaseFromBundle:LWE_CURRENT_USER_DATABASE
                     completionBlock:^{
                       // Get rid of the spinny
                       [DSBezelActivityView removeViewAnimated:YES];

                       // Register & open the database when finished
                       NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
                       [settings setBool:YES forKey:@"db_did_finish_copying"];
                       [self _openUserDatabaseWithPlugins];
                     }];
  }
  else
  {
    dispatch_async(dispatch_get_main_queue(), ^{ [self _openUserDatabaseWithPlugins]; });
  }
  return YES;
}

- (BOOL) _needToCopyDatabase
{
  NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
  NSString *pathToDatabase = [LWEFile createDocumentPathWithFilename:LWE_CURRENT_USER_DATABASE];
  return ([LWEFile fileExists:pathToDatabase] == NO || [settings boolForKey:@"db_did_finish_copying"] == NO);
}


/**
 * Loads & opens the databases and plugins
 */
- (void) _openUserDatabaseWithPlugins
{
  // Open the database - it already exists & is properly copied
  LWEDatabase *db = [LWEDatabase sharedLWEDatabase];
  NSString *filename = LWE_CURRENT_USER_DATABASE;
  BOOL openedDB = [db openDatabase:[LWEFile createDocumentPathWithFilename:filename]];
  LWE_ASSERT_EXC(openedDB, @"Unable to open DB: %@", filename);
  if ([CurrentState sharedCurrentState].isFirstLoad)
  {
    // "Install" the preinstalled bundle plugins (CARD-DB) now
    NSString *cardsDbFilePath = [[NSBundle mainBundle] pathForResource:LWE_PREINSTALLED_PLUGIN_PLIST ofType:nil];
    LWE_ASSERT_EXC(cardsDbFilePath, @"Cannot find preinstalled plugins file");
    NSDictionary *preinstalledPluginHash = [[NSDictionary dictionaryWithContentsOfFile:cardsDbFilePath] objectForKey:CARD_DB_KEY];
    Plugin *cardsDb = [Plugin pluginWithDictionary:preinstalledPluginHash];
    [self.pluginManager installPlugin:cardsDb error:NULL];
  }
  
  // Then load plugins
  BOOL loadedPlugins = [self.pluginManager loadInstalledPlugins];
  LWE_ASSERT_EXC(loadedPlugins, @"Unable to load plugins");

  // Get rid of the splash view
  [self.splashView removeFromSuperview];
  self.splashView = nil;
  
  // Finish setting up & load tab bar
  [self _registerObservers];
  [self.window addSubview:self.tabBarController.view];
  [Appirater appLaunched];
  
  // Finally load search if we're supposed to do that.
  if (self.loadSearchOnBoot)
  {
    [self.externalAppManager runSearch];
    self.tabBarController.selectedIndex = SEARCH_VIEW_CONTROLLER_TAB_INDEX;
  }
  
  // MMA - 12.10.2011 not ENTIRELY sure this is still necessary.  If this code can enver be executed 
  // before openURL: call above, then this whole setup can be removed.  It was originally set up as a 
  // concurrency check?  Or maybe, no, I remember now -- it's for when the app's already been loaded 
  // but is just in the BG.  That's right.
  self.isFinishedLoading = YES;
}

#pragma mark - Register Observers

- (void) _registerObservers
{
  self.observerArray = [NSMutableArray array];
  
  // MMA Apparently, there really isn't a way around this dirtiness.
  __block jFlashAppDelegate *blockSelf = self;
  NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
  
  id observer = nil;
  // Register listener to switch the tab bar controller index programmatically
  observer = [center addObserverForName:LWEShouldSwitchTab object:nil queue:nil usingBlock:^(NSNotification *notification)
  {
    NSNumber *index = [notification.userInfo objectForKey:@"index"];
    blockSelf.tabBarController.selectedIndex = [index integerValue];
  }];
  [self.observerArray addObject:observer];
  
  //Register the generic show modal, and dismiss modal notification which can be used by any view controller.
  [center addObserver:self selector:@selector(_showModal:) name:LWEShouldShowModal object:nil];
}


#pragma mark - Generic Modal Pop-ups and dismissal. 

/**
 * Private method that actually does the dirty work of displaying any modal
 */
- (void) _showModalWithViewController:(UIViewController*)vc useNavController:(BOOL)useNavController
{
  if (useNavController)
  {
    UINavigationController *controller = [[UINavigationController alloc] initWithRootViewController:vc];
    [self.tabBarController presentModalViewController:controller animated:YES];
    [controller release];
  }
  else
  {
    [self.tabBarController presentModalViewController:vc animated:YES];    
  }
}

/**
 * Show Modal method that will call the show modal view controller private method.
 * the notification user info will determine whether it will be animated, and what view controller to view. 
 */
- (void) _showModal:(NSNotification *)notification
{
	NSDictionary *dict = [notification userInfo];
	//It will do anything if there is any information in regard to what view controller to be pop-ed up.
  LWE_ASSERT_EXC(dict && ([dict count] > 0), @"Show modal notification cannot run properly, caused by nil or zero length of NSNotification user info dictionary.");
  UIViewController *vc = (UIViewController *) [dict objectForKey:@"controller"];
  
  // Default to YES
  BOOL useNavController = YES;
  if ([dict valueForKey:@"useNavController"])
  {
    useNavController = [[dict valueForKey:@"useNavController"] boolValue];
  }
  [self _showModalWithViewController:vc useNavController:useNavController];
}


#pragma mark - Local Notifications

- (void) scheduleLocalNotification 
{
  // should we set up a new one
  NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
  NSNumber *reminderSetting = [settings objectForKey:APP_REMINDER];
  if (reminderSetting == nil || [reminderSetting intValue] == 0)
  {
    return;
  }
  
  // create a notification to study again
  UILocalNotification *localNotification = [[UILocalNotification alloc] init];
  NSTimeInterval secondsToNextReminder = 24 * 60 * 60 * [reminderSetting intValue];
  localNotification.fireDate = [NSDate dateWithTimeIntervalSinceNow:secondsToNextReminder];
  localNotification.timeZone = [NSTimeZone localTimeZone];
  localNotification.alertBody = NSLocalizedString(@"You're Awesome!  It's time to learn some more words!",@"StudyNotification.Body");
  localNotification.alertAction = NSLocalizedString(@"Study",@"StudyNotification.Action");
  localNotification.soundName = UILocalNotificationDefaultSoundName;

  // schedule it
  [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
  
  // the application retains the notification
  [localNotification release];
}

#pragma mark - UIApplication Delegate methods

/**
 * Called on iOS4 when the app is put into the background
 */
- (void) applicationDidEnterBackground:(UIApplication *) application
{
  // We no longer care if we came from another app
  [self.externalAppManager resetState];
  
  [self scheduleLocalNotification];
}

- (void) applicationDidBecomeActive:(UIApplication *)application
{
  // get rid of old notifications -- we use "did become active" because it is called both on 
  // first launch AND on resume from background/SMS/just about anything
  [[UIApplication sharedApplication] cancelAllLocalNotifications];
}

/**
 * Called on iOS4 when the app comes back to life from background
 * Here, we delete the plist file created in the background
 * because the cards should still be in memory.
 */
- (void) applicationWillEnterForeground:(UIApplication *)application
{
  // We make the PLIST when going into the background, as we may be killed/terminated.
  // However, this call (enter foreground) means we're back w/o termination, so we can
  // delete our PLIST.
  [LWEFile deleteFile:[LWEFile createCachesPathWithFilename:@"ids.plist"]];
}

// Just pass it on to the new iOS4 delegate
- (void) applicationWillTerminate:(UIApplication *)application
{
  [self applicationDidEnterBackground:application];
}

#pragma mark -

- (void)dealloc
{
  // This handles the name/selector-based
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  
  // This handles the block-based notifications
  for (id observer in self.observerArray)
  {
    [[NSNotificationCenter defaultCenter] removeObserver:observer];
  }
  
  [observerArray release];
  [tabBarController release];
  [window release];
  
  [externalAppManager release];
  [downloadManager release];
  [pluginManager release];
  
  [super dealloc];
}

@end