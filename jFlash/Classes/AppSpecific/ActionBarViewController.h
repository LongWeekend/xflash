//
//  ActionBarViewController.h
//  jFlash
//
//  Created by シャロット ロス on 6/4/10.
//  Copyright 2010 LONG WEEKEND INC.. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AddTagViewController.h"
#import "Constants.h"
#import "ReportBadDataViewController.h"
#import "jFlashAppDelegate.h"
#import "TweetWordViewController.h"
#import "LWETwitterEngine.h"
#import "LWETUser.h"
#import "LWETRequestDelegate.h"
#import "TweetWordXAuthController.h"

#define SVC_ACTION_TWEET_BUTTON 1
#define SVC_ACTION_REPORT_BUTTON 2
#define SVC_ACTION_ADDTOSET_BUTTON 0

@interface ActionBarViewController : UIViewController <UIActionSheetDelegate, UIAlertViewDelegate, LWETRequestDelegate>
{
  IBOutlet id delegate;  
  
  Card *currentCard;
  LWETwitterEngine *_twitterEngine;
  
  // The overtop buttons for quiz mode
  IBOutlet UIView *cardMeaningBtnHint;
  IBOutlet UIView *cardMeaningBtnHintMini;
  
  IBOutlet UIButton *nextCardBtn;
  IBOutlet UIButton *prevCardBtn;
  IBOutlet UIButton *rightBtn;
  IBOutlet UIButton *wrongBtn;
  IBOutlet UIButton *addBtn;
  IBOutlet UIButton *buryCardBtn;
}

- (NSString *)getTweetWord;

// interface actions
- (IBAction)doNextCardBtn;
- (IBAction)doPrevCardBtn;
- (IBAction)doRightBtn;
- (IBAction)doWrongBtn;
- (IBAction)doBuryCardBtn;

// core methods
- (void) setup;
- (void) reveal;

- (void)tweet;

// action sheet
- (IBAction)showCardActionSheet;

- (void) initTwitterEngine;


//we don't retain delegates
@property (assign, nonatomic, readwrite) IBOutlet id delegate;

@property (nonatomic, retain) Card *currentCard;

@property (nonatomic, retain) UIButton *addBtn;
@property (nonatomic, retain) UIButton *buryCardBtn;
@property (nonatomic, retain) UIButton *nextCardBtn;
@property (nonatomic, retain) UIButton *prevCardBtn;
@property (nonatomic, retain) UIButton *rightBtn;
@property (nonatomic, retain) UIButton *wrongBtn;

@property (nonatomic, retain) UIView *cardMeaningBtnHint;
@property (nonatomic, retain) UIView *cardMeaningBtnHintMini;

@end

//! Notification names
extern NSString * const actionBarWillSetupNotification;
extern NSString * const actionBarDidSetupNotification;
extern NSString * const actionBarWillRevealNotification;
extern NSString * const actionBarDidRevealNotification;