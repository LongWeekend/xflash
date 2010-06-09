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

#define UPDATE_ALERT_CANCEL_BUTTON 0
#define UPDATE_ALERT_UPDATE_NOW_BUTTON 1
#define UPDATE_ALERT_RELEASE_NOTES_BUTTON 2

@interface RootViewController : UIViewController <UIAlertViewDelegate>
{
  BOOL _showWelcomeSplash;
  LoadingView *loadingView;
  UITabBarController *tabBarController;
}

@property (retain,nonatomic) UITabBarController *tabBarController;
@property (retain,nonatomic) LoadingView *loadingView;

- (void) switchToStudyView;
- (void) applicationWillTerminate:(UIApplication*) application;
- (void) loadTabBar;

// Notification methods
- (void) _showModalWithViewController:(UIViewController*)vc useNavController:(BOOL)useNavController;
- (void) showUpdaterModal:(BOOL)releaseNotesOnly;
- (void) swapSearchViewController;
- (void) hideDownloaderModal:(NSNotification*)aNotification;
- (void) showDownloaderModal:(NSNotification*)aNotification;
@end