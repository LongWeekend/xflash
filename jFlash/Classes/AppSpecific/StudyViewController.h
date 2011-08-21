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

#import "MoodIcon.h"

#import "CardViewController.h"
#import "ActionBarViewController.h"
#import "BrowseModeCardViewDelegate.h"
#import "PracticeModeCardViewDelegate.h"
#import "ExampleSentencesViewController.h"

#define STUDY_SET_HAS_FINISHED_ALERT_TAG  777
#define STUDY_SET_SHOW_BURIED_IDX         1
#define STUDY_SET_CHANGE_SET_IDX          0

@interface StudyViewController : UIViewController <UIScrollViewDelegate, UIActionSheetDelegate, UIAlertViewDelegate>
{
  BOOL _alreadyShowedAlertView;
  BOOL _finishedSetAlertShowed;
  //! This is set when card is loaded, and used when revealed
  BOOL _cardShouldShowExampleViewCached;
  BOOL _viewHasBeenLoadedOnce;
  
  id cardViewControllerDelegate;
  
  // scroll view
  IBOutlet UIScrollView* scrollView;
  IBOutlet UIPageControl* pageControl;
 
  MoodIcon *moodIcon;
  
  IBOutlet CardViewController *cardViewController;
  IBOutlet UIView *cardView;
  
  IBOutlet ActionBarViewController *actionBarController;
  IBOutlet UIView *actionbarView;
  
  UIViewController *exampleSentencesViewController;
  
  IBOutlet UILabel *cardSetLabel;
  IBOutlet UILabel *totalWordsLabel;

  IBOutlet UIImageView *percentCorrectTalkBubble;
  IBOutlet UILabel *percentCorrectLabel;
  
  IBOutlet UIButton *revealCardBtn;
  IBOutlet UIImageView *tapForAnswerImage;
  
  // The progress bar
  IBOutlet UIButton *showProgressModalBtn;
  IBOutlet UIImageView *practiceBgImage;
  IBOutlet UIView *progressBarView;
  ProgressBarViewController *progressBarViewController;
  
  // Mood Icon
  IBOutlet UIButton *moodIconBtn;
  IBOutlet UIImageView *hhAnimationView;
  
  // Progress modal overlay
  IBOutlet UIView *progressModalView;
  IBOutlet UIView *progressModalBtn;
  IBOutlet UIButton *progressModalCloseBtn;
  
  IBOutlet UILabel *remainingCardsLabel;

  Tag *currentCardSet;
  Card *currentCard;

  BOOL percentCorrectVisible;
  BOOL isBrowseMode;
  
  // page control state
  BOOL pageControlIsChangingPage;

  // For statistics
  NSInteger numViewed;
  NSInteger numRight;
  NSInteger numWrong;
  NSInteger currentRightStreak;
  NSInteger currentWrongStreak;
}

- (IBAction)doShowProgressModalBtn;
- (IBAction)doTogglePercentCorrectBtn;
- (IBAction)revealCard;

- (void)doCardBtn: (NSNotification *)aNotification;
- (void)doChangeCard: (Card*) card direction:(NSString*)directionOrNil;
- (void)resetStudySet;
- (void)refreshCardView;

//! Gets notification from plugin manager
- (void)pluginDidInstall: (NSNotification *)aNotification;
- (void)doCardBtn: (NSNotification *)aNotification;

/* for pageControl */
- (IBAction) changePage:(id)sender;
- (IBAction) launchExampleInstaller;


// scroll view
@property (nonatomic, retain) UIScrollView *scrollView;
@property (nonatomic, retain) UIPageControl* pageControl;
@property (nonatomic, retain) UIButton *revealCardBtn;
@property (nonatomic, retain) UIImageView *tapForAnswerImage;

@property (nonatomic, retain) MoodIcon *moodIcon;
@property (nonatomic, retain) ProgressBarViewController *progressBarViewController; 
@property (nonatomic, retain) CardViewController *cardViewController; 
@property (nonatomic, retain) UIView *cardView;

@property (nonatomic, retain) UIViewController *exampleSentencesViewController;

@property (nonatomic, retain) ActionBarViewController *actionBarController;
@property (nonatomic, retain) UIView *actionbarView;

@property (nonatomic, retain) UILabel *cardSetLabel;
@property (nonatomic, retain) UILabel *percentCorrectLabel;
@property (nonatomic, retain) UILabel *totalWordsLabel;
@property (nonatomic, retain) UILabel *remainingCardsLabel;

@property (nonatomic, retain) UIImageView *practiceBgImage;
@property (nonatomic, retain) UIView *progressBarView;
@property (nonatomic, retain) UIImageView *hhAnimationView;

@property (nonatomic, retain) UIView *progressModalView;
@property (nonatomic, retain) UIView *progressModalBtn;

@property (nonatomic, retain) Tag *currentCardSet;
@property (nonatomic, retain) Card *currentCard;

@property (nonatomic, retain) id cardViewControllerDelegate;

@property BOOL percentCorrectVisible;
@property BOOL isBrowseMode;

// stats for progress modal
@property NSInteger numRight;
@property NSInteger numWrong;
@property NSInteger numViewed;
@property NSInteger currentRightStreak;
@property NSInteger currentWrongStreak;

@end