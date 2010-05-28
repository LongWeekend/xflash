    //
//  DownloaderViewController.m
//  jFlash
//
//  Created by Mark Makdad on 5/25/10.
//  Copyright 2010 LONG WEEKEND INC. All rights reserved.
//

#import "DownloaderViewController.h"

@implementation DownloaderViewController

@synthesize statusMsgLabel, taskMsgLabel, progressIndicator;
@synthesize dlHandler;

/** 
 * viewDidLoad - Initialize UI elements in the view - progress indicator & labels
 */
- (void)viewDidLoad
{
  [super viewDidLoad];

  // Reset all variables to default
  [self setStatusMessage:@"Press the button to initiate the download"];
  [self setTaskMessage:@""];
  [self setProgress:0.0f];
  
  // Instantiate downloader with jFlash download URL
  LWEDownloader *tmpDlHandler = [[LWEDownloader alloc] initWithTargetURL:@"http://mini.local:8080/hudson/foobar"];
  [self setDlHandler:tmpDlHandler];
  
  // Register notification listener to handle downloader events
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateDownloaderDisplay) name:@"LWEDownloaderStateUpdated" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateDownloaderDisplay) name:@"LWEDownloaderProgressUpdated" object:nil];
}


/**
 * Delegate method before view appears; sets title bar tint according to theme
 */
- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  // TODO: Theme the status bar here
}


/**
 * Sets the status message of the Downloader View
 */
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

/**
 * Gets the current status message of the Downloader View
 */
-(NSString*) statusMessage
{
  return [[self statusMsgLabel] text];
}


/**
 * Sets the current task message of the Downloader View
 */
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


/**
 * Gets the current task message of the Downloader View
 */
-(NSString*) taskMessage
{
  return [[self taskMsgLabel] text];
}


/**
 * Sets the current progress % complete of the UIProgressView on the Downloader View
 */
-(void) setProgress: (float) newVal
{
  [[self progressIndicator] setProgress:newVal];
}


/**
 * Gets the current progress % complete of the UIProgressView on the Downloader View
 */
-(float) progress
{
  return [[self progressIndicator] progress];
}


/**
 * Starts a new download using the LWEDownloader instance held by DownloaderViewController  
 */
- (IBAction) startDownloadProcess
{
  [[self dlHandler] startDownload];
}


/**
 * Cancels an ongoing LWEDownloader instance and dismisses the DownloaderViewController  
 */
- (IBAction) cancelDownloadProcess
{
  [[self dlHandler] cancelDownload];
  [[self parentViewController] dismissModalViewControllerAnimated:YES];
}


/**
 * Retrieves current status from LWEDownloader and updates view
 */
- (void) updateDownloaderDisplay
{
  [self setTaskMessage:[[self dlHandler] taskMessage]];
  [self setStatusMessage:[[self dlHandler] statusMessage]];
  [self setProgress:[[self dlHandler] progress]];
  
  // See if we are done
  if ([[self dlHandler] stateIsFinal])
  {
    //[[self parentViewController] dismissModalViewControllerAnimated:YES];
  }
}


- (void)didReceiveMemoryWarning 
{
  // Releases the view if it doesn't have a superview.
  [super didReceiveMemoryWarning];
  // Release any cached data, images, etc that aren't in use.
}

- (void)dealloc
{
  [super dealloc];
}


@end
