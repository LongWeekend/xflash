//
//  DownloaderViewController.h
//  jFlash
//
//  Created by Mark Makdad on 5/25/10.
//  Copyright 2010 LONG WEEKEND INC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LWEDownloader.h"

@interface DownloaderViewController : UIViewController
{
  // IBOutlet properties
  IBOutlet UILabel *statusMsgLabel;
  IBOutlet UILabel *taskMsgLabel;
  IBOutlet UIProgressView *progressIndicator;
  IBOutlet UIButton *cancelButton;
  
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

@property (nonatomic, retain) IBOutlet UILabel *statusMsgLabel;
@property (nonatomic, retain) IBOutlet UILabel *taskMsgLabel;
@property (nonatomic, retain) IBOutlet UIProgressView *progressIndicator;
@property (nonatomic, retain) IBOutlet UIButton *cancelButton;

@property (nonatomic, retain) LWEDownloader *dlHandler;

@end
