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

@synthesize delegate;
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
  }
	return self;
}

/**
 * Loads the jFlash logo splash screen and calls the database loader when finished
 */
- (void) loadView
{
  // Splash screen
  //TODO: make this work w/o a default on first load
  //TODO: get rid of these path names all over this code
  NSString* tmpStr = [[NSString alloc] initWithFormat:@"/%@theme-cookie-cutters/Default.png",[[ThemeManager sharedThemeManager] currentThemeFileName]];
  UIView *view = [[UIView alloc] initWithFrame:[UIScreen mainScreen].applicationFrame];
  view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:tmpStr]];
  [tmpStr release];
  self.view = view;
  [view release];
  
  // Database work next, but put delay so we can update the UIKIT with the splash screen
  [self performSelector:@selector(loadDatabase) withObject:nil afterDelay:0.1];
}  


/**
 * Loads & opens the databases (including if it doesn't exist), calls loadTabBar when finished
 */
- (void) loadDatabase
{
  // Get singleton objects - settings, current state, database
  NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
  CurrentState *state = [CurrentState sharedCurrentState];
  LWEDatabase *db = [LWEDatabase sharedLWEDatabase];
  
  // This call loads/initializes settings and if we don't call this here, shit WILL break.
  [state initializeSettings];
  
  // Determine if the MAIN database exists or not
  NSString* pathToDatabase = [LWEFile createDocumentPathWithFilename:@"jFlash.db"];
  bool dbDidFinishCopying = [settings boolForKey:@"db_did_finish_copying"];
  if (state.isFirstLoad || ![db databaseFileExists:pathToDatabase] || !dbDidFinishCopying)
  {
    // Load the "waiting" view for the new database copy
    [self showFirstLoadProgressView];
  }
  else
  {
    if ([db openDatabase:pathToDatabase])
    {
      // Open the database - it already exists & is properly copied
      // TODO: pull this out
      PluginManager* pm = [[PluginManager alloc] init];
      BOOL success = [pm installPluginWithPath:[LWEFile createDocumentPathWithFilename:@"jFlash1_1_example_sentences.sqlite"]];
      
      // Add each plugin database if it exists
      NSMutableDictionary *plugins = [settings objectForKey:@"plugins"];
      NSEnumerator *keyEnumerator = [plugins keyEnumerator];
      NSString *key;
      while (key = [keyEnumerator nextObject])
      {
        NSString* filename = [LWEFile createDocumentPathWithFilename:[plugins objectForKey:key]];
        if ([[state pluginMgr] loadPluginFromFile:filename] == nil)
        {
          LWE_LOG(@"FAILED to load plugin: %@",filename);
        }
      }
    }
    [self performSelector:@selector(loadTabBar) withObject:nil afterDelay:0.0];
  }
}


/**
 * Programmatically creates a TabBarController and adds nav/view controllers for each tab item
 */
- (void) loadTabBar
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

  LWE_LOG(@"END Tab bar");
  
  //launch the please rate us
  [Appirater appLaunched];
}


/**
 * On first load - this shows the "setting up for first time" dialog, starts DB copy, and calls continueDatabaseCopy when finished
 */
- (void) showFirstLoadProgressView
{
  loadingView = [LoadingView loadingViewInView:self.view withText:@"Setting up jFlash for first time use. This might take a minute."];
  LWEDatabase *db = [LWEDatabase sharedLWEDatabase];
  NSString *pathToDatabase = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"jFlash.db"];
  [db performSelectorInBackground:@selector(openDatabase:) withObject:pathToDatabase];
  [self _continueDatabaseCopy];
} 


/**
 * Called continously by itself until DB copy is finished
 */
- (void) _continueDatabaseCopy
{
  LWEDatabase *db = [LWEDatabase sharedLWEDatabase];
  if (!db.databaseOpenFinished)
  {
    // Checks every 250 milliseconds to see if we are done
    [self performSelector:@selector(_continueDatabaseCopy) withObject:nil afterDelay:0.25];
  }
  else
  {
    [self _finishDatabaseCopy];
  }
}


/**
 * Cleanup once database is finished copying, removes "setup" dialog
 * If RootViewController has a delegate, it will call appInitDidComplete
 */
- (void) _finishDatabaseCopy
{
	if (loadingView)
  {
    [loadingView removeView];
	}		
	if (self.delegate != NULL && [self.delegate respondsToSelector:@selector(appInitDidComplete)])
  {
		[delegate appInitDidComplete];
	}
  [self loadTabBar];
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
