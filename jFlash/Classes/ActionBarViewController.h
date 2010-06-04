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

#define SVC_ACTION_REPORT_BUTTON 0
#define SVC_ACTION_ADDTOSET_BUTTON 1

@interface ActionBarViewController : UIViewController <UIActionSheetDelegate> {
  IBOutlet id delegate;  
  IBOutlet id controllee;
  
  // The overtop buttons for quiz mode
  IBOutlet UIView *cardMeaningBtnHint;
  IBOutlet UIView *cardMeaningBtnHintMini;
  IBOutlet UIButton *cardMeaningBtn;
  
  IBOutlet UIButton *nextCardBtn;
  IBOutlet UIButton *prevCardBtn;
  IBOutlet UIButton *rightBtn;
  IBOutlet UIButton *wrongBtn;
  IBOutlet UIButton *addBtn;
  IBOutlet UIButton *buryCardBtn;
}

// interface actions
- (IBAction)doRevealMeaningBtn;
- (IBAction)doNextCardBtn;
- (IBAction)doPrevCardBtn;
- (IBAction)doRightBtn;
- (IBAction)doWrongBtn;
- (IBAction)doBuryCardBtn;

// core methods
- (void) setup;
- (void) reveal;

// action sheet
- (IBAction)showCardActionSheet;

//we don't retain delegates
@property (assign, nonatomic, readwrite) IBOutlet id delegate;
@property (assign, nonatomic, readwrite) IBOutlet id controllee;

@property (nonatomic, retain) UIButton *addBtn;
@property (nonatomic, retain) UIButton *buryCardBtn;
@property (nonatomic, retain) UIButton *nextCardBtn;
@property (nonatomic, retain) UIButton *prevCardBtn;
@property (nonatomic, retain) UIButton *rightBtn;
@property (nonatomic, retain) UIButton *wrongBtn;

@property (nonatomic, retain) UIButton *cardMeaningBtn;
@property (nonatomic, retain) UIView *cardMeaningBtnHint;
@property (nonatomic, retain) UIView *cardMeaningBtnHintMini;

@end

//! Notification names
extern NSString  *actionBarWillSetupNotification;
extern NSString  *actionBarDidSetupNotification;
extern NSString  *actionBarWillRevealNotification;
extern NSString  *actionBarDidRevealNotification;