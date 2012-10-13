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
#import "jFlashAppDelegate.h"
#import <MessageUI/MessageUI.h>
#import "StudyViewProtocols.h"

#define SVC_ACTION_ADDTOSET_BUTTON 1
#define SVC_ACTION_ADDTOFAV_BUTTON 0
#define SVC_ACTION_REPORT_BUTTON 2
#define SVC_ACTION_TWEET_BUTTON 3
#define SVC_ACTION_FACEBOOK_BUTTON 4

@class ActionBarViewController;

@protocol ActionBarViewControllerDelegate <NSObject>
@optional
- (void)actionBarDidChangeMode:(ActionBarViewController*)avc;

// setup card to unrevealed state
- (void)actionBarWillSetup:(ActionBarViewController*)avc;
- (void)actionBarDidSetup:(ActionBarViewController*)avc;

// reveal card
- (void)actionBarWillReveal:(ActionBarViewController*)avc;
- (void)actionBarDidReveal:(ActionBarViewController*)avc;
- (BOOL)actionBarShouldReveal:(ActionBarViewController*)avc;
@end

@interface ActionBarViewController : UIViewController <UIActionSheetDelegate,
                                                       UIAlertViewDelegate,
                                                       MFMailComposeViewControllerDelegate,
                                                       StudyViewSubcontrollerProtocol>

- (NSString *)getTweetWord;

// action sheet
- (IBAction)showCardActionSheet;

@property (assign) IBOutlet id<ActionBarViewControllerDelegate> delegate;

@property (nonatomic, retain) Card *currentCard;

@property (nonatomic, retain) IBOutlet UIButton *addBtn;
@property (nonatomic, retain) IBOutlet UIButton *buryCardBtn;
@property (nonatomic, retain) IBOutlet UIButton *nextCardBtn;
@property (nonatomic, retain) IBOutlet UIButton *prevCardBtn;
@property (nonatomic, retain) IBOutlet UIButton *rightBtn;
@property (nonatomic, retain) IBOutlet UIButton *wrongBtn;

@property (nonatomic, retain) IBOutlet UIView *cardMeaningBtnHint;

@end