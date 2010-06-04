//
//  DownloaderViewController.h
//  jFlash
//
//  Created by Mark Makdad on 5/25/10.
//  Copyright 2010 LONG WEEKEND INC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LWEDownloader.h"
#import "PDColoredProgressView.h"

@interface DownloaderViewController : UIViewController
{
  // IBOutlet properties
  IBOutlet UILabel *statusMsgLabel;
  IBOutlet UILabel *taskMsgLabel;
  IBOutlet PDColoredProgressView *progressIndicator;
  IBOutlet UIButton *cancelButton;
  IBOutlet UIButton *retryButton;
  
  // Downloader & Updater objects
  LWEDownloader *dlHandler;
}

// Custom getters & setters
-(void) setStatusMessage: (NSString*) newString;
-(NSString*) statusMessage;
-(void) setTaskMessage: (NSString*) newString;
-(NSString*) taskMessage;
-(void) setProgress: (float) newVal;
-(float) progress;

// IBActions
- (IBAction) startDownloadProcess;
- (IBAction) cancelDownloadProcess;
- (IBAction) retryDownloadProcess;

@property (nonatomic, retain) IBOutlet UILabel *statusMsgLabel;
@property (nonatomic, retain) IBOutlet UILabel *taskMsgLabel;
@property (nonatomic, retain) IBOutlet PDColoredProgressView *progressIndicator;
@property (nonatomic, retain) IBOutlet UIButton *cancelButton;
@property (nonatomic, retain) IBOutlet UIButton *retryButton;

@property (nonatomic, retain) LWEDownloader *dlHandler;

@end
