    //
//  SearchUnavailableViewController.m
//  jFlash
//
//  Created by Mark Makdad on 6/2/10.
//  Copyright 2010 Long Weekend Inc. All rights reserved.
//

#import "SearchUnavailableViewController.h"


@implementation SearchUnavailableViewController

 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
//    self.navigationItem.title = @"Word Search";
    self.tabBarItem = [[UITabBarItem alloc] initWithTabBarSystemItem:UITabBarSystemItemSearch tag:0];
    self.title = @"Search";
  }
  return self;
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
  [super viewDidLoad];
  // Set the tab bar controller image png to the targets
}


- (void)viewWillAppear: (BOOL)animated
{
  [super viewWillAppear:animated];
  self.navigationController.navigationBar.tintColor = [[ThemeManager sharedThemeManager] currentThemeTintColor];
  self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:TABLEVIEW_BACKGROUND_IMAGE]];
}

//! Executed when the user presses "download" on the search unavailable page
- (IBAction) doDownloadButton
{
  DownloaderViewController* dlViewController = [[DownloaderViewController alloc] initWithNibName:@"DownloaderView" bundle:nil];
  dlViewController.title = @"Download Dictionary Indexes";
  UINavigationController *modalNavController = [[UINavigationController alloc] initWithRootViewController:dlViewController];
  [[self navigationController] presentModalViewController:modalNavController animated:YES];
  [modalNavController release];
  [dlViewController release];
}


- (void)dealloc
{
    [super dealloc];
}


@end
