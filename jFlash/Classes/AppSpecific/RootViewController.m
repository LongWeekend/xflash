//
//  RootViewController.m
//  jFlash
//
//  Created by Mark Makdad on 2/20/10.
//  Copyright 2010 LONG WEEKEND INC.. All rights reserved.
//

#import "RootViewController.h"

//! Takes control from appDelegate and loads tab bar controller programmatically - top level view controller in the app
@implementation RootViewController

@synthesize loadingView;
@synthesize i;
@synthesize tabBarController;


- (id)init
{
  LWE_LOG(@"Entering Init");
  if (self = [super init])
  {
    i = 0;
    // Register listener to switch the tab bar controller when the user selects a new set
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(switchToStudyView) name:@"switchToStudyView" object:nil];
    // Register listener to pop up downloader modal for search FTS download & ex sentence download
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(shouldShowDownloaderModal:) name:@"shouldShowDownloaderModal" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(shouldHideDownloaderModal:) name:@"shouldHideDownloaderModal" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(shouldSwapSearchViewController) name:@"shouldSwapSearchViewController" object:nil];
    
    // This call loads/initializes settings and if we don't call this here, shit WILL break.
    CurrentState *state = [CurrentState sharedCurrentState];
    [state initializeSettings];
  }
	return self;
}

/**
 * Loads the jFlash logo splash screen and calls the database loader when finished
 */
- (void) loadView
{
  // Make the main view the themed splash screen
  UIView *view = [[UIView alloc] initWithFrame:[UIScreen mainScreen].applicationFrame];
  NSString *pathToSplashImage = [[ThemeManager sharedThemeManager] elementWithCurrentTheme:@"Default.png"];
  view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:pathToSplashImage]];
  self.view = view;
  [view release];
  
  // Database work next, but put delay so we can update the UIKIT with the splash screen
  [self performSelector:@selector(_prepareDatabase) withObject:nil afterDelay:0.0];
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
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_openDatabase) name:@"DatabaseCopyFinished" object:nil];
    LWEDatabase *db = [LWEDatabase sharedLWEDatabase];
    [db performSelectorInBackground:@selector(copyDatabaseFromBundle:) withObject:@"jFlash.db"];

    // Show the "database loading" view
    loadingView = [LoadingView loadingViewInView:self.view withText:@"Setting up jFlash for first time use. This might take a minute."];
  }
  else
  {
    // Finished copying, and we have the database file - just open it
    [self _openDatabase];
  }
}


/**
 * Loads & opens the databases (including if it doesn't exist), calls loadTabBar when finished
 */
- (void) _openDatabase
{
  // Remove observer if we had one for first copy, also get rid of the loading page if we had one
  [[NSNotificationCenter defaultCenter] removeObserver:self name:@"DatabaseCopyFinished" object:nil];
	if (loadingView)
  {
    [loadingView removeView];
	}
  
  // Open the database - it already exists & is properly copied
  if ([[LWEDatabase sharedLWEDatabase] openDatabase:[LWEFile createDocumentPathWithFilename:@"jFlash.db"]])
  {
    // Then load plugins
    [[[CurrentState sharedCurrentState] pluginMgr] loadInstalledPlugins];
  }
  else
  {
    // Could not open database!
  }
  [self _loadTabBar];
}


/**
 * Programmatically creates a TabBarController and adds nav/view controllers for each tab item
 */
- (void) _loadTabBar
{
  LWE_LOG(@"START Tab bar");
  
	self.tabBarController = [[UITabBarController alloc] init];
  
  CurrentState *state = [CurrentState sharedCurrentState];
  [state loadActiveTag];
  
  // Make room for the status bar
  CGRect tabBarFrame;
  tabBarFrame = CGRectMake(0, 0, 320, 460);
	self.tabBarController.view.frame = tabBarFrame;
  UINavigationController *localNavigationController;
	NSMutableArray *localControllersArray = [[NSMutableArray alloc] initWithCapacity:5];

  StudyViewController *studyViewController = [[StudyViewController alloc] init];
  [localControllersArray addObject:studyViewController];
  [studyViewController release];
  
  StudySetViewController *studySetViewController = [[StudySetViewController alloc] init];
  localNavigationController = [[UINavigationController alloc] initWithRootViewController:studySetViewController];
  [localControllersArray addObject:localNavigationController];
  [studySetViewController release];
  [localNavigationController release];
  
  UIViewController *searchViewController;
  // Depending on whether user has search FTS installed or not, we use different controller for search
  if ([[state pluginMgr] pluginIsLoaded:FTS_DB_KEY])
  {
    LWE_LOG(@"User HAS FTS database plugin installed");
    searchViewController = [[SearchViewController alloc] init];
  }
  else
  {
    LWE_LOG(@"User DOES NOT have FTS database plugin installed");
    searchViewController = [[SearchUnavailableViewController alloc] init];
  }
  localNavigationController = [[UINavigationController alloc] initWithRootViewController:searchViewController];
  [localControllersArray addObject:localNavigationController];
  [searchViewController release];
  [localNavigationController release];
  
  SettingsViewController *settingsViewController = [[SettingsViewController alloc] init];
  localNavigationController = [[UINavigationController alloc] initWithRootViewController:settingsViewController];
  [localControllersArray addObject:localNavigationController];
  [settingsViewController release];
  [localNavigationController release];
  
  HelpViewController *helpViewController = [[HelpViewController alloc] init];
  localNavigationController = [[UINavigationController alloc] initWithRootViewController:helpViewController];
  [localControllersArray addObject:localNavigationController];
  [helpViewController release];
  [localNavigationController release];
  
  tabBarController.viewControllers = localControllersArray;
	[localControllersArray release];

  // Replace active view with tabBarController's view
  self.view = tabBarController.view;

  // Show a UIAlert if this is the first time the user has launched the app.
  CurrentState *appSettings = [CurrentState sharedCurrentState];
  if (appSettings.isFirstLoad)
  {
    UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:@"Welcome to Japanese Flash!" message:@"To get you started, we've loaded our favorite words as an example set.   To study other sets, tap the 'Study Sets' icon below." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alertView show];
    [alertView release];
    // RSH Jun 3 2010 - why are we doing this in study view controller?  This shouldn't know about the program state
    appSettings.isFirstLoad = NO;
  }
  
  LWE_LOG(@"END Tab bar");
  
  //launch the please rate us
  [Appirater appLaunched];
}


# pragma mark Convenience Methods for Notifications

//! Switches active view to study view, convenience method for notification
- (void) switchToStudyView
{
  [tabBarController setSelectedIndex:STUDY_VIEW_CONTROLLER_TAB_INDEX]; 
}


//! Pops up a modal over the screen when the user needs to download something
- (void) shouldShowDownloaderModal:(NSNotification*)aNotification
{
  DownloaderViewController* dlViewController = [[DownloaderViewController alloc] initWithNibName:@"DownloaderView" bundle:nil];

  // Instantiate downloader with jFlash download URL & destination filename
  NSString *targetURL  = [[aNotification userInfo] objectForKey:@"target_url"];
  NSString *targetPath = [[aNotification userInfo] objectForKey:@"target_path"];
  LWEDownloader *tmpDlHandler = [[LWEDownloader alloc] initWithTargetURL:targetURL targetPath:targetPath];
   
  // Set the installer delegate to the PluginManager class
  [tmpDlHandler setDelegate:[[CurrentState sharedCurrentState] pluginMgr]];
  [dlViewController setDlHandler:tmpDlHandler];
  
  UINavigationController *modalNavController = [[UINavigationController alloc] initWithRootViewController:dlViewController];
  [dlViewController release];

  [[self tabBarController] presentModalViewController:modalNavController animated:YES];
  [modalNavController release];
}


//! Hides the downloader
- (void) shouldHideDownloaderModal:(NSNotification*)aNotification
{
  [[self tabBarController] dismissModalViewControllerAnimated:YES];
}


//TODO: this is not the best implementation MMA 6/3/2010
//! Changes the middle tab bar to searchViewController
- (void) shouldSwapSearchViewController
{
  NSArray* vcs = [[self tabBarController] viewControllers];
  NSMutableArray *tmpVcs = [NSMutableArray arrayWithArray:vcs];
  SearchViewController *svc = [[SearchViewController alloc] init];
  UINavigationController *localNavigationController = [[UINavigationController alloc] initWithRootViewController:svc];
  [tmpVcs replaceObjectAtIndex:2 withObject:localNavigationController];
  [svc release];
  [localNavigationController release];
  [[self tabBarController] setViewControllers:tmpVcs animated:NO];
}

# pragma mark Delegate Methods

-(void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	[tabBarController viewWillAppear:animated];
}


-(void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
	[tabBarController viewWillDisappear:animated];
}


-(void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	[tabBarController viewDidAppear:animated];
}


-(void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
	[tabBarController viewDidDisappear:animated];
}

# pragma mark Housekeeping

//! Delegate method of UIApplication (via AppDelegate); called on shutdown
- (void) applicationWillTerminate:(UIApplication*)application
{
  // Get current card from StudyViewController
  StudyViewController* studyCtl = [tabBarController.viewControllers objectAtIndex:STUDY_VIEW_CONTROLLER_TAB_INDEX];
  
  // Save current card, user, and set, update cache
  CurrentState *state = [CurrentState sharedCurrentState];
  
  NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
  [settings setInteger:studyCtl.currentCard.cardId forKey:@"card_id"];
  [settings setInteger:state.activeTag.tagId forKey:@"tag_id"];
  [settings setInteger:state.activeTag.currentIndex forKey:@"current_index"];
  [settings setInteger:0 forKey:@"first_load"];
  [settings setInteger:0 forKey:@"app_running"];
  [settings synchronize];
  
  // Only freeze if we have a database
  if ([[LWEDatabase sharedLWEDatabase] dao]) [[state activeTag] freezeCardIds];
}


- (void)dealloc
{
  // Unobserve notifications
	[[NSNotificationCenter defaultCenter] removeObserver:self];

  // Clear the application settings singleton
  CurrentState* state = [CurrentState sharedCurrentState];
  LWEDatabase *db = [LWEDatabase sharedLWEDatabase];
  [db release];
  [state release];

  [super dealloc];
}

@end
