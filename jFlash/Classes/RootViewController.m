//
//  RootViewController.m
//  jFlash
//
//  Created by Mark Makdad on 2/20/10.
//  Copyright 2010 LONG WEEKEND INC.. All rights reserved.
//

#import "CurrentState.h"
#import "RootViewController.h"
#import "StudyViewController.h"
#import "StudySetViewController.h"
#import "SearchViewController.h"
#import "SettingsViewController.h"
#import "HelpViewController.h"
#import "PDColoredProgressView.h"
#import "SplashView.h"
#import "Appirater.h"
#import "Constants.h"

#define PROFILE_SQL_STATEMENTS 0
#if (PROFILE_SQL_STATEMENTS)
#import "LWESQLDebug.h"
#endif

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


- (void) loadView
{
  LWE_LOG(@"START Load View");
  UIView *view = [[UIView alloc] initWithFrame:[UIScreen mainScreen].applicationFrame];
  
  CurrentState *appSettings = [CurrentState sharedCurrentState];
  LWEDatabase *db = [LWEDatabase sharedLWEDatabase];
  [appSettings initializeSettings];
  
  if (appSettings.isFirstLoad || ![db databaseFileExists])
  {
    // Is first load, copy database splash screen
    NSString* tmpStr = [[NSString alloc] initWithFormat:@"/%@theme-cookie-cutters/Default.png",[CurrentState getThemeName]];
    view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:tmpStr]];
    [tmpStr release];
    self.view = view;
    [view release];
    [self performSelector:@selector(showFirstLoadProgressView) withObject:nil afterDelay:0.1];
  }
  else if ([appSettings splashIsOn])
  {
    // Not first load, splash screen
    NSString* tmpStr = [[NSString alloc] initWithFormat:@"/%@theme-cookie-cutters/Default.png",[CurrentState getThemeName]];
    SplashView *mySplash = [[SplashView alloc] initWithImage:[UIImage imageNamed:tmpStr]];
    [tmpStr release];
    mySplash.animation = SplashViewAnimationFade;
    mySplash.delay = 3;
    mySplash.touchAllowed = YES;
    mySplash.delegate = nil;
    [mySplash startSplash:YES];
    [mySplash release];
    self.view = view;
    [view release];
    [self performSelector:@selector(doAppInit) withObject:nil afterDelay:0.1];
  }
  else
  {
    // Not first load, no splash screen
    view.backgroundColor = [UIColor blackColor];
    self.view = view;
    [view release];
    [self performSelector:@selector(doAppInit) withObject:nil afterDelay:0.1];
  }
  LWE_LOG(@"END Loading Splash");
}

- (void) doAppInit
{
  LWE_LOG(@"START app init");
  
  // Get app settings singleton
  LWEDatabase *db = [LWEDatabase sharedLWEDatabase];  
  if ([db openedDatabase])
  {
      // We are OK to go
#if (PROFILE_SQL_STATEMENTS)
      NSArray* statements = [[NSArray alloc] initWithObjects:
           [NSString stringWithFormat:@"SELECT card_id FROM card_tag_link WHERE tag_id = '%d'",199],
           [NSString stringWithFormat:@"SELECT card_id FROM card_tag_link WHERE tag_id = '%d'",199],
           [NSString stringWithFormat:@"SELECT l.card_id AS card_id,u.card_level as card_level,u.wrong_count as wrong_count,u.right_count as right_count FROM card_tag_link l, user_history u WHERE u.card_id = l.card_id AND l.tag_id = '%d' AND u.user_id = '%d'",199,1],
           [NSString stringWithFormat:@"SELECT l.card_id AS card_id,u.card_level as card_level FROM card_tag_link l, user_history u WHERE u.card_id = l.card_id AND l.tag_id = '%d' AND u.user_id = '%d'",199,1],
           nil
      ];
      [LWESQLDebug profileSQLStatements:statements];
#endif
  }
  [self loadTabBar];
}

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
  [localControllersArray addObject:helpViewController];
  [helpViewController release];
  
  tabBarController.viewControllers = localControllersArray;
	[localControllersArray release];

  // Replace active view with tabBarController's view
  self.view = tabBarController.view;

  LWE_LOG(@"END Tab bar");
  
  //launch the please rate us
  [Appirater appLaunched];

}

// On first load when copying the database
- (void) showFirstLoadProgressView
{
  loadingView = [[PDColoredProgressView alloc] initWithProgressViewStyle: UIProgressViewStyleDefault];
  [loadingView setTintColor:[UIColor yellowColor]];
  CGRect viewFrame = loadingView.frame;
  viewFrame.origin.x = 81;
  viewFrame.origin.y = 412;
  loadingView.frame = viewFrame;

  [self.view addSubview:loadingView];
  [self startDatabaseCopy];
} 

- (void) startDatabaseCopy
{
  LWEDatabase *db = [LWEDatabase sharedLWEDatabase];
  [db performSelectorInBackground:@selector(openedDatabase) withObject:nil];
  [self continueDatabaseCopy];
}

- (void) continueDatabaseCopy
{
  LWEDatabase *db = [LWEDatabase sharedLWEDatabase];
  if (!db.databaseOpenFinished)
  {
    float k = ((float)i/150.0f);
    LWE_LOG(@"float val : %f %d",k,i);
    [[self loadingView] setProgress:k];
    i++;
    [self performSelector:@selector(continueDatabaseCopy) withObject:nil afterDelay:0.25];
  }
  else
  {
    [[self loadingView] setProgress:1.0f];
    [self performSelector:@selector(finishDatabaseCopy) withObject:nil afterDelay:0.1];
  }
}

- (void) finishDatabaseCopy
{
	if (loadingView)
  {
		[loadingView removeFromSuperview];
		[loadingView release];
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

- (void) applicationWillTerminate
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
  
  [[appSettings activeTag] freezeCardIds];
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
