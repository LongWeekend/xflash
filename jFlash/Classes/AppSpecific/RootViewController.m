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
    // Register listener to switch the tab bar controller when the user selects a new set
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(switchToStudyView) name:@"switchToStudyView" object:nil];

    // Register listener to pop up downloader modal for search FTS download & ex sentence download
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showDownloaderModal:) name:@"shouldShowDownloaderModal" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hideDownloaderModal:) name:@"taskDidCompleteSuccessfully" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showUpdaterModal) name:@"shouldShowUpdaterModal" object:nil];
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

  //launch the please rate us
  [Appirater appLaunched];
}


# pragma mark Convenience Methods for Notifications

/** Switches active view to study view, convenience method for notification */
- (void) switchToStudyView
{
  [tabBarController setSelectedIndex:STUDY_VIEW_CONTROLLER_TAB_INDEX]; 
}

- (IBAction) switchToSettings
{
  [tabBarController setSelectedIndex:SETTINGS_VIEW_CONTROLLER_TAB_INDEX]; 
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
  // let everyone know we did this.  Delegate notifcations like souldHide... should be followed by a ...DidHide
  //[[NSNotificationCenter defaultCenter] postNotificationName:@"taskDidCompleteSuccessfully" object:nil];
}


# pragma mark Delegate Methods

-(void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	[tabBarController viewWillAppear:animated];
}

- (void) viewDidAppear:(BOOL)animated
{
  [super viewDidAppear:animated];
  [tabBarController viewDidAppear:animated];
}

-(void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
	[tabBarController viewWillDisappear:animated];
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
}


- (void)dealloc
{
  // Unobserve notifications
	[[NSNotificationCenter defaultCenter] removeObserver:self];
  [self setTabBarController:nil];
  [self setLoadingView:nil];
  [super dealloc];
}

@end
