//
//  StudyViewController.h
//  jFlash
//
//  Created by シャロット ロス on 5/4/09.
//  Copyright LONG WEEKEND INC 2009. All rights reserved.

#import <UIKit/UIKit.h>
#import "jFlashAppDelegate.h"
#import "Constants.h"
#import "ProgressDetailsViewController.h"
#import "ProgressBarViewController.h"
#import "CardViewController.h"
#import "MoodIcon.h"
#import "BrowseModeCardViewDelegate.h"
#import "PracticeModeCardViewDelegate.h"
#import "ExampleSentencesViewController.h"

@interface StudyViewController : UIViewController <UIScrollViewDelegate, UIActionSheetDelegate> {
  
  // scroll view
  IBOutlet UIScrollView* scrollView;
  IBOutlet UIPageControl* pageControl;
 
  MoodIcon *moodIcon;
  
  IBOutlet CardViewController *cardViewController;
  IBOutlet UIView *cardView;
  
  IBOutlet ActionBarViewController *actionBarController;
  IBOutlet UIView *actionbarView;
  
  ExampleSentencesViewController *exampleSentencesViewController;
  
  IBOutlet UILabel *cardSetLabel;
  IBOutlet UILabel *totalWordsLabel;

  IBOutlet UIImageView *percentCorrectTalkBubble;
  IBOutlet UILabel *percentCorrectLabel;
  
  IBOutlet UIButton *revealCardBtn;
  IBOutlet UIImageView *tapForAnswerImage;
  
  // The progress bar
  IBOutlet UIButton *showProgressModalBtn;
  IBOutlet UIView *practiceBgImage;
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

- (void)refreshProgressBarView;
- (void)doCardBtn: (NSNotification *)aNotification;
- (void)doChangeCard: (Card*) card direction:(NSString*)direction;
- (void)updateTheme;
- (void)resetStudySet;
- (void)resetKeepingCurrentCard;
- (NSMutableArray*) getLevelDetails;

/* for pageControl */
- (IBAction)changePage:(id)sender;

/* internal */
- (void)setupScrollView;

// scroll view
@property (nonatomic, retain) UIView *scrollView;
@property (nonatomic, retain) UIPageControl* pageControl;
@property (nonatomic, retain) UIButton *revealCardBtn;
@property (nonatomic, retain) UIImageView *tapForAnswerImage;

@property (nonatomic, retain) MoodIcon *moodIcon;
@property (nonatomic, retain) ProgressBarViewController *progressBarViewController; 
@property (nonatomic, retain) CardViewController *cardViewController; 
@property (nonatomic, retain) UIView *cardView;

@property (nonatomic, retain) ExampleSentencesViewController *exampleSentencesViewController;

@property (nonatomic, retain) ActionBarViewController *actionBarController;
@property (nonatomic, retain) UIView *actionbarView;

@property (nonatomic, retain) UILabel *cardSetLabel;
@property (nonatomic, retain) UILabel *percentCorrectLabel;
@property (nonatomic, retain) UILabel *totalWordsLabel;
@property (nonatomic, retain) UILabel *remainingCardsLabel;

@property (nonatomic, retain) UIView *practiceBgImage;
@property (nonatomic, retain) UIView *progressBarView;
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

@end