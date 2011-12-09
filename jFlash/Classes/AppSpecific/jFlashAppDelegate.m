//  jFlashAppDelegate.m
//  jFlash
//
//  Created by シャロット ロス on 5/4/09.
//  Copyright LONG WEEKEND INC 2009. All rights reserved.

#import "jFlashAppDelegate.h"

#import "DSActivityView.h"
#import "NSURL+IFUnicodeURL.h"
#import "TapjoyConnect.h"
#import "AudioSessionManager.h"
#import "Appirater.h"

#import "SettingsViewController.h"
#import "SearchViewController.h"

#import "LWEPackageDownloader.h"
#import "ModalTaskViewController.h"

#if defined(LWE_RELEASE_APP_STORE) || defined(LWE_RELEASE_AD_HOC)
#import "FlurryAPI.h"
#endif

@interface jFlashAppDelegate ()
- (void) _switchToSearchWithTerm:(NSString*)term;
- (void) _showModalWithViewController:(UIViewController*)vc useNavController:(BOOL)useNavController;
- (void) showDownloaderModal:(NSNotification*)aNotification;
- (void) _registerObservers;
- (BOOL) _needToCopyDatabase;
- (void) _openUserDatabaseWithPlugins;
@property (retain) NSMutableArray *observerArray;
@end

@implementation jFlashAppDelegate

@synthesize observerArray;
@synthesize window, tabBarController, splashView;
@synthesize isFinishedLoading;
@synthesize downloadManager, pluginManager;

#pragma mark - URL Handling

- (NSString*) getDecodedSearchTerm:(NSURL *)url  
{
  NSString *searchTerm = [url unicodeAbsoluteString];
  if ([searchTerm isEqualToString:@""] || [searchTerm isEqualToString:@"jflash://"])
  {
    searchTerm = [[url absoluteString] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
  }
  searchTerm = [searchTerm stringByReplacingOccurrencesOfString:@"jflash://" withString:@""];
  return searchTerm;
}

// handles URL openings from other apps
- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
  NSString *searchTerm = [self getDecodedSearchTerm:url];
  if (self.isFinishedLoading)
  {
    // If we have finished loading our database, et al, we can jump straight to search.
    [self _switchToSearchWithTerm:searchTerm];
  }
  else
  {
    // Add an observer to wait for the loading of the Tab Bar, stash the term so we have it later
    // This is private among these two methods so we are manually managing memory here instead of synthesizers
    [self addObserver:self forKeyPath:@"isFinishedLoading" options:NSKeyValueObservingOptionNew context:NULL];
    _searchedTerm = [searchTerm retain];
  }
  return YES;
}

- (void) observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void *)context
{
  if ([keyPath isEqualToString:@"isFinishedLoading"] && [[change objectForKey:NSKeyValueChangeNewKey] boolValue] == YES)
  {
    // Now be done with it, get rid of the observer too
    [self removeObserver:self forKeyPath:@"isFinishedLoading"];
    [self _switchToSearchWithTerm:_searchedTerm];
    [_searchedTerm release];
  }
}

- (void) _switchToSearchWithTerm:(NSString*)term
{
  UINavigationController *searchNav = [self.tabBarController.viewControllers objectAtIndex:SEARCH_VIEW_CONTROLLER_TAB_INDEX];
  LWE_ASSERT_EXC([searchNav isKindOfClass:[UINavigationController class]],@"Whoa");
  
  SearchViewController *searchVC = (SearchViewController*)[searchNav topViewController];
  LWE_ASSERT_EXC([searchVC isKindOfClass:[SearchViewController class]], @"Whoa");
  [searchVC runSearchAndSetSearchBarForString:term];
  
  // Now set the index so the search shows up
  self.tabBarController.selectedIndex = SEARCH_VIEW_CONTROLLER_TAB_INDEX;
}

//! For compatibility
- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url
{
  return [self application:application openURL:url sourceApplication:nil annotation:nil];
}

#pragma mark - appDidFinishingLaunching

/** App delegate method, point of entry for the app */
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)userInfo
{
#if defined(LWE_RELEASE_APP_STORE) || defined(LWE_RELEASE_AD_HOC)
  [FlurryAPI startSession:@"1ZHZ39TNG7GC3VT5PSW4"];    // add analytics if this is live
  [TapjoyConnect requestTapjoyConnectWithAppId:@"6f0f78d1-f4bf-437b-befc-977b317f7b04"];     // Connect to Tapjoy for CPI ads
#endif

  NSSetUncaughtExceptionHandler(&LWEUncaughtExceptionHandler);  // in case we crash, we can log it
  srandomdev();    // Seed random generator

  // This call initializes app settings in NSUserDefaults if not already done.  Important!  Do this FIRST!
  CurrentState *state = [CurrentState sharedCurrentState];
  [state initializeSettings];
  
  // We initialize the plugins manager
	if ([self.pluginManager isTimeForCheckingUpdate])
	{
		/**
		 * This only runs when the program is launched. 
		 * This private methods will be run in the background, because the dictionary which data is coming from the internet sometimes can take quite a few minutes. 
		 * And that process will block the UI. So, if the user click the button "Check For Update" This method will be called from the background, and it will update the badge
		 * number, and all of the data if it has finished.
		 */
    [self.pluginManager checkNewPluginsAsynchronous:YES notifyOnNetworkFail:NO];
	}
  
  // Initialize audio session manager - start with audio session "playback" first
  AudioSessionManager *audioManager = [AudioSessionManager sharedAudioSessionManager];
  [audioManager setSessionCategory:AVAudioSessionCategoryPlayback];
  [audioManager setSessionActive:NO];

  self.splashView.image = [UIImage imageNamed:LWE_APP_SPLASH_IMAGE];
  [self.window makeKeyAndVisible];
  
  // If we need to copy the xFlash user database (e.g. this is first load), do that first.
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
  [self.pluginManager loadInstalledPlugins];

  // Get rid of the splash view
  [self.splashView removeFromSuperview];
  self.splashView = nil;
  
  // Finish setting up & load tab bar
  [self _registerObservers];
  [self.window addSubview:self.tabBarController.view];
  self.isFinishedLoading = YES;
  [Appirater appLaunched];
}

# pragma mark Convenience Methods

//! Called via first responder from progress view
- (IBAction)switchToSettings
{
  self.tabBarController.selectedIndex = SETTINGS_VIEW_CONTROLLER_TAB_INDEX;
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
  
  // Hide any modal view controller, optionally animated.  Used by plugin downloaders, twitter stuff
  void (^dismissBlock)(NSNotification*) = ^(NSNotification *notification)
  {
    //if the animated key is not specified in the user info, it will be animated.
    NSDictionary *dict = [notification userInfo];
    BOOL animated = YES;
    if ([dict valueForKey:@"animated"])
    {
      animated = [[dict valueForKey:@"animated"] boolValue];
    }
    [blockSelf.tabBarController dismissModalViewControllerAnimated:animated];
  };
  observer = [center addObserverForName:LWEShouldDismissModal object:nil queue:nil usingBlock:dismissBlock];
  [self.observerArray addObject:observer];
  
  // Show popover for progress view
  observer = [center addObserverForName:LWEShouldShowPopover object:nil queue:nil usingBlock:^(NSNotification *notification)
  {
    UIViewController *controller = (UIViewController *)[notification.userInfo objectForKey:@"controller"];
    if (controller)
    {
      // For some reason we have to adjust this.   Tihs is still a hack.
      CGRect frame = controller.view.frame;
      frame.origin = CGPointMake(0, 20);
      controller.view.frame = frame;
      [blockSelf.tabBarController.view addSubview:controller.view];
    }
  }];
  [self.observerArray addObject:observer];
  
  // Register listener to pop up downloader modal for search FTS download & ex sentence download
  [center addObserver:self selector:@selector(showDownloaderModal:) name:LWEShouldShowDownloadModal object:nil];
  
  //Register the generic show modal, and dismiss modal notification which can be used by any view controller.
  [center addObserver:self selector:@selector(showModal:) name:LWEShouldShowModal object:nil];
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
- (void)showModal:(NSNotification *)notification
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

/**
 * Pops up a modal over the screen when the user needs to download something
 * Relies on _showModalWithViewController:useNavController:
 */
- (void) showDownloaderModal:(NSNotification*)aNotification
{
  // If the user tries to re-lauch while we are downloading, just re-launch that modal.
  if ([self.downloadManager pluginIsDownloading])
  {
    [self _showModalWithViewController:self.downloadManager.modalTaskViewController useNavController:YES];
    return;
  }
  
  Plugin *thePlugin = (Plugin *)aNotification.object;
  LWE_ASSERT_EXC(thePlugin, @"This method can't be called with a nil plugin.");
  
  // Instantiate downloader with jFlash download URL & destination filename
  //TODO: iPad customization here
  ModalTaskViewController *dlViewController = [[ModalTaskViewController alloc] initWithNibName:@"ModalTaskView" bundle:nil];
  dlViewController.title = NSLocalizedString(@"Get Update",@"ModalTaskViewController_Update.NavBarTitle");
  dlViewController.webViewContent = thePlugin.htmlString;
  
  // Get path information
  LWEPackageDownloader *packageDownloader = [[LWEPackageDownloader alloc] initWithDownloaderDelegate:self.downloadManager];
  packageDownloader.progressDelegate = dlViewController;
  [packageDownloader queuePackage:[thePlugin downloadPackage]];
  dlViewController.taskHandler = packageDownloader;
  [self _showModalWithViewController:dlViewController useNavController:YES];
  [packageDownloader release];
  
  // Hold on to this
  self.downloadManager.modalTaskViewController = dlViewController;
  [dlViewController release];
}


#pragma mark - UIApplication Delegate methods

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

/**
 * Called on iOS4 when the app is put into the background
 */
- (void) applicationDidEnterBackground:(UIApplication *) application
{
  LWE_LOG(@"Application did enter the background now");
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
  
  // We need to do this so that way this code knows to get a new card when loading 2nd or later set in one session
  NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
  [settings setInteger:0 forKey:@"card_id"];
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
  
  [downloadManager release];
  [pluginManager release];
  
  // Handle all singletons
  CurrentState *state = [CurrentState sharedCurrentState];
  LWEDatabase *db = [LWEDatabase sharedLWEDatabase];
  ThemeManager *tm = [ThemeManager sharedThemeManager];
  [db release];
  [state release];
  [tm release];
  
  [super dealloc];
}

@end