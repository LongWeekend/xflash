//
//  RootViewController.m
//  jFlash
//
//  Created by Mark Makdad on 2/20/10.
//  Copyright 2010 LONG WEEKEND INC.. All rights reserved.
//

#import "RootViewController.h"
#import "VersionManager.h"

NSString * const LWEShouldUpdateSettingsBadge	= @"LWEShouldUpdateSettingsBadge";
NSString * const LWEShouldShowModal				= @"LWEShouldShowModal";
NSString * const LWEShouldDismissModal			= @"LWEShouldDismissModal";

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
  if ((self = [super init]))
  {
    // Register listener to switch the tab bar controller when the user selects a new set
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(switchToStudyView) name:@"switchToStudyView" object:nil];

    // Register listener to pop up downloader modal for search FTS download & ex sentence download
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showDownloaderModal:) name:@"shouldShowDownloaderModal" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hideDownloaderModal:) name:@"taskDidCancelSuccessfully" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hideDownloaderModal:) name:@"taskDidCompleteSuccessfully" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showUpdaterModal) name:@"shouldShowUpdaterModal" object:nil];
	
    //Register the generic show modal, and dismiss modal notification which can be used by any view controller.  
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showModal:) name:LWEShouldShowModal object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dismissModal:) name:LWEShouldDismissModal object:nil];

		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changeSettingsBadge:) name:LWEShouldUpdateSettingsBadge object:nil];
  }
	return self;
}

/**
 * Loads the jFlash logo splash screen and calls the database loader when finished
 */
- (void) loadView
{
  // Make the main view the themed splash screen
  UIView *aView = [[UIView alloc] initWithFrame:[UIScreen mainScreen].applicationFrame];
  // TODO: iPad customization HERE?
  NSString *pathToSplashImage = [[ThemeManager sharedThemeManager] elementWithCurrentTheme:APP_SPLASH_IMAGE];
  aView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:pathToSplashImage]];
  self.view = aView;
  [aView release];
}  


//! Shows the "database loading" view on top of the splash screen
- (void) showDatabaseLoadingView
{
  self.loadingView = [LWELoadingView loadingView:self.view withText:NSLocalizedString(@"Setting up for first time use. This might take a minute.",@"RootViewController.FirstLoadModalText")];
}


//! Hides the "database loading" view
- (void) hideDatabaseLoadingView
{
  if (self.loadingView)
  {
    [self.loadingView removeFromSuperview];
  }
}


/**
 * Programmatically creates a TabBarController and adds nav/view controllers for each tab item
 */
- (void) loadTabBar
{
	self.tabBarController = [[[UITabBarController alloc] init] autorelease];
  
  // Make room for the status bar
  CGRect tabBarFrame;
  tabBarFrame = [[UIScreen mainScreen] bounds];
  tabBarFrame.size.height = tabBarFrame.size.height - 20;

  //TODO: iPad customization here
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
  
  self.tabBarController.viewControllers = localControllersArray;
	[localControllersArray release];

  // Replace active view with tabBarController's view
  self.view = self.tabBarController.view;

  //launch the please rate us
  [Appirater appLaunched];
}


# pragma mark Convenience Methods for Notifications

/** Switches active view to study view, convenience method for notification */
- (void) switchToStudyView
{
  [self.tabBarController setSelectedIndex:STUDY_VIEW_CONTROLLER_TAB_INDEX]; 
}

- (IBAction) switchToSettings
{
  [self.tabBarController setSelectedIndex:SETTINGS_VIEW_CONTROLLER_TAB_INDEX]; 
}


#pragma mark -
#pragma mark Generic Modal Pop-ups and dismissal. 

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
	if ((dict != nil) && ([dict count] > 0))
	{
		UIViewController *vc = (UIViewController *) [dict objectForKey:@"controller"];

    // Default to YES
    BOOL useNavController = YES;
    if ([dict valueForKey:@"useNavController"])
    {
      useNavController = [[dict valueForKey:@"useNavController"] boolValue];
    }
		[self _showModalWithViewController:vc useNavController:useNavController];
	}
	else 
	{
		LWE_LOG(@"Error : Show modal notification cannot run properly, caused by nil or zero length of NSNotification user info dictionary. ");
	}
}

/**
 * Dismiss the modal view controller. The default for animated key is YES.
 */
- (void)dismissModal:(NSNotification *)notification
{
  NSDictionary *dict = [notification userInfo];
	//if the animated key is not specified in the user info, it will be animated.
  BOOL animated = YES;
  if ([dict valueForKey:@"animated"])
  {
    animated = [[dict valueForKey:@"animated"] boolValue];
  }
	[self.tabBarController dismissModalViewControllerAnimated:animated];
}

#pragma mark -


/**
 * Pops up a modal over the screen when the user is updating versions
 * Can be used to view release notes only
 */
- (void) showUpdaterModal
{
  //TODO: iPad customization here
  ModalTaskViewController *updateVC = [[ModalTaskViewController alloc] initWithNibName:@"ModalTaskView" bundle:nil];
  [updateVC setTitle:NSLocalizedString(@"Get Update",@"ModalTaskViewController_Update.NavBarTitle")];
  [[NSNotificationCenter defaultCenter] addObserver:updateVC selector:@selector(updateDisplay) name:@"MigraterStateUpdated" object:nil];
  // Set task parameters
  [updateVC setShowDetailedViewOnAppear:YES];
  [updateVC setStartTaskOnAppear:NO];
  [updateVC setWebViewContentDirectory:@"plugin-resources"];
  [updateVC setWebViewContentFileName:@"release-notes-1.1"];
  VersionManager *tmpVm = [[VersionManager alloc] init];
  [updateVC setTaskHandler:tmpVm];
  [tmpVm release];
  [self _showModalWithViewController:updateVC useNavController:YES];
  [updateVC release];
}

/**
 * Update the settings tab bar item with badge number
 */
-(void)changeSettingsBadge:(NSNotification*)aNotification
{
  NSNumber *badgeNumber = [[aNotification userInfo] objectForKey:@"badge_number"];
  NSArray *tabBarItems = [[self.tabBarController tabBar] items];
  // TODO: change this to a constant later
  UITabBarItem *settingsTabBar = [tabBarItems objectAtIndex:3];
	if ([badgeNumber intValue] != 0)
  {
		[settingsTabBar setBadgeValue:[badgeNumber stringValue]];
  }
  else 
  {
		[settingsTabBar setBadgeValue:nil];
  }
}


/**
 * Pops up a modal over the screen when the user needs to download something
 * Relies on _showModalWithViewController:useNavController:
 */
- (void) showDownloaderModal:(NSNotification*)aNotification
{
  // Instantiate downloader with jFlash download URL & destination filename
  //TODO: iPad customization here
  ModalTaskViewController* dlViewController = [[ModalTaskViewController alloc] initWithNibName:@"ModalTaskView" bundle:nil];
  //[dlViewController setTitle:[[aNotification userInfo] objectForKey:@"plugin_name"]];
  [dlViewController setTitle:NSLocalizedString(@"Get Update",@"ModalTaskViewController_Update.NavBarTitle")];
  [dlViewController setShowDetailedViewOnAppear:YES];
  [dlViewController setStartTaskOnAppear:NO];
  
  // Use HTML from PLIST if we have it
  NSString *htmlString = [[aNotification userInfo] objectForKey:@"plugin_html_content"];
  if (htmlString)
  {
    [dlViewController setWebViewContent:htmlString];
  }
  else
  {
    [dlViewController setWebViewContentDirectory:[[aNotification userInfo] objectForKey:@"plugin_notes_dir"]];
    [dlViewController setWebViewContentFileName:[[aNotification userInfo] objectForKey:@"plugin_notes_file"]];
    LWE_LOG(@"Loading web view w/ file: %@",[dlViewController webViewContentDirectory]);
    LWE_LOG(@"Loading web view w/ file: %@",[dlViewController webViewContentFileName]);
  }
  NSString *targetURL  = [[aNotification userInfo] objectForKey:@"plugin_target_url"];
  NSString *targetPath = [[aNotification userInfo] objectForKey:@"plugin_target_path"];
  LWEDownloader *tmpDlHandler = [[LWEDownloader alloc] initWithTargetURL:targetURL targetPath:targetPath];
   
  // Set the installer delegate to the PluginManager class
  [tmpDlHandler setDelegate:[[CurrentState sharedCurrentState] pluginMgr]];
  [dlViewController setTaskHandler:tmpDlHandler];
  
  // Register notification listener to handle downloader events
	[[NSNotificationCenter defaultCenter] addObserver:dlViewController selector:@selector(updateDisplay) name:@"LWEDownloaderStateUpdated" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:dlViewController selector:@selector(updateDisplay) name:@"LWEDownloaderProgressUpdated" object:nil];
  
  [self _showModalWithViewController:dlViewController useNavController:YES];
  [dlViewController release];
  
  // TODO: Am I not leaking tmpDlHandler here?? MMA 10.11.2010
}


/** Hides the downloader */
- (void) hideDownloaderModal:(NSNotification*)aNotification
{
  [self.tabBarController dismissModalViewControllerAnimated:YES];
  // let everyone know we did this.  Delegate notifcations like souldHide... should be followed by a ...DidHide
  //[[NSNotificationCenter defaultCenter] postNotificationName:@"taskDidCompleteSuccessfully" object:nil];
}


# pragma mark Delegate Methods

-(void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	[self.tabBarController viewWillAppear:animated];
}

- (void) viewDidAppear:(BOOL)animated
{
  [super viewDidAppear:animated];
  [self.tabBarController viewDidAppear:animated];
}

-(void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
	[self.tabBarController viewWillDisappear:animated];
}


-(void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
	[self.tabBarController viewDidDisappear:animated];
}

- (void) viewDidUnload
{
  [super viewDidUnload];
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

# pragma mark Housekeeping

- (void)dealloc
{
  // Unobserve notifications
  [tabBarController release];
  [self setLoadingView:nil];
  [super dealloc];
}

@end
