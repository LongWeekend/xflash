//
//  StudyViewController.h
//  jFlash
//
//  Created by シャロット ロス on 5/4/09.
//  Copyright LONG WEEKEND INC 2009. All rights reserved.

#import <UIKit/UIKit.h>
#import "Constants.h"
#import "ProgressDetailsViewController.h"
#import "ProgressBarViewController.h"

#import "StudyViewProtocols.h"
#import "PracticeModeCardViewDelegate.h"
#import "BrowseModeCardViewDelegate.h"
#import "ExampleSentencesViewController.h"

#import "ActionBarViewController.h"
#import "CardViewController.h"

#import "LWEAudioQueue.h"

#define STUDY_SET_HAS_FINISHED_ALERT_TAG  777
#define STUDY_SET_SHOW_BURIED_IDX         1
#define STUDY_SET_CHANGE_SET_IDX          0

@interface StudyViewController : UIViewController <UIScrollViewDelegate,
                                                   UIActionSheetDelegate,
                                                   UIAlertViewDelegate,
                                                   ProgressDetailsDelegate,
                                                   LWEAudioQueueDelegate>
{
  ProgressDetailsViewController *_progressVC;
  BOOL _alreadyShowedAlertView;
  BOOL _finishedSetAlertShowed;
  //! This is set when card is loaded, and used when revealed
  BOOL _hasExampleSentences;
  BOOL _viewHasBeenLoadedOnce;
  BOOL _isChangingPage;  // page control state
}

- (BOOL) hasExampleSentences;

- (IBAction)doShowProgressModalBtn;
- (IBAction)revealCard;
- (IBAction)pronounceCard:(id)sender;

- (void)resetStudySet;

- (void)doCardBtn: (NSNotification *)aNotification;
- (void)doChangeCard: (Card*) card direction:(NSString*)directionOrNil;

//! Gets notification from plugin manager
- (void)pluginDidInstall: (NSNotification *)aNotification;

/* for pageControl */
- (IBAction) changePage:(id)sender;
- (IBAction) changePage:(id)sender animated:(BOOL)animated;
- (IBAction) launchExampleInstaller;

@property (assign) id<StudyViewControllerDelegate> delegate;
@property (retain) id<ActionBarViewControllerDelegate, CardViewControllerDelegate> subcontrollerDelegate;

@property (nonatomic, retain) IBOutlet UIButton *_pronounceBtn;
@property (nonatomic, retain) IBOutlet UIButton *pronounceBtn;

// scroll view
@property (nonatomic, retain) IBOutlet UIScrollView *scrollView;
@property (nonatomic, retain) IBOutlet UIPageControl *pageControl;

@property (nonatomic, retain) IBOutlet CardViewController<StudyViewSubcontrollerDelegate> *cardViewController;
@property (nonatomic, retain) IBOutlet ActionBarViewController<StudyViewSubcontrollerDelegate> *actionBarController;
@property (nonatomic, retain) ExampleSentencesViewController *exampleSentencesViewController;
@property (nonatomic, retain) IBOutlet UIView *cardView;
@property (nonatomic, retain) IBOutlet UIView *actionbarView;

@property (nonatomic, retain) IBOutlet UILabel *cardSetLabel;
@property (nonatomic, retain) IBOutlet UILabel *totalWordsLabel;

@property (nonatomic, retain) IBOutlet UIButton *revealCardBtn;
@property (nonatomic, retain) IBOutlet UIImageView *tapForAnswerImage;

// The progress bar
@property (nonatomic, retain) IBOutlet UIButton *showProgressModalBtn;
@property (nonatomic, retain) IBOutlet UIImageView *practiceBgImage;
@property (nonatomic, retain) IBOutlet UIView *progressBarView;

// Progress modal overlay
@property (nonatomic, retain) IBOutlet UIView *progressModalView;
@property (nonatomic, retain) IBOutlet UIView *progressModalBtn;

@property (nonatomic, retain) IBOutlet UILabel *remainingCardsLabel;


// scroll view
@property (nonatomic, retain) Tag *currentCardSet;
@property (nonatomic, retain) Card *currentCard;

@property (nonatomic, retain) ProgressBarViewController *progressBarViewController; 

// stats for progress modal
@property NSInteger numRight;
@property NSInteger numWrong;
@property NSInteger numViewed;
@property NSInteger currentRightStreak;
@property NSInteger currentWrongStreak;

@end