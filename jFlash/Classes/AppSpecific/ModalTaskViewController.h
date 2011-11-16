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
#import "UIWebView+LWENoBounces.h"

/**
 * Any delegate of this class needs to implement the following methods
 * - isSuccessState
 * - isFailureState
 * .. so that the task view controller knows what to do
 */
@protocol ModalTaskViewDelegate <NSObject>
@required
/** called when the user requests to cancel */
- (void) cancelTask;

/** called when the user requests to start */
- (void) startTask;

/** should return YES when the task is successful */
- (BOOL) isSuccessState;

/** should return YES when the task has terminated in failure */
- (BOOL) isFailureState;

/** Brief description of the active state of the task */
- (NSString*) taskMessage;

- (NSString*) statusMessage;
- (CGFloat) progress;
@optional
- (void) willUpdateButtonsInView:(id)sender;
- (void) didUpdateButtonsInView:(id)sender;
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
  NSString *webViewContentDirectory;              //! Sets the sub directory of the content to load into the details web view
  NSString *webViewContentFileName;               //! Sets the filename of the content to load into the details web view
}

@property (copy) NSString *statusMessage;
@property (copy) NSString *taskMessage;
@property CGFloat progress;

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
@property (nonatomic, retain) IBOutlet UIButton *startButton;
@property (nonatomic, retain) IBOutlet UIButton *pauseButton;

// User-set properties

//! If YES, -startProcess will be called on viewDidAppear
@property BOOL startTaskOnAppear;
//! If YES, -showDetailedView will be called on viewDidAppear
@property BOOL showDetailedViewOnAppear;

// Content to be displayed in the web view
@property (nonatomic, retain) NSString *webViewContent;

//! Task delegate, must conform to TaskViewControllerDelegate protocol
@property (nonatomic, retain) id<ModalTaskViewDelegate> taskHandler;

@end
