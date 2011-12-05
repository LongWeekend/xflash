//
//  RootViewController.h
//  jFlash
//
//  Created by Mark Makdad on 2/20/10.
//  Copyright 2010 LONG WEEKEND INC.. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "DSActivityView.h"
#import "CurrentState.h"
#import "PDColoredProgressView.h"
#import "Appirater.h"
#import "Constants.h"
#import "LWEFile.h"

#define STUDY_VIEW_CONTROLLER_TAB_INDEX     0
#define STUDY_SET_VIEW_CONTROLLER_TAB_INDEX 1
#define SEARCH_VIEW_CONTROLLER_TAB_INDEX    2
#define SETTINGS_VIEW_CONTROLLER_TAB_INDEX  3

extern NSString * const LWEShouldShowModal;
extern NSString * const LWEShouldShowDownloadModal;
extern NSString * const LWEShouldDismissModal;
extern NSString * const LWEShouldShowStudySetView;
extern NSString * const LWEShouldShowStudyView;
extern NSString * const LWEShouldShowPopover;

@interface RootViewController : UIViewController <UIAlertViewDelegate, UITabBarControllerDelegate>

@property (retain,nonatomic) UITabBarController *tabBarController;

@property BOOL isFinishedLoading;

- (IBAction)switchToSettings;
- (void) switchToSearchWithTerm:(NSString*)term;
- (void) loadTabBar;
- (void) showDatabaseLoadingView;
- (void) hideDatabaseLoadingView;

- (void) _showModalWithViewController:(UIViewController*)vc useNavController:(BOOL)useNavController;
- (void) showDownloaderModal:(NSNotification*)aNotification;
@end