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

@class PDColoredProgressView;

@interface RootViewController : UIViewController 
{
//	PDColoredProgressView *loadingView;
  LoadingView *loadingView;
  NSInteger i;
  UITabBarController *tabBarController;
}

@property (retain,nonatomic) UITabBarController *tabBarController;
@property (retain,nonatomic) LoadingView *loadingView;
@property NSInteger i;

- (void) switchToStudyView;
- (void) applicationWillTerminate:(UIApplication*) application;

// Semiprivate methods
- (void) _prepareDatabase;
- (void) _openDatabase;
- (void) _loadTabBar;

// Notification methods
- (void) shouldSwapSearchViewController;
- (void) shouldHideDownloaderModal:(NSNotification*)aNotification;
- (void) shouldShowDownloaderModal:(NSNotification*)aNotification;
@end