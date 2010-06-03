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

@protocol InitializationDelegate <NSObject>
@optional
- (void)appInitDidComplete;
@end

@class PDColoredProgressView;

@interface RootViewController : UIViewController 
{
	id<InitializationDelegate> delegate;
//	PDColoredProgressView *loadingView;
  LoadingView *loadingView;
  NSInteger i;
  UITabBarController *tabBarController;
}

@property (retain,nonatomic) UITabBarController *tabBarController;
@property (retain) id<InitializationDelegate> delegate;
@property (retain,nonatomic) LoadingView *loadingView;
@property NSInteger i;

- (void) switchToStudyView;
- (void) applicationWillTerminate:(UIApplication*) application;
- (void) showFirstLoadProgressView;
- (void) _continueDatabaseCopy;
- (void) _finishDatabaseCopy;
- (void) loadTabBar;

- (void) shouldSwapSearchViewController;
- (void) shouldHideDownloaderModal:(NSNotification*)aNotification;
- (void) shouldShowDownloaderModal:(NSNotification*)aNotification;
@end