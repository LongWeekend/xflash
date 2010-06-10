//
//  RootViewController.m
//  jFlash
//
//  Created by Mark Makdad on 2/20/10.
//  Copyright 2010 LONG WEEKEND INC.. All rights reserved.
//

#import "RootViewController.h"
#import "VersionManager.h"

/**
 * Takes UI hierarchy control from appDelegate and 
 * loads tab bar controller programmatically when loadTabBar is called
 * This is the top level view controller in the app
 */
@implementation RootViewController

@synthesize loadingView;
@synthesize tabBarController;

/**
 * Custom initializer - adds observers for notifications
 */
- (id)init
{
  if (self = [super init])
  {
    // Should show "welcome to JFlash alert view if first load?
    _showWelcomeSplash = NO;
    
    // Register listener to switch the tab bar controller when the user selects a new set
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(switchToStudyView) name:@"switchToStudyView" object:nil];

    // Register listener to pop up downloader modal for search FTS download & ex sentence download
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showDownloaderModal:) name:@"shouldShowDownloaderModal" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hideDownloaderModal:) name:@"shouldHideDownloaderModal" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(swapSearchViewController) name:@"shouldSwapSearchViewController" object:nil];
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
}  


//! Shows the "database loading" view on top of the splash screen
- (void) showDatabaseLoadingView
{
  loadingView = [LoadingView loadingViewInView:self.view withText:NSLocalizedString(@"Setting up jFlash for first time use. This might take a minute.",@"RootViewController.FirstLoadModalText")];
}


//! Hides the "database loading" view
- (void) hideDatabaseLoadingView
{
	if (loadingView)
  {
    [loadingView removeView];
	}
}


/**
 * Programmatically creates a TabBarController and adds nav/view controllers for each tab item
 */
- (void) loadTabBar
{
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

  //launch the please rate us
  [Appirater appLaunched];

  // Show a UIAlert if this is the first time the user has launched the app.
  CurrentState *appSettings = [CurrentState sharedCurrentState];
  if (appSettings.isFirstLoad && _showWelcomeSplash)
  {
    UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Welcome to Japanese Flash!",@"RootViewController.WelcomeAlertViewTitle")
                                                  message:NSLocalizedString(@"To get you started, we've loaded our favorite words as an example set.   To study other sets, tap the 'Study Sets' icon below.",@"RootViewController.WelcomeAlertViewMessage")
                                                  delegate:self
                                                  cancelButtonTitle:NSLocalizedString(@"OK",@"Global.OK") otherButtonTitles:nil];
    [alertView show];
    [alertView release];
    _showWelcomeSplash = NO;
  }
  else if (appSettings.isFirstLoadAfterNewVersion || 1)
  {
    UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"The New Japanese Flash!",@"RootViewController.UpdateAlertViewTitle")
                                                  message:NSLocalizedString(@"JFlash has grown up!  In this version, we've improved the database and added new, great features.  Sometime soon, we need about 3 minutes of your time and a network (Wifi or 3G) connection to update your data (you won't lose your progress).  Want to do it now?",@"RootViewController.UpdateAlertViewMessage")
                                                  delegate:self
                                                  cancelButtonTitle:NSLocalizedString(@"Update Later",@"RootViewController.UpdateAlertViewButton_UpdateLater")
                                                  otherButtonTitles:NSLocalizedString(@"Update Now",@"RootViewController.UpdateAlertViewButton_UpdateNow"),nil];
    [alertView show];
    [alertView release];
  }
}


#pragma mark UIAlertView delegate methods

/** UIAlertView delegate - takes action based on which button was pressed */
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
  switch (buttonIndex)
  {
    case UPDATE_ALERT_UPDATE_NOW_BUTTON:
      [self showUpdaterModal];
      break;
    // Do nothing
    case UPDATE_ALERT_CANCEL_BUTTON:
      break;
  }
}


# pragma mark Convenience Methods for Notifications

/** Switches active view to study view, convenience method for notification */
- (void) switchToStudyView
{
  [tabBarController setSelectedIndex:STUDY_VIEW_CONTROLLER_TAB_INDEX]; 
}


/**
 * Private method that actually does the dirty work of displaying any modal
 */
- (void) _showModalWithViewController:(UIViewController*)vc useNavController:(BOOL)useNavController
{
  if (useNavController)
  {
    UINavigationController *controller = [[UINavigationController alloc] initWithRootViewController:vc];
    [[self tabBarController] presentModalViewController:controller animated:YES];
    [controller release];
  }
  else
  {
    [[self tabBarController] presentModalViewController:vc animated:YES];    
  }
}


/**
 * Pops up a modal over the screen when the user is updating versions
 * Can be used to view release notes only
 */
- (void) showUpdaterModal
{
  ModalTaskViewController *updateVC = [[ModalTaskViewController alloc] initWithNibName:@"ModalTaskView" bundle:nil];
  [updateVC setTitle:NSLocalizedString(@"Update Dictionary",@"ModalTaskViewController_Update.NavBarTitle")];
  [[NSNotificationCenter defaultCenter] addObserver:updateVC selector:@selector(updateDisplay) name:@"MigraterStateUpdated" object:nil];
  // Set task parameters
  [updateVC setShowDetailedViewOnAppear:YES];
  [updateVC setStartTaskOnAppear:NO];
  [updateVC setWebViewContentFile:@"release-notes"];
  VersionManager *tmpVm = [[VersionManager alloc] init];
  [updateVC setTaskHandler:tmpVm];
  [tmpVm release];
  [self _showModalWithViewController:updateVC useNavController:YES];
  [updateVC release];
}


/**
 * Pops up a modal over the screen when the user needs to download something
 * Relies on _showModalWithViewController:useNavController:
 */
- (void) showDownloaderModal:(NSNotification*)aNotification
{
  // Instantiate downloader with jFlash download URL & destination filename
  ModalTaskViewController* dlViewController = [[ModalTaskViewController alloc] initWithNibName:@"ModalTaskView" bundle:nil];
  [dlViewController setTitle:[[aNotification userInfo] objectForKey:@"plugin_name"]];
  [dlViewController setShowDetailedViewOnAppear:YES];
  [dlViewController setStartTaskOnAppear:NO];
  [dlViewController setWebViewContentFile:[[aNotification userInfo] objectForKey:@"plugin_notes_file"]];
  LWE_LOG(@"Loading web view w/ file: %@",[dlViewController webViewContentFile]);
  NSString *targetURL  = [[aNotification userInfo] objectForKey:@"target_url"];
  NSString *targetPath = [[aNotification userInfo] objectForKey:@"target_path"];
  LWEDownloader *tmpDlHandler = [[LWEDownloader alloc] initWithTargetURL:targetURL targetPath:targetPath];
   
  // Set the installer delegate to the PluginManager class
  [tmpDlHandler setDelegate:[[CurrentState sharedCurrentState] pluginMgr]];
  [dlViewController setTaskHandler:tmpDlHandler];
  
  // Register notification listener to handle downloader events
	[[NSNotificationCenter defaultCenter] addObserver:dlViewController selector:@selector(updateDisplay) name:@"LWEDownloaderStateUpdated" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:dlViewController selector:@selector(updateDisplay) name:@"LWEDownloaderProgressUpdated" object:nil];
  
  [self _showModalWithViewController:dlViewController useNavController:YES];
  [dlViewController release];
}


/** Hides the downloader */
- (void) hideDownloaderModal:(NSNotification*)aNotification
{
  [[self tabBarController] dismissModalViewControllerAnimated:YES];
}


//! Changes the middle tab bar to searchViewController
- (void) swapSearchViewController
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

/**
 * Delegate method of UIApplication (via AppDelegate); called on shutdown
 * TODO: review why this happens here? MMA 6/5/2010
 */
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
  [settings synchronize];
  
  // Only freeze if we have a database
  if ([[LWEDatabase sharedLWEDatabase] dao]) [[state activeTag] freezeCardIds];
}


- (void)dealloc
{
  // Unobserve notifications
	[[NSNotificationCenter defaultCenter] removeObserver:self];
  [super dealloc];
}

@end
