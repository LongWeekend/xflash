//
//  ModalTaskViewController.h
//  jFlash
//
//  Created by Mark Makdad on 5/25/10.
//  Copyright 2010 LONG WEEKEND INC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LWEDownloader.h"
#import "PDColoredProgressView.h"

/**
 * Any delegate of this class needs to implement the following methods
 * - isSuccessState
 * - isFailureState
 * .. so that the task view controller knows what to do
 */
//TODO; this isn't a protocol - this is an interface.  We should be subclassing some abstract class for VersionManager and LWEDownloader
@protocol ModalTaskViewDelegate <NSObject>
@required
- (void) cancelTask;
- (void) startTask;
- (BOOL) isSuccessState;
- (BOOL) isFailureState;
- (NSString*) taskMessage;
- (NSString*) statusMessage;
@optional
- (void) willUpdateButtonsInView:(id)sender;
- (BOOL) canCancelTask;
- (BOOL) canRetryTask;
- (BOOL) canStartTask;
- (BOOL) canPauseTask;
- (void) resetTask;
- (void) pauseTask;
- (void) resumeTask;
@end

@interface ModalTaskViewController : UIViewController
{
  // IBOutlet properties
  IBOutlet UILabel *statusMsgLabel;
  IBOutlet UILabel *taskMsgLabel;
  IBOutlet PDColoredProgressView *progressIndicator;
  IBOutlet UIButton *cancelButton;
  IBOutlet UIButton *retryButton;
  IBOutlet UIButton *pauseButton;
  IBOutlet UIButton *startButton;
  
  // How to behave
  BOOL startTaskOnAppear;                             //! If YES, -startProcess will be called on viewDidAppear
  BOOL showDetailedViewOnAppear;                      //! If YES, -showDetailedView will be called on viewDidAppear
  
  // Downloader & Updater objects
  id<ModalTaskViewDelegate> taskHandler;         //! Task delegate, must conform to TaskViewControllerDelegate protocol
}

// Custom getters & setters
-(void) setStatusMessage: (NSString*) newString;
-(NSString*) statusMessage;
-(void) setTaskMessage: (NSString*) newString;
-(NSString*) taskMessage;
-(void) setProgress: (float) newVal;
-(float) progress;

// IBActions
- (IBAction) startProcess;
- (IBAction) cancelProcess;
- (IBAction) retryProcess;
- (IBAction) pauseProcess;
- (IBAction) showDetailedView;

- (void) updateButtons;

// These can be delegated, but just in case we have 'em
- (BOOL) canStartTask;
- (BOOL) canRetryTask;
- (BOOL) canCancelTask;
- (BOOL) canPauseTask;
- (void) willUpdateButtonsInView:(id)sender;

// Properties set from XIB file
@property (nonatomic, retain) IBOutlet UILabel *statusMsgLabel;
@property (nonatomic, retain) IBOutlet UILabel *taskMsgLabel;
@property (nonatomic, retain) IBOutlet PDColoredProgressView *progressIndicator;
@property (nonatomic, retain) IBOutlet UIButton *cancelButton;
@property (nonatomic, retain) IBOutlet UIButton *retryButton;
@property (nonatomic, retain) IBOutlet UIButton *startButton;
@property (nonatomic, retain) IBOutlet UIButton *pauseButton;

// User-set properties
@property BOOL startTaskOnAppear;
@property BOOL showDetailedViewOnAppear;
@property (nonatomic, retain) id taskHandler;

@end