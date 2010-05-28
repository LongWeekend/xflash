//
//  CardFlowViewController.h
//  jFlash
//
//  Created by シャロット ロス on 5/25/10.
//  Copyright 2010 LONG WEEKEND INC.. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "jFlashAppDelegate.h"
#import "UserHistoryPeer.h"
#import "AddTagViewController.h"
#import "Constants.h"
#import "PDColoredProgressView.h"
#import "ProgressDetailsViewController.h"
#import "MoodIcon.h"
#import "CardView.h"
#import <QuartzCore/QuartzCore.h>


@interface CardFlowViewController : UIViewController {
  IBOutlet id delegate;  //! The Delegate if any
  
  // the actual layout and view pieces
  CardView *cardView;
  IBOutlet UIView *practiceBgImage;

  // data objects
  Tag *currentCardSet;
  Card *currentCard;  
  
  // Mood Icon stuff
  MoodIcon *moodIcon;
  // Move these to MoodIcon.m
  IBOutlet UIImageView *percentCorrectTalkBubble;
  IBOutlet UILabel *percentCorrectLabel;
  IBOutlet UIButton *moodIconBtn;
  IBOutlet UIImageView *hhAnimationView;
  
  // suspect
  IBOutlet UILabel *cardSetLabel;
  IBOutlet UILabel *cardHeadwordLabel;
  IBOutlet UILabel *cardReadingLabel;
  IBOutlet UILabel *totalWordsLabel;
  
  // Action Bar
  IBOutlet UIButton *nextCardBtn;
  IBOutlet UIButton *prevCardBtn;
  IBOutlet UIButton *rightBtn;
  IBOutlet UIButton *wrongBtn;
  IBOutlet UIButton *addBtn;
  IBOutlet UIButton *buryCardBtn;
  
  // Progress Bar - move this out
  IBOutlet UIView *progressBarView;
  IBOutlet UILabel *cardSetProgressLabel0;
  IBOutlet UILabel *cardSetProgressLabel1;
  IBOutlet UILabel *cardSetProgressLabel2;
  IBOutlet UILabel *cardSetProgressLabel3;
  IBOutlet UILabel *cardSetProgressLabel4;
  IBOutlet UILabel *cardSetProgressLabel5;
  
  // Progress modal overlay
  IBOutlet UIButton *showProgressModalBtn;
  IBOutlet UIView *progressModalView;
  IBOutlet UIView *progressModalBorder;
  IBOutlet UIView *progressModalBtn;
  IBOutlet UIButton *progressModalCloseBtn;
  IBOutlet UILabel *progressModalCurrentStudySetLabel;
  IBOutlet UILabel *progressModalMotivationLabel;
    
  BOOL readingVisible;
  BOOL percentCorrectVisible;
  BOOL meaningMoreIconVisible;
  BOOL readingMoreIconVisible;
  BOOL showReadingBtnHiddenByUser;
  BOOL meaningRevealed;
  
  // For statistics
  // Stays here
  NSInteger numViewed;
  NSInteger numRight;
  NSInteger numWrong;
  NSInteger currentRightStreak;
  NSInteger currentWrongStreak;
  NSMutableArray *stats;
    
  //For swipes
  CGPoint startTouchPosition;
}

- (void)_cardViewDidSetup:(Card*)card;

@property (assign, nonatomic, readwrite) IBOutlet id delegate;
@property (nonatomic, retain) MoodIcon *moodIcon;
@property (nonatomic, retain) CardView *cardView;
@property (nonatomic, retain) UIView *practiceBgImage;

@end

extern NSString  *CardViewDidSetupNotification;
extern NSString  *CardViewWillSetupNotification;
