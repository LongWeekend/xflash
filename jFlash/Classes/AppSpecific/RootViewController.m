//
//  RootViewController.m
//  jFlash
//
//  Created by Mark Makdad on 2/20/10.
//  Copyright 2010 LONG WEEKEND INC.. All rights reserved.
//

#import "RootViewController.h"
#import "FlurryAPI.h"

#import "StudyViewController.h"
#import "StudySetViewController.h"
#import "SearchViewController.h"
#import "SettingsViewController.h"
#import "JapaneseSettingsDataSource.h"
#import "ChineseSettingsDataSource.h"
#import "HelpViewController.h"
#import "LWEPackageDownloader.h"
#import "ModalTaskViewController.h"

NSString * const LWEShouldShowModal				    = @"LWEShouldShowModal";
// TODO: Why is this different than the above?  (MMA 11.14.2011)
NSString * const LWEShouldShowDownloadModal	  = @"LWEShouldShowDownloadModal";
NSString * const LWEShouldDismissModal		   	= @"LWEShouldDismissModal";
NSString * const LWEShouldShowStudySetView    = @"LWEShouldShowStudySet";
NSString * const LWEShouldShowStudyView       = @"LWEShouldShowStudyView";
NSString * const LWEShouldShowPopover         = @"LWEShouldShowPopover";

@interface RootViewController ()
@property (retain) NSMutableArray *observerArray;
@end

/**
 * Takes UI hierarchy control from appDelegate and 
 * loads tab bar controller programmatically when loadTabBar is called
 * This is the top level view controller in the app
 */
@implementation RootViewController

@synthesize loadingView;
@synthesize tabBarController;
@synthesize isFinishedLoading;
@synthesize observerArray;

/**
 * Custom initializer - adds observers for notifications
 */
- (id)init
{
  if ((self = [super init]))
  {
    self.isFinishedLoading = NO;
    self.observerArray = [NSMutableArray array];
    
    // MMA Apparently, there really isn't a way around this dirtiness.
    __block UIViewController *blockSelf = self;
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    
    id observer = nil;

    // Register listener to switch the tab bar controller to user sets when user masters a set
    observer = [center addObserverForName:LWEShouldShowStudySetView object:nil queue:nil usingBlock:^(NSNotification *notification)
    {
      blockSelf.tabBarController.selectedIndex = STUDY_SET_VIEW_CONTROLLER_TAB_INDEX;
    }];
    [self.observerArray addObject:observer];
    
    // Register listener to switch the tab bar controller to the study view when the user selects a new set
    observer = [center addObserverForName:LWEShouldShowStudyView object:nil queue:nil usingBlock:^(NSNotification *notification)
     {
       blockSelf.tabBarController.selectedIndex = STUDY_VIEW_CONTROLLER_TAB_INDEX;
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
    observer = [center addObserverForName:@"taskDidCancelSuccessfully" object:nil queue:nil usingBlock:dismissBlock];
    [self.observerArray addObject:observer];

    observer = [center addObserverForName:@"taskDidCompleteSuccessfully" object:nil queue:nil usingBlock:dismissBlock];
    [self.observerArray addObject:observer];

    observer = [center addObserverForName:LWEShouldDismissModal object:nil queue:nil usingBlock:dismissBlock];
    [self.observerArray addObject:observer];
    
    // Update the settings tab bar item with badge number
    observer = [center addObserverForName:LWEShouldUpdateSettingsBadge object:nil queue:nil usingBlock:^(NSNotification *notification)
     {
       NSNumber *badgeNumber = [notification.userInfo objectForKey:@"badge_number"];
       UITabBarItem *settingsTabBar = [blockSelf.tabBarController.tabBar.items objectAtIndex:SETTINGS_VIEW_CONTROLLER_TAB_INDEX];
       if ([badgeNumber intValue] != 0)
       {
         settingsTabBar.badgeValue = [badgeNumber stringValue];
       }
       else 
       {
         settingsTabBar.badgeValue = nil;
       }
     }];
    [self.observerArray addObject:observer];
    
    // Show popover for progress view
    observer = [center addObserverForName:LWEShouldShowPopover object:nil queue:nil usingBlock:^(NSNotification *notification)
     {
       UIViewController *controller = (UIViewController *)[notification.userInfo objectForKey:@"controller"];
       if (controller)
       {
         [blockSelf.tabBarController.view addSubview:controller.view];
       }
     }];
    [self.observerArray addObject:observer];
    
    // Register listener to pop up downloader modal for search FTS download & ex sentence download
    [center addObserver:self selector:@selector(showDownloaderModal:) name:LWEShouldShowDownloadModal object:nil];
    
    //Register the generic show modal, and dismiss modal notification which can be used by any view controller.
    [center addObserver:self selector:@selector(showModal:) name:LWEShouldShowModal object:nil];
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
  aView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:LWE_APP_SPLASH_IMAGE]];
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
  
  StudySetViewController *studySetViewController = [[StudySetViewController alloc] initWithGroup:[GroupPeer topLevelGroup]];
  localNavigationController = [[UINavigationController alloc] initWithRootViewController:studySetViewController];
  [localControllersArray addObject:localNavigationController];
  [studySetViewController release];
  [localNavigationController release];
  
  SearchViewController *searchViewController = [[SearchViewController alloc] init];
  localNavigationController = [[UINavigationController alloc] initWithRootViewController:searchViewController];
  [localControllersArray addObject:localNavigationController];
  [searchViewController release];
  [localNavigationController release];
  
  SettingsViewController *settingsViewController = [[SettingsViewController alloc] initWithNibName:@"SettingsView" bundle:nil];
#if defined(LWE_JFLASH)
  settingsViewController.dataSource = [[[JapaneseSettingsDataSource alloc] init] autorelease];
#elif defined(LWE_CFLASH)
  settingsViewController.dataSource = [[[ChineseSettingsDataSource alloc] init] autorelease];
#endif
  settingsViewController.delegate = (id<LWESettingsDelegate>)settingsViewController.dataSource;
  
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
  [self.view addSubview:self.tabBarController.view];
  
  // Get rid of the splash image beneath
  self.view.backgroundColor = [UIColor blackColor];

  //launch the please rate us
  [Appirater appLaunched];
  
  // We're done!
  self.isFinishedLoading = YES;
}


# pragma mark Convenience Methods

//! Called via first responder from progress view
- (IBAction)switchToSettings
{
  self.tabBarController.selectedIndex = SETTINGS_VIEW_CONTROLLER_TAB_INDEX;
}

- (void) switchToSearchWithTerm:(NSString*)term
{
  self.tabBarController.selectedIndex = SEARCH_VIEW_CONTROLLER_TAB_INDEX;

  // TODO: this is a little ghetto. Maybe a Notification is more appropriate?
  UINavigationController *vc = (UINavigationController*)[self.tabBarController selectedViewController];
  if ([vc isKindOfClass:[UINavigationController class]])
  {
    SearchViewController *searchVC = (SearchViewController*)[vc topViewController];
    if ([searchVC isKindOfClass:[SearchViewController class]])
    {
      [searchVC runSearchAndSetSearchBarForString:term];
    }
    else
    {
      [LWEUIAlertView notificationAlertWithTitle:NSLocalizedString(@"Unable to load Search",@"Unable to load Search")
                                         message:NSLocalizedString(@"An unexpected error occurred.  Gawd I hate these kinds of errors.  Always when I never expect it.",@"foobar")];
    }
  }
  else
  {
    [LWEUIAlertView notificationAlertWithTitle:NSLocalizedString(@"Unable to load Search Nav",@"Unable to load Search")
                                       message:NSLocalizedString(@"An unexpected error occurred.  Gawd I hate these kinds of errors.  Always when I never expect it.",@"foobar")];
  }
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
 * Pops up a modal over the screen when the user needs to download something
 * Relies on _showModalWithViewController:useNavController:
 */
- (void) showDownloaderModal:(NSNotification*)aNotification
{
  Plugin *thePlugin = (Plugin *)aNotification.object;
  LWE_ASSERT_EXC(thePlugin, @"This method can't be called with a nil plugin.");

  // Instantiate downloader with jFlash download URL & destination filename
  //TODO: iPad customization here
  ModalTaskViewController *dlViewController = [[ModalTaskViewController alloc] initWithNibName:@"ModalTaskView" bundle:nil];
  dlViewController.title = NSLocalizedString(@"Get Update",@"ModalTaskViewController_Update.NavBarTitle");
  dlViewController.webViewContent = thePlugin.htmlString;

  // Get path information
  LWEPackageDownloader *packageDownloader = [[LWEPackageDownloader alloc] initWithDownloaderDelegate:[CurrentState sharedCurrentState]];
  packageDownloader.progressDelegate = dlViewController;
  [packageDownloader queuePackage:[thePlugin downloadPackage]];
  dlViewController.taskHandler = packageDownloader;
  [self _showModalWithViewController:dlViewController useNavController:YES];
  [packageDownloader release];
  
  // Hold on to this
  [[CurrentState sharedCurrentState] setModalTaskViewController:dlViewController];
  [dlViewController release];
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

# pragma mark Housekeeping

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
  [loadingView release];
  [super dealloc];
}

@end
