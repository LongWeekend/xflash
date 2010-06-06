//
//  RootViewController.h
//  jFlash
//
//  Created by Mark Makdad on 2/20/10.
//  Copyright 2010 LONG WEEKEND INC.. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "LoadingView.h"
#import "CurrentState.h"
#import "StudyViewController.h"
#import "StudySetViewController.h"
#import "SearchUnavailableViewController.h"
#import "SearchViewController.h"
#import "SettingsViewController.h"
#import "HelpViewController.h"
#import "PDColoredProgressView.h"
#import "Appirater.h"
#import "Constants.h"
#import "LWEFile.h"
#import "LWEDownloader.h"
// TODO: may not need to do this
#import "PluginManager.h"

@interface RootViewController : UIViewController 
{
  LoadingView *loadingView;
  UITabBarController *tabBarController;
}

@property (retain,nonatomic) UITabBarController *tabBarController;
@property (retain,nonatomic) LoadingView *loadingView;

- (void) switchToStudyView;
- (void) applicationWillTerminate:(UIApplication*) application;
- (void) loadTabBar;

// Notification methods
- (void) swapSearchViewController;
- (void) hideDownloaderModal:(NSNotification*)aNotification;
- (void) showDownloaderModal:(NSNotification*)aNotification;
@end