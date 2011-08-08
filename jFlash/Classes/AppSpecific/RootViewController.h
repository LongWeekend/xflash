//
//  RootViewController.h
//  jFlash
//
//  Created by Mark Makdad on 2/20/10.
//  Copyright 2010 LONG WEEKEND INC.. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "LWELoadingView.h"
#import "CurrentState.h"
#import "StudyViewController.h"
#import "StudySetViewController.h"
#import "SearchViewController.h"
#import "HelpViewController.h"
#import "PDColoredProgressView.h"
#import "Appirater.h"
#import "Constants.h"
#import "LWEFile.h"
#import "LWEDownloader.h"
#import "SettingsViewController.h"

extern NSString * const LWEShouldUpdateSettingsBadge;
extern NSString * const LWEShouldShowModal;
extern NSString * const LWEShouldDismissModal;
extern NSString * const LWEShouldShowStudySetView;

@interface RootViewController : UIViewController <UIAlertViewDelegate>
{
}

@property (retain,nonatomic) UITabBarController *tabBarController;
@property (retain,nonatomic) LWELoadingView *loadingView;

@property BOOL isFinishedLoading;

- (void) switchToStudyView;
- (IBAction) switchToSettings;
- (void) switchToSearchWithTerm:(NSString*)term;
- (void) loadTabBar;
- (void) showDatabaseLoadingView;
- (void) hideDatabaseLoadingView;

// Notification methods
- (void) _showModalWithViewController:(UIViewController*)vc useNavController:(BOOL)useNavController;
- (void) hideDownloaderModal:(NSNotification*)aNotification;
- (void) showDownloaderModal:(NSNotification*)aNotification;
@end