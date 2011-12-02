//  ModalTaskViewController.m
//  jFlash
//
//  Created by Mark Makdad on 5/25/10.
//  Copyright 2010 LONG WEEKEND INC. All rights reserved.
//

#import "ModalTaskViewController.h"

NSString * const LWEModalTaskDidCancel = @"LWEModalTaskDidCancel";
NSString * const LWEModalTaskDidFinish = @"LWEModalTaskDidFinish";
NSString * const LWEModalTaskDidFail = @"LWEModalTaskDidFail";

/**
 * Controls view & program flow during plugin/file downloads, database upgrades
 */
@implementation ModalTaskViewController

@synthesize taskMsgLabel, progressIndicator, startButton;
@synthesize taskHandler, showDetailedViewOnAppear, startTaskOnAppear;

// For content/webview
@synthesize webViewContent;

#pragma mark - View Hierarchy

/** UIView delegate - Initialize UI elements in the view - progress indicator & labels */
- (void)viewDidLoad
{
  [super viewDidLoad];
  self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:LWETableBackgroundImage]];
  [self.progressIndicator setTintColor:[[ThemeManager sharedThemeManager] currentThemeTintColor]];
}


/** UIView Delegate method - sets nav title bar tint according to theme */
- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  self.navigationController.navigationBar.tintColor = [[ThemeManager sharedThemeManager] currentThemeTintColor];
  
  // Make sure the buttons are set to the right states
  [self updateButtons];
}

/** UIView Delegate method - starts the download! */
- (void)viewDidAppear:(BOOL)animated
{
  [super viewDidAppear:animated];
  if (self.startTaskOnAppear)
  {
    [self startProcess];
  }
  if (self.showDetailedViewOnAppear)
  {
    // Avoid infinite loop when user presses "back" on nav bar
    self.showDetailedViewOnAppear = NO;
    [self showDetailedView];
  }
}

#pragma mark - LWEPackageDownloaderProgressDelegate

- (void) packageDownloader:(LWEPackageDownloader *)downloader progressDidUpdate:(CGFloat)progress
{
  self.progressIndicator.progress = progress;
}

- (void) packageDownloader:(LWEPackageDownloader *)downloader statusDidUpdate:(NSString *)string
{
  self.taskMsgLabel.text = string;
}

#pragma mark - IBAction Methods

/**
 * Starts a new task using delegate
 * Checks canStartTask first to see if it can start, otherwise NO-OP
 */ 
- (IBAction) startProcess
{
  if ([self canStartTask])
  {
    [self.taskHandler start];
    [self updateButtons];
  }
}


/**
 * If delegate does not implement canStartTask, assumes
 * that it is not possible to start (always returns NO)
 * We rely on the delegate to tell us it is ready to start
 */
- (BOOL) canStartTask
{
  if ([self.taskHandler respondsToSelector:@selector(canStartTask)])
  {
    return [self.taskHandler canStartTask];
  }
  else
  {
    return NO;
  }
}

/**
 * Cancels an ongoing task process
 * If delegate does not implement canCancelTask, assume that it is possible
 * to cancel and sends cancelTask message to taskHandler.
 * Also sends a notification on the current thread if cancel msg sent to delegate
 */
- (IBAction) cancelProcess
{
  if ([self canCancelTask])
  {
    [self.taskHandler cancel];
    [self updateButtons];
    [[NSNotificationCenter defaultCenter] postNotificationName:LWEModalTaskDidCancel object:nil];
  }
}

/**
 * Determines whether or not we can cancel based on delegate
 * If delegate does not implement, return YES - we should never
 * be able to NOT cancel if we aren't in control
 */
- (BOOL) canCancelTask
{
  if ([self.taskHandler respondsToSelector:@selector(canCancelTask)])
  {
    return [self.taskHandler canCancelTask];
  }
  else
  {
    return YES;
  }
}


/**
 * Update the enabled / disabled state of the buttons
 * based on delegates or canSomethingTask methods
 */
- (void) updateButtons
{
  if (self.canStartTask)
  {
    self.startButton.hidden = NO;
    self.progressIndicator.hidden = YES;
  }
  else
  {
    self.startButton.hidden = YES;
    self.progressIndicator.hidden = NO;
  }
       
  if (self.canCancelTask)
  {
    if (self.navigationItem.leftBarButtonItem == nil)
    {
      UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelProcess)];
      self.navigationItem.leftBarButtonItem = cancelButton;
      [cancelButton release];
    }
  }
  else
  {
    self.navigationItem.leftBarButtonItem = nil;
  }
}


/**
 * Retrieves current status from task delegate and updates view
 */
- (void) updateDisplay
{
  if ([self.taskHandler isSuccessState])
  {
    [[NSNotificationCenter defaultCenter] postNotificationName:LWEModalTaskDidFinish object:self];
  }
  else if ([self.taskHandler isFailureState])
  {
    [[NSNotificationCenter defaultCenter] postNotificationName:LWEModalTaskDidFail object:self];
  }
  
  // Call delegate & update the UI buttons
  [self updateButtons];
}


/**
 * Pushes the detail view controller on top of the ModalTaskViewController
 * The idea is that users have things to look @ while waiting on the task to complete
 * New idea: DOWNLOAD IN THE BACKGROUND FOOL.  MMA 2011.11.29
 */
- (IBAction) showDetailedView
{
  // Load a UIWebView to show
  UIWebView *webView = [[UIWebView alloc] initWithFrame:CGRectMake(0, 0, 320, 317)];
  [webView shutOffBouncing];
  webView.backgroundColor = [UIColor clearColor];
  webView.opaque = NO;
  
  // Only show content if we have set this variable
  if (self.webViewContent)
  {
    NSURL *url = [NSURL fileURLWithPath:[LWEFile createBundlePathWithFilename:@"plugin-resources/index.html"]];
    [webView loadHTMLString:self.webViewContent baseURL:url];
  }

//  WebGradientView *subview = [[WebGradientView alloc] initWithFrame:CGRectMake(0,0,320,317) subview:webView];

  [self.view addSubview:webView];
  [webView release];
}

- (void) viewDidUnload
{
  [super viewDidUnload];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
  self.taskMsgLabel = nil;
  self.progressIndicator = nil;
}

//! standard dealloc
- (void)dealloc
{
  [taskMsgLabel release];
  [progressIndicator release];
  [webViewContent release];
  [taskHandler release];
  [super dealloc];
}


@end