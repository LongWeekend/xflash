//  ModalTaskViewController.m
//  jFlash
//
//  Created by Mark Makdad on 5/25/10.
//  Copyright 2010 LONG WEEKEND INC. All rights reserved.
//

#import "ModalTaskViewController.h"
//#import "WebGradientView.h"

/**
 * Controls view & program flow during plugin/file downloads, database upgrades
 */
@implementation ModalTaskViewController

@synthesize statusMsgLabel, taskMsgLabel, progressIndicator, startButton, pauseButton;
@synthesize taskHandler, showDetailedViewOnAppear, startTaskOnAppear, webViewContentDirectory, webViewContentFileName;

//! Initialization
- (id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
  if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]))
  {
    [self setTaskHandler:nil];
    [self setWebViewContentDirectory:nil];
    [self setWebViewContentFileName:nil];
    self.navigationItem.leftBarButtonItem = nil;
  }
  return self;
}

/** UIView delegate - Initialize UI elements in the view - progress indicator & labels */
- (void)viewDidLoad
{
  [super viewDidLoad];
  self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:TABLEVIEW_BACKGROUND_IMAGE]];

  // Reset all variables to default
  [self setStatusMessage:@""];
  [self setTaskMessage:@""];
  [self setProgress:0.0f];

  // Sets the disabled/enabled state of start button
//  [[self startButton] setEnabled:![self startTaskOnAppear]];

  [[self progressIndicator] setTintColor:[[ThemeManager sharedThemeManager] currentThemeTintColor]];
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
  if (startTaskOnAppear)
  {
    [self startProcess];
  }
  if (showDetailedViewOnAppear)
  {
    // Avoid infinite loop when user presses "back" on nav bar
    [self setShowDetailedViewOnAppear:NO];
    [self showDetailedView];
  }
}


/** Sets the status message of the Downloader View */
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


/** Gets the current status message of the Downloader View */
-(NSString*) statusMessage
{
  return [[self statusMsgLabel] text];
}


/** Sets the current task message of the Downloader View */
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


/** Gets the current task message of the Downloader View */
-(NSString*) taskMessage
{
  return [[self taskMsgLabel] text];
}


/** Sets the current progress % complete of the UIProgressView on the Downloader View */
-(void) setProgress: (float) newVal
{
  [[self progressIndicator] setProgress:newVal];
}


/** Gets the current progress % complete of the UIProgressView on the Downloader View */
-(float) progress
{
  return [[self progressIndicator] progress];
}


/**
 * Starts a new task using delegate
 * Checks canStartTask first to see if it can start, otherwise NO-OP
 */ 
- (IBAction) startProcess
{
  if ([self canStartTask])
  {
    [[self taskHandler] startTask];
    self.progressIndicator.hidden = NO;
    self.startButton.hidden = YES;
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
  if ([[self taskHandler] respondsToSelector:@selector(canStartTask)])
    return [[self taskHandler] canStartTask];
  else
    return NO;
}


/** 
 * Pauses an ongoing task, calling on canPauseTask (or delegate) first
 */
- (IBAction) pauseProcess
{
  if ([self canPauseTask] && [[self taskHandler] respondsToSelector:@selector(pauseTask)])
  {
    [[self taskHandler] pauseTask];
  }
}

                         
/*
* If delegate does not implement canPauseTask, assumes
* that it is not possible to pause (always returns NO)
*/
- (BOOL) canPauseTask
{
  if ([[self taskHandler] respondsToSelector:@selector(canPauseTask)])
    return [[self taskHandler] canPauseTask];
  else
    return NO;
}
                         

/**
 * Cancels an ongoing task process
 * If delegate does not implement canCancelTask, assume that it is possible
 * to cancel and sends cancelTask message to taskHandler.
 * Also sends a taskDidCompleteSuccessfully notification on the current thread if cancel msg sent to delegate
 */
- (IBAction) cancelProcess
{
  if ([self canCancelTask])
  {
    [[self taskHandler] cancelTask];
    self.progressIndicator.hidden = YES;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"taskDidCancelSuccessfully" object:nil];
  }
}


/**
 * Determines whether or not we can cancel based on delegate
 * If delegate does not implement, return YES - we should never
 * be able to NOT cancel if we aren't in control
 */
- (BOOL) canCancelTask
{
  if ([[self taskHandler] respondsToSelector:@selector(canCancelTask)])
    return [[self taskHandler] canCancelTask];
  else
    return YES;  
}


/**
 * Retries a failed task process
 * Checks if delegate responds to canRetryTask - assumes NO if not implemented
 * Also will call resetTask if implemented prior to restarting
 * Updates UI buttons accordingly
 */
- (IBAction) retryProcess
{
  if ([[self taskHandler] isFailureState])
  {
    if ([self canRetryTask])
    {
      // See if reset is possible
      if ([[self taskHandler] respondsToSelector:@selector(resetTask)]) 
      {
        [[self taskHandler] resetTask];
      }
      
      // Finally, restart
      [self startProcess];
    }
  }
}


/**
 * Assume that I cannot retry (always return NO) unless delegate
 * implements this method and says YES.
 */
- (BOOL) canRetryTask
{
  if ([[self taskHandler] respondsToSelector:@selector(canRetryTask)])
  {
    return [[self taskHandler] canRetryTask];
  }
  else
  {
    return NO;
  }
}


/** 
 * Called immediately before we update buttons
 * Gives the delegate a chance to change the visibility
 * (hidden = YES, for example)
 */
- (void) willUpdateButtonsInView:(id)sender
{
  if ([[self taskHandler] respondsToSelector:@selector(willUpdateButtonsInView:)])
  {
    [[self taskHandler] willUpdateButtonsInView:sender];
  }
}

- (void) didUpdateButtonsInView:(id)sender
{
  if ([[self taskHandler] respondsToSelector:@selector(didUpdateButtonsInView:)])
  {
    [[self taskHandler] didUpdateButtonsInView:sender];
  }
}


/**
 * Update the enabled / disabled state of the buttons
 * based on delegates or canSomethingTask methods
 */
- (void) updateButtons
{
  [self willUpdateButtonsInView:self];
       
  if ([self canCancelTask])
  {
    if (self.navigationItem.leftBarButtonItem == nil)
    {
      UIBarButtonItem* cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelProcess)];
      self.navigationItem.leftBarButtonItem = cancelButton;
      [cancelButton release];
    }
  }
  else
  {
    self.navigationItem.leftBarButtonItem = nil;
  }
  
  [self didUpdateButtonsInView:self];
}


/**
 * Retrieves current status from task delegate and updates view
 */
- (void) updateDisplay
{
  [self setTaskMessage:[[self taskHandler] taskMessage]];
  [self setStatusMessage:[[self taskHandler] statusMessage]];
  [self setProgress:[[self taskHandler] progress]];
  
  if ([[self taskHandler] isSuccessState])
  {
    // Tell someone about this!  Let someone else handle this noise
    LWE_LOG(@"DownloaderVC got success state, send a notification and stop worrying about it");
    [[NSNotificationCenter defaultCenter] postNotificationName:@"taskDidCompleteSuccessfully" object:self];
  }
  else if ([[self taskHandler] isFailureState])
  {
    // Tell someone about this!  Let someone else handle this noise
    [[NSNotificationCenter defaultCenter] postNotificationName:@"taskDidFail" object:self];
  }
  
  // Call delegate & update the UI buttons
  [self updateButtons];
}


/**
 * Pushes the detail view controller on top of the ModalTaskViewController
 * The idea is that users have things to look @ while waiting on the task to complete
 */
- (IBAction) showDetailedView
{
  // Load a UIWebView to show
  UIWebView *webView = [[UIWebView alloc] initWithFrame:CGRectMake(0, 0, 320, 317)];
  [webView shutOffBouncing];
  webView.backgroundColor = [UIColor clearColor];
  webView.opaque = NO;
  
  NSString *filename = [[NSBundle mainBundle] pathForResource:[self webViewContentFileName] ofType:@"html" inDirectory:[self webViewContentDirectory]];
  NSURL *url = [NSURL fileURLWithPath:filename];
  [webView loadRequest:[NSURLRequest requestWithURL:url]];
  
//  WebGradientView *subview = [[WebGradientView alloc] initWithFrame:CGRectMake(0,0,320,317) subview:webView];

  [self.view addSubview:webView];
  [webView release];
}

- (void) viewDidUnload
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
  [super viewDidUnload];
}

//! standard dealloc
- (void)dealloc
{
  [self setTaskHandler:nil];
  [self setWebViewContentDirectory:nil];
  [self setWebViewContentFileName:nil];
  [super dealloc];
}


@end