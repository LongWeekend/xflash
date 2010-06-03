//  DownloaderViewController.m
//  jFlash
//
//  Created by Mark Makdad on 5/25/10.
//  Copyright 2010 LONG WEEKEND INC. All rights reserved.
//

#import "DownloaderViewController.h"

//! Controls view & program flow during plugin/file downloads
@implementation DownloaderViewController

@synthesize statusMsgLabel, taskMsgLabel, progressIndicator, cancelButton;
@synthesize dlHandler;

//! UIView delegate - Initialize UI elements in the view - progress indicator & labels
- (void)viewDidLoad
{
  [super viewDidLoad];

  // Reset all variables to default
  [self setStatusMessage:@"Press the button to initiate the download"];
  [self setTaskMessage:@""];
  [self setProgress:0.0f];
  
  // Instantiate downloader with jFlash download URL & destination filename
  LWEDownloader *tmpDlHandler = [[LWEDownloader alloc] initWithTargetURL:@"http://mini.local:8080/hudson/jFlash-CORE-v1.1.db.gz"
                                                       targetFilename:[LWEFile createDocumentPathWithFilename:@"jFlash-CORE-v1.1.db"]];
  // Set the installer delegate to the PluginManager class
  [tmpDlHandler setDelegate:[[CurrentState sharedCurrentState] pluginMgr]];
  [self setDlHandler:tmpDlHandler];
  
  // Register notification listener to handle downloader events
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateDownloaderDisplay) name:@"LWEDownloaderStateUpdated" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateDownloaderDisplay) name:@"LWEDownloaderProgressUpdated" object:nil];
}


//! UIView Delegate method - sets nav title bar tint according to theme
- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  self.navigationController.navigationBar.tintColor = [[ThemeManager sharedThemeManager] currentThemeTintColor];
}


//! UIView Delegate method - starts the download!
- (void)viewDidAppear:(BOOL)animated
{
  [super viewDidAppear:animated];
  [self startDownloadProcess];
}


//! Sets the status message of the Downloader View
-(void) setStatusMessage: (NSString*) newString
{
  // Check that nil was not passed
  if (newString != nil)
  {
    if ([newString isKindOfClass:[NSString class]])
    {
      // OK - we got a string
      [[self statusMsgLabel] setText:newString];
    }
    else
    {
      // When passed non-NSString, throw exception
      [NSException raise:@"Invalid String Object Passed" format:@"Was passed object: %@",newString];
    }
  }
  else
  {
    // In nil case, set string to blank
    [[self statusMsgLabel] setText:@""];
  }
}


//! Gets the current status message of the Downloader View
-(NSString*) statusMessage
{
  return [[self statusMsgLabel] text];
}


//! Sets the current task message of the Downloader View
-(void) setTaskMessage: (NSString*) newString
{
  // Check that nil was not passed
  if (newString != nil)
  {
    if ([newString isKindOfClass:[NSString class]])
    {
      // OK - we got a string
      [[self taskMsgLabel] setText:newString];
    }
    else
    {
      // When passed non-NSString, throw exception
      [NSException raise:@"Invalid String Object Passed" format:@"Was passed object: %@",newString];
    }
  }
  else
  {
    // In nil case, set string to blank
    [[self taskMsgLabel] setText:@""];
  }
}


//! Gets the current task message of the Downloader View
-(NSString*) taskMessage
{
  return [[self taskMsgLabel] text];
}


//! Sets the current progress % complete of the UIProgressView on the Downloader View
-(void) setProgress: (float) newVal
{
  [[self progressIndicator] setProgress:newVal];
}


//! Gets the current progress % complete of the UIProgressView on the Downloader View
-(float) progress
{
  return [[self progressIndicator] progress];
}


//! Starts a new download using the LWEDownloader instance held by DownloaderViewController  
- (IBAction) startDownloadProcess
{
  [[self dlHandler] startDownload];
}


//! Cancels an ongoing LWEDownloader instance and dismisses the DownloaderViewController  
- (IBAction) cancelDownloadProcess
{
  [[self dlHandler] cancelDownload];
  [[NSNotificationCenter defaultCenter] postNotificationName:@"shouldHideDownloaderModal" object:self];
}


//! Retrieves current status from LWEDownloader and updates view
- (void) updateDownloaderDisplay
{
  [self setTaskMessage:[[self dlHandler] taskMessage]];
  [self setStatusMessage:[[self dlHandler] statusMessage]];
  [self setProgress:[[self dlHandler] progress]];
  
  if ([[self dlHandler] isFailureState])
  {
    // Yikes, we have to handle that
    LWE_LOG(@"DownloaderVC got failure state, shit what do I do now");
    
  }
  else if ([[self dlHandler] isSuccessState])
  {
    // Disable the cancel button
    [[self cancelButton] setEnabled:NO];
    
    // Tell someone about this!  Let someone else handle this noise
    LWE_LOG(@"DownloaderVC got success state, send a notification and stop worrying about it");
    [[NSNotificationCenter defaultCenter] postNotificationName:@"shouldHideDownloaderModal" object:self];
  }
}


//! standard dealloc
- (void)dealloc
{
  [super dealloc];
}


@end
