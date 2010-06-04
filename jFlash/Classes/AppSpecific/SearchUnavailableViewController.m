//
//  SearchUnavailableViewController.m
//  jFlash
//
//  Created by Mark Makdad on 6/2/10.
//  Copyright 2010 Long Weekend Inc. All rights reserved.
//

#import "SearchUnavailableViewController.h"

//! View controller that tells the user that they have to download the FTS plugin first
@implementation SearchUnavailableViewController

//! Customized initializer setting title bar
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
  if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])
  {
    self.tabBarItem = [[UITabBarItem alloc] initWithTabBarSystemItem:UITabBarSystemItemSearch tag:0];
    self.title = @"Search";
  }
  return self;
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
  // Fire off a notification to bring up the downloader
  PluginManager *pm = [[CurrentState sharedCurrentState] pluginMgr];
  NSDictionary *dict = [[pm availablePluginsDictionary] objectForKey:FTS_DB_KEY];
  [[NSNotificationCenter defaultCenter] postNotificationName:@"shouldShowDownloaderModal" object:self userInfo:dict];
}


- (void)dealloc
{
    [super dealloc];
}


@end
