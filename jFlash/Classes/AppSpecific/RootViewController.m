//
//  RootViewController.m
//  jFlash
//
//  Created by Mark Makdad on 2/20/10.
//  Copyright 2010 LONG WEEKEND INC.. All rights reserved.
//

#import "RootViewController.h"

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
  }
	return self;
}

/**
 * Loads the jFlash logo splash screen and calls the database loader when finished
 */
- (void) loadView
{
  // Splash screen
  NSString* tmpStr = [[NSString alloc] initWithFormat:@"/%@theme-cookie-cutters/Default.png",[CurrentState getThemeName]];
  UIView *view = [[UIView alloc] initWithFrame:[UIScreen mainScreen].applicationFrame];
  view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:tmpStr]];
  [tmpStr release];
  self.view = view;
  [view release];
  
  // Database work next, but put delay so we can update the UIKIT with the splash screen
  [self performSelector:@selector(loadDatabase) withObject:nil afterDelay:0.1];
}  


/**
 * Loads & opens the database (including if it doesn't exist), calls loadTabBar when finished
 */
- (void) loadDatabase
{
  // Determine if the database exists or not
  NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
  CurrentState *appSettings = [CurrentState sharedCurrentState];
  LWEDatabase *db = [LWEDatabase sharedLWEDatabase];
  NSString* pathToDatabase = [LWEFile createDocumentPathWithFilename:@"jFlash.db"];
  [appSettings initializeSettings];
  bool dbDidFinishCopying = [settings boolForKey:@"db_did_finish_copying"];
  if (appSettings.isFirstLoad || ![db databaseFileExists:pathToDatabase] || !dbDidFinishCopying)
  {
    // Load the "waiting" view for the new database copy
    [self showFirstLoadProgressView];
  }
  else
  {
    // Open the database - it already exists & is properly copied - then add FTS database if possible
    [db openedDatabase:pathToDatabase];
    
    // TODO: This is the FTS database - somehow change this later
    NSString *pathToFTSDatabase = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"jFlashFTS.db"];
    [db attachDatabase:pathToFTSDatabase withName:@"fts"];

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
  
  CurrentState *appSettings = [CurrentState sharedCurrentState];
  [appSettings loadActiveTag];
  
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
  
  SearchViewController *searchViewController = [[SearchViewController alloc] init];
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
  [db performSelectorInBackground:@selector(openedDatabase:) withObject:pathToDatabase];
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

// Switches active view to study view
- (void) switchToStudyView
{
  [tabBarController setSelectedIndex:STUDY_VIEW_CONTROLLER_TAB_INDEX]; 
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

- (void) applicationWillTerminate:(UIApplication*)application
{
  // Get current card from StudyViewController
  StudyViewController* studyCtl = [tabBarController.viewControllers objectAtIndex:STUDY_VIEW_CONTROLLER_TAB_INDEX];
  
  // Save current card, user, and set, update cache
  CurrentState *appSettings = [CurrentState sharedCurrentState];
  
  NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
  [settings setInteger:studyCtl.currentCard.cardId forKey:@"card_id"];
  [settings setInteger:appSettings.activeTag.tagId forKey:@"tag_id"];
  [settings setInteger:appSettings.activeTag.currentIndex forKey:@"current_index"];
  [settings setInteger:0 forKey:@"first_load"];
  [settings setInteger:0 forKey:@"app_running"];
  [settings synchronize];
  
  // Only freeze if we have a database
  if ([[LWEDatabase sharedLWEDatabase] dao]) [[appSettings activeTag] freezeCardIds];
}


- (void)dealloc
{
  // Clear the application settings singleton
  CurrentState* appSettings = [CurrentState sharedCurrentState];
  LWEDatabase *db = [LWEDatabase sharedLWEDatabase];
  [db release];
  [appSettings release];

  [super dealloc];
}

@end
