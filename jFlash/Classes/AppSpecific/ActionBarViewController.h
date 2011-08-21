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

#define SVC_ACTION_ADDTOSET_BUTTON 1
#define SVC_ACTION_ADDTOFAV_BUTTON 0
#define SVC_ACTION_TWEET_BUTTON 2
#define SVC_ACTION_REPORT_BUTTON 3

@class ActionBarViewController;

@protocol ActionBarViewControllerDelegate <NSObject>
@optional
// setup card to unrevealed state
- (void)actionBarWillSetup:(ActionBarViewController*)avc;
- (void)actionBarDidSetup:(ActionBarViewController*)avc;
// reveal card
- (void)actionBarWillReveal:(ActionBarViewController*)avc;
- (void)actionBarDidReveal:(ActionBarViewController*)avc;
- (BOOL)actionBar:(ActionBarViewController*)avc shouldReveal:(BOOL)reveal;
@end

@interface ActionBarViewController : UIViewController <UIActionSheetDelegate, UIAlertViewDelegate, LWETRequestDelegate>
{
  LWETwitterEngine *_twitterEngine;
}

- (NSString *)getTweetWord;

// interface actions
- (IBAction)doNextCardBtn;
- (IBAction)doPrevCardBtn;
- (IBAction)doRightBtn;
- (IBAction)doWrongBtn;
- (IBAction)doBuryCardBtn;

// core methods
- (void)setupWithCard:(Card*)card;
- (void)reveal;
- (void)tweet;

// action sheet
- (IBAction)showCardActionSheet;
- (void) initTwitterEngine;

//we don't retain delegates
@property (assign) IBOutlet id<ActionBarViewControllerDelegate> delegate;

@property (nonatomic, retain) Card *currentCard;

@property (nonatomic, retain) IBOutlet UIButton *addBtn;
@property (nonatomic, retain) IBOutlet UIButton *buryCardBtn;
@property (nonatomic, retain) IBOutlet UIButton *nextCardBtn;
@property (nonatomic, retain) IBOutlet UIButton *prevCardBtn;
@property (nonatomic, retain) IBOutlet UIButton *rightBtn;
@property (nonatomic, retain) IBOutlet UIButton *wrongBtn;

@property (nonatomic, retain) IBOutlet UIView *cardMeaningBtnHint;
@property (nonatomic, retain) IBOutlet UIView *cardMeaningBtnHintMini;

@end