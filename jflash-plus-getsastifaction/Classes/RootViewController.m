//
//  RootViewController.m
//  jFlash
//
//  Created by Mark Makdad on 2/20/10.
//  Copyright 2010 LONG WEEKEND INC.. All rights reserved.
//

#import "RootViewController.h"
#import "StudyViewController.h"
#import "StudySetViewController.h"
#import "SearchViewController.h"
#import "SettingsViewController.h"
#import "HelpViewController.h"


@implementation RootViewController

@synthesize delegate;
@synthesize loadingView;
@synthesize i;


- (void) loadView
{
  UIView *contentView = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];
	contentView.backgroundColor = [UIColor darkGrayColor];
	self.view = contentView;
	[contentView release];
  
  
	UITabBarController *tabBarController;
	tabBarController = [[UITabBarController alloc] init];

  UINavigationController *localNavigationController;
	NSMutableArray *localControllersArray = [[NSMutableArray alloc] initWithCapacity:5];

  // How should we init this?
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
  
  
  /*

   
   // create the nav controller and add the root view controller as its first view
   UINavigationController *localNavigationController;
   localNavigationController = [[UINavigationController alloc] initWithRootViewController:firstViewController];
	
	// add the new nav controller (with the root view controller inside it)
	// to the array of controllers
	[localControllersArray addObject:localNavigationController];
	
	// release since we are done with this for now
	[localNavigationController release];
	[firstViewController release];
	
	// setup the second view controller just like the first
	SecondViewController *secondViewController;
	secondViewController = [[SecondViewController alloc] initWithTabBar];
	localNavigationController = [[UINavigationController alloc] initWithRootViewController:secondViewController];
	[localControllersArray addObject:localNavigationController];
	[localNavigationController release];
	[secondViewController release];
	
	// load up our tab bar controller with the view controllers
	tabBarController.viewControllers = localControllersArray;
	[localControllersArray release];
	
	// give the tabBarController view a tag so we can retrieve it later.
	tabBarController.view.tag = 1996;
	[self.view addSubview:tabBarController.view];
	
	// create the view to show without the tab bar.  For this example just assume it is the 
	// secondViewController (the "Edit" view).  We could also do this without a nav controller
	UINavigationController *secondNavController;
	SecondViewController *newViewController;
	// notice we use initWithStyle here instead of initWithTabBar
	newViewController = [[SecondViewController alloc] initWithStyle:UITableViewStylePlain];
	secondNavController = [[UINavigationController alloc] initWithRootViewController:newViewController];
	secondNavController.view.tag = 1997;
	// make the frame size the same as the one we are replacing (with the tab bar)
	CGRect navControllerFrame;
	navControllerFrame = CGRectMake(0, 260, 320, 200);
	secondNavController.view.frame = navControllerFrame;
	// hide this view initially
	[secondNavController.view setHidden:YES];
	// make the tab bar red - you can comment this line out if you don't like it
	secondNavController.navigationBar.tintColor = [UIColor redColor];
	[self.view addSubview:secondNavController.view];
	[newViewController release];
	
	NSArray *arrayOfSubViews;
	arrayOfSubViews = [self.view subviews];
	
	NSLog(@"There are %d subviews", [arrayOfSubViews count]);
*/  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
}

- (id)init
{
  if (self = [super init])
  {
    NSString* tmpStr = [[NSString alloc] initWithFormat:@"/%@theme-cookie-cutters/Default.png",[ApplicationSettings getThemeName]];
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:tmpStr]];
    [tmpStr release];
    i = 0;
  }
  
  // Get the notification for dismissing this view
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dismissView) name:@"databaseOpened" object:nil];
    
	return self;
}

- (void)startView
{
  // Set up the window
	[[[[UIApplication sharedApplication] windows] objectAtIndex:0] addSubview:self.view];

  loadingView = [[PDColoredProgressView alloc] initWithProgressViewStyle: UIProgressViewStyleDefault];
  [loadingView setTintColor:[UIColor yellowColor]]; //or any other color you like

  CGRect viewFrame = loadingView.frame;
  viewFrame.origin.x = 81;
  viewFrame.origin.y = 412;
  loadingView.frame = viewFrame;
	[self.view addSubview:loadingView];
  
  // Copy the database
  ApplicationSettings *appSettings = [ApplicationSettings sharedApplicationSettings];
  [appSettings performSelectorInBackground:@selector(openedDatabase) withObject:nil];
//  [appSettings openedDatabase];
  [self checkIfDoneYet];
  
}

- (void) checkIfDoneYet
{
  if (i < 15)
  {
    float k = ((float)i/15.0f);
    LWE_LOG(@"float val : %f %d",k,i);
    [[self loadingView] setProgress:k];
    i++;
    [self performSelector:@selector(checkIfDoneYet) withObject:nil afterDelay:0.25];
  }
  else
  {
    [self dismissView];
  }
}

- (void)dismissView
{
	if (loadingView) {
		[loadingView removeFromSuperview];
		[self.view removeFromSuperview];
		[loadingView release];
	}		
	if (self.delegate != NULL && [self.delegate respondsToSelector:@selector(appInitDidComplete)])
  {
		[delegate appInitDidComplete];
	}
  [[NSNotificationCenter defaultCenter] postNotificationName:@"setWasChanged" object:self];
}

- (void)dealloc
{
  [super dealloc];
}

@end
