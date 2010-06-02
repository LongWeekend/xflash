//
//  StudyViewController.h
//  jFlash
//
//  Created by シャロット ロス on 5/4/09.
//  Copyright LONG WEEKEND INC 2009. All rights reserved.

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "jFlashAppDelegate.h"
#import "AddTagViewController.h"
#import "Constants.h"
#import "ProgressDetailsViewController.h"
#import "ProgressBarViewController.h"
#import "CardViewController.h"
#import "MoodIcon.h"
#import "BrowseModeCardViewDelegate.h"
#import "PracticeModeCardViewDelegate.h"
#import "ReportBadDataViewController.h"

#define SVC_ACTION_REPORT_BUTTON 0
#define SVC_ACTION_ADDTOSET_BUTTON 1

@interface StudyViewController : UIViewController <UIScrollViewDelegate, UIActionSheetDelegate> {
  
  // scroll view
  IBOutlet UIScrollView* scrollView;
  IBOutlet UIPageControl* pageControl;
 
  MoodIcon *moodIcon;
  
  IBOutlet CardViewController *cardViewController;
  IBOutlet UIView *cardView;
  
  IBOutlet UILabel *cardSetLabel;
  IBOutlet UILabel *totalWordsLabel;

  IBOutlet UIImageView *percentCorrectTalkBubble;
  IBOutlet UILabel *percentCorrectLabel;
  
  // TODO: move to action bar
  IBOutlet UIButton *nextCardBtn;
  IBOutlet UIButton *prevCardBtn;
  IBOutlet UIButton *rightBtn;
  IBOutlet UIButton *wrongBtn;
  IBOutlet UIButton *addBtn;
  IBOutlet UIButton *buryCardBtn;
  
  // The progress bar
  IBOutlet UIButton *showProgressModalBtn;
  IBOutlet UIView *practiceBgImage;
  IBOutlet UIView *progressBarView;
  ProgressBarViewController *progressBarViewController;
  
  // The overtop buttons for quiz mode
  IBOutlet UIView *cardMeaningBtnHint;
  IBOutlet UIView *cardMeaningBtnHintMini;
  IBOutlet UIButton *cardMeaningBtn;
  
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
  
  BOOL pageControlIsChangingPage;

  // For statistics
  NSInteger numViewed;
  NSInteger numRight;
  NSInteger numWrong;
  NSInteger currentRightStreak;
  NSInteger currentWrongStreak;

  //For swipes
  CGPoint startTouchPosition;
}

- (IBAction)doRevealMeaningBtn;
- (IBAction)doNextCardBtn;
- (IBAction)doPrevCardBtn;
- (IBAction)doRightBtn;
- (IBAction)doWrongBtn;
- (IBAction)doBuryCardBtn;
- (IBAction)doShowProgressModalBtn;
- (IBAction)doTogglePercentCorrectBtn;
- (IBAction) showCardActionSheet;

- (void)refreshProgressBarView;

- (void)doCardBtn: (int)action;
- (void)doChangeCard: (Card*) card direction:(NSString*)direction;
- (void)doCardTransition:(NSString *)transition direction:(NSString *)direction;

- (void)updateTheme;
- (void)resetStudySet;
- (void)resetKeepingCurrentCard;
- (NSMutableArray*) getLevelDetails;

// Private
- (void) _resetActionMenu;

/* for pageControl */
- (IBAction)changePage:(id)sender;

/* internal */
- (void)setupScrollView;

// scroll view
@property (nonatomic, retain) UIView *scrollView;
@property (nonatomic, retain) UIPageControl* pageControl;

@property (nonatomic, retain) MoodIcon *moodIcon;
@property (nonatomic, retain) ProgressBarViewController *progressBarViewController; 
@property (nonatomic, retain) CardViewController *cardViewController; 
@property (nonatomic, retain) UIView *cardView;
@property (nonatomic, retain) UILabel *cardSetLabel;
@property (nonatomic, retain) UILabel *percentCorrectLabel;
@property (nonatomic, retain) UILabel *totalWordsLabel;
@property (nonatomic, retain) UILabel *remainingCardsLabel;

@property (nonatomic, retain) UIButton *addBtn;
@property (nonatomic, retain) UIButton *buryCardBtn;
@property (nonatomic, retain) UIButton *nextCardBtn;
@property (nonatomic, retain) UIButton *prevCardBtn;
@property (nonatomic, retain) UIButton *rightBtn;
@property (nonatomic, retain) UIButton *wrongBtn;
@property (nonatomic, retain) UIButton *cardMeaningBtn;
@property (nonatomic, retain) UIView *practiceBgImage;
@property (nonatomic, retain) UIView *progressBarView;
@property (nonatomic, retain) UIView *cardMeaningBtnHint;
@property (nonatomic, retain) UIView *cardMeaningBtnHintMini;
@property (nonatomic, retain) UIImageView *hhAnimationView;

@property (nonatomic, retain) UIView *progressModalView;
@property (nonatomic, retain) UIView *progressModalBtn;

@property (nonatomic, retain) Tag *currentCardSet;
@property (nonatomic, retain) Card *currentCard;

@property BOOL percentCorrectVisible;
@property BOOL isBrowseMode;

// stats for progress modal
@property NSInteger numRight;
@property NSInteger numWrong;
@property NSInteger numViewed;
@property NSInteger currentRightStreak;
@property NSInteger currentWrongStreak;

@property (nonatomic) CGPoint startTouchPosition;

@end