//
//  StudyViewController.h
//  jFlash
//
//  Created by シャロット ロス on 5/4/09.
//  Copyright LONG WEEKEND INC 2009. All rights reserved.

#import <UIKit/UIKit.h>
#import "jFlashAppDelegate.h"
#import "UserHistoryPeer.h"
#import "AddTagViewController.h"
#import "Constants.h"
#import "PDColoredProgressView.h"
#import "ProgressDetailsViewController.h"
#import "ProgressBarViewController.h"
#import "MoodIcon.h"
#import <QuartzCore/QuartzCore.h>

@interface StudyViewController : UIViewController {
  MoodIcon *moodIcon;
  
  IBOutlet UILabel *cardSetLabel;

  IBOutlet UILabel *cardHeadwordLabel;
  IBOutlet UILabel *cardReadingLabel;
  IBOutlet UILabel *totalWordsLabel;

  IBOutlet UIImageView *percentCorrectTalkBubble;
  IBOutlet UILabel *percentCorrectLabel;
  IBOutlet UIButton *nextCardBtn;
  IBOutlet UIButton *prevCardBtn;
  IBOutlet UIButton *rightBtn;
  IBOutlet UIButton *wrongBtn;
  IBOutlet UIButton *addBtn;
  IBOutlet UIButton *buryCardBtn;
  IBOutlet UIButton *toggleReadingBtn;
  IBOutlet UIButton *cardMeaningBtn;
  IBOutlet UIButton *showProgressModalBtn;
  IBOutlet UIView *practiceBgImage;
  IBOutlet UIView *progressBarView;
  ProgressBarViewController *progressBarViewController;
  IBOutlet UIView *cardMeaningBtnHint;
  IBOutlet UIView *cardMeaningBtnHintMini;
  IBOutlet UIScrollView *cardReadingLabelScrollContainer;
  IBOutlet UIScrollView *cardHeadwordLabelScrollContainer;
  IBOutlet UIButton *moodIconBtn;
  IBOutlet UIImageView *hhAnimationView;
  IBOutlet UIImageView *cardReadingLabelScrollMoreIcon;
  IBOutlet UIImageView *cardHeadwordLabelScrollMoreIcon;

  // Progress modal overlay
  IBOutlet UIView *progressModalView;
  IBOutlet UIView *progressModalBtn;
  IBOutlet UIButton *progressModalCloseBtn;
  
  IBOutlet UILabel *remainingCardsLabel;
  IBOutlet UIWebView *meaningWebView;
  
  NSString *sql;

  NSMutableArray *stats;
  Tag *currentCardSet;
  Card *currentCard;

  BOOL readingVisible;
  BOOL percentCorrectVisible;
  BOOL meaningMoreIconVisible;
  BOOL readingMoreIconVisible;
  BOOL showReadingBtnHiddenByUser;
  BOOL isBrowseMode;
  BOOL meaningRevealed;

  // For statistics
  NSInteger numViewed;
  NSInteger numRight;
  NSInteger numWrong;
  NSInteger currentRightStreak;
  NSInteger currentWrongStreak;
  
  // Tracking XIB Layout Coordinates
  NSInteger cardReadingLabelScrollContainerYPosInXib;
  NSInteger cardHeadwordLabelHeightInXib;
  NSInteger toggleReadingBtnYPosInXib;
  NSInteger cardHeadwordLabelYPosInXib;

  //For swipes
  CGPoint startTouchPosition;
}

- (IBAction)doRevealMeaningBtn;
- (IBAction)doNextCardBtn;
- (IBAction)doPrevCardBtn;
- (IBAction)doRightBtn;
- (IBAction)doWrongBtn;
- (IBAction)doAddToSetBtn;
- (IBAction)doBuryCardBtn;
- (IBAction)doToggleReadingBtn;
- (IBAction)doShowProgressModalBtn;
- (IBAction)doDismissProgressModalBtn;
- (IBAction)doTogglePercentCorrectBtn;

- (void)refreshProgressBarView;
- (void)doCardBtn: (int)action;
- (void)doChangeCard: (Card*) card direction:(NSString*)direction;
- (void)doCardTransition:(NSString *)transition direction:(NSString *)direction;

- (void)prepareViewForCard:(Card*)card;
- (void)layoutCardContentForStudyDirection: (NSString*) studyDirection;
- (void)toggleMoreIconForLabel: (UILabel *)theLabel forScrollView:(UIScrollView *)scrollViewContainer;
- (void)updateCardReading;
- (void)updateTheme;
- (void)resetStudySet;
- (void)resetKeepingCurrentCard;
- (void)hideShowReadingBtn;
- (void)displayShowReadingBtn;
- (NSMutableArray*) getLevelDetails;

@property (nonatomic, retain) MoodIcon *moodIcon;
@property (nonatomic, retain) ProgressBarViewController *progressBarViewController; 
@property (nonatomic, retain) UILabel *cardSetLabel;
@property (nonatomic, retain) UILabel *cardHeadwordLabel;
@property (nonatomic, retain) UILabel *cardReadingLabel;
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
@property (nonatomic, retain) UIButton *toggleReadingBtn;
@property (nonatomic, retain) UIView *practiceBgImage;
@property (nonatomic, retain) UIView *progressBarView;
@property (nonatomic, retain) UIView *cardMeaningBtnHint;
@property (nonatomic, retain) UIView *cardMeaningBtnHintMini;
@property (nonatomic, retain) UIImageView *hhAnimationView;
@property (nonatomic, retain) UIScrollView *cardReadingLabelScrollContainer;
@property (nonatomic, retain) UIScrollView *cardHeadwordLabelScrollContainer;

@property (nonatomic, retain) UIWebView *meaningWebView;

@property (nonatomic, retain) UIView *progressModalView;
@property (nonatomic, retain) UIView *progressModalBtn;

@property (nonatomic, retain) Tag *currentCardSet;
@property (nonatomic, retain) Card *currentCard;
@property (nonatomic, retain) NSMutableArray *stats;

@property BOOL percentCorrectVisible;
@property BOOL readingVisible;
@property BOOL meaningMoreIconVisible;
@property BOOL readingMoreIconVisible;
@property BOOL showReadingBtnHiddenByUser;
@property BOOL isBrowseMode;
@property BOOL meaningRevealed;

@property NSInteger numRight;
@property NSInteger numWrong;
@property NSInteger numViewed;
@property NSInteger currentRightStreak;
@property NSInteger currentWrongStreak;
@property NSInteger cardReadingLabelScrollContainerYPosInXib;
@property NSInteger cardHeadwordLabelHeightInXib;
@property NSInteger toggleReadingBtnYPosInXib;
@property NSInteger cardHeadwordLabelYPosInXib;

@property (nonatomic) CGPoint startTouchPosition;

@end