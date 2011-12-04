//
//  ModalTaskViewController.h
//  jFlash
//
//  Created by Mark Makdad on 5/25/10.
//  Copyright 2010 LONG WEEKEND INC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LWELongRunningTaskProtocol.h"
#import "PDColoredProgressView.h"
#import "UIWebView+LWENoBounces.h"

extern NSString * const LWEModalTaskDidCancel;

@interface ModalTaskViewController : UIViewController <LWEPackageDownloaderProgressDelegate>
{
  NSString *webViewContentDirectory;              //! Sets the sub directory of the content to load into the details web view
  NSString *webViewContentFileName;               //! Sets the filename of the content to load into the details web view
}

// IBActions
- (IBAction) startProcess;
- (IBAction) cancelProcess;
- (IBAction) showDetailedView;

- (void) updateButtons;

// These can be delegated, but just in case we have 'em
- (BOOL) canStartTask;
- (BOOL) canCancelTask;

// Properties set from XIB file
@property (nonatomic, retain) IBOutlet UILabel *taskMsgLabel;
@property (nonatomic, retain) IBOutlet PDColoredProgressView *progressIndicator;
@property (nonatomic, retain) IBOutlet UIButton *startButton;

// User-set properties

// Content to be displayed in the web view
@property (retain) NSString *webViewContent;

//! Our task, must conform to LongRunningTaskProtocol so we know how to talk to it
@property (retain) id<LWELongRunningTaskProtocol> taskHandler;

@end
