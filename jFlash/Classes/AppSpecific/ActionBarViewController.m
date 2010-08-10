//
//  ActionBarViewController.m
//  jFlash
//
//  Created by シャロット ロス on 6/4/10.
//  Copyright 2010 LONG WEEKEND INC. All rights reserved.
//

#import "ActionBarViewController.h"
#import "RootViewController.h"

//! Informal protocol defined messages sent to delegate
@interface NSObject (ActionBarDelegateSupport)

// setup card to unrevealed state
- (void)actionBarWillSetup:(NSNotification *)aNotification;
- (void)actionBarDidSetup:(NSNotification *)aNotification;

// reveal card
- (void)actionBarWillReveal:(NSNotification *)aNotification;
- (void)actionBarDidReveal:(NSNotification *)aNotification;
- (BOOL)actionBarShouldReveal:(id)actionMenu shouldReveal:(BOOL)reveal;

@end

@implementation ActionBarViewController
@synthesize delegate, currentCard;
@synthesize nextCardBtn, prevCardBtn, addBtn, rightBtn, wrongBtn, buryCardBtn;
@synthesize cardMeaningBtnHint, cardMeaningBtnHintMini;

#pragma mark -
#pragma mark Delegate Methods

- (void)_actionBarWillSetup
{
  NSNotification *notification = [NSNotification notificationWithName: actionBarWillSetupNotification object:self];
  
  // send the selector to the delegate if it responds
  if([[self delegate] respondsToSelector:@selector(actionBarWillSetup:)])
  {
    [[self delegate] actionBarWillSetup:notification];
  }
  
  //in case something else cares.  Seems to be the pattern from the book but I don't know if we really need this
  [[NSNotificationCenter defaultCenter] postNotification:notification];
}

- (void)_actionBarDidSetup
{
  NSNotification *notification = [NSNotification notificationWithName: actionBarDidSetupNotification object:self];
  
  // send the selector to the delegate if it responds
  if([[self delegate] respondsToSelector:@selector(actionBarDidSetup:)])
  {
    [[self delegate] actionBarDidSetup:notification];
  }
  
  //in case something else cares.  Seems to be the pattern from the book but I don't know if we really need this
  [[NSNotificationCenter defaultCenter] postNotification:notification];
}

- (void)_actionBarWillReveal
{
  NSNotification *notification = [NSNotification notificationWithName: actionBarWillRevealNotification object:self];
  
  // send the selector to the delegate if it responds
  if([[self delegate] respondsToSelector:@selector(actionBarWillReveal:)])
  {
    [[self delegate] actionBarWillReveal:notification];
  }
  
  //in case something else cares.  Seems to be the pattern from the book but I don't know if we really need this
  [[NSNotificationCenter defaultCenter] postNotification:notification];
}

- (void)_actionBarDidReveal
{
  // we created this name previously
  NSNotification *notification = [NSNotification notificationWithName: actionBarDidRevealNotification object:self];
  
  // send the selector to the delegate if it responds
  if([[self delegate] respondsToSelector:@selector(actionBarDidReveal:)])
  {
    [[self delegate] actionBarDidReveal:notification];
  }
  
  //in case something else cares.  Seems to be the pattern from the book but I don't know if we really need this
  [[NSNotificationCenter defaultCenter] postNotification:notification];
}

//Give the delegate a chance to not reveal the card
- (BOOL)_actionBarShouldReveal:(BOOL)reveal
{
  if([[self delegate] respondsToSelector:@selector(actionBarShouldReveal:shouldReveal:)])
  {
    reveal = [[self delegate] actionBarShouldReveal:self shouldReveal:reveal];
  }
  
  return reveal;
}

#pragma mark -
#pragma mark IBActions

- (IBAction) doNextCardBtn
{
  [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:@"actionBarButtonWasTapped" object:[NSNumber numberWithInt:NEXT_BTN]]];
}

- (IBAction) doPrevCardBtn
{
  [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:@"actionBarButtonWasTapped" object:[NSNumber numberWithInt:PREV_BTN]]];
}

- (IBAction) doBuryCardBtn
{
  [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:@"actionBarButtonWasTapped" object:[NSNumber numberWithInt:BURY_BTN]]];
}

- (IBAction) doRightBtn
{
  [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:@"actionBarButtonWasTapped" object:[NSNumber numberWithInt:RIGHT_BTN]]];
}

- (IBAction) doWrongBtn
{
  [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:@"actionBarButtonWasTapped" object:[NSNumber numberWithInt:WRONG_BTN]]];
}

- (IBAction) doRevealMeaningBtn
{
  [self reveal];
}

#pragma mark -
#pragma mark Core Class Methods

- (void) setup
{
  [self _actionBarWillSetup];
  [self _actionBarDidSetup];
}

- (void) reveal
{
  [self _actionBarWillReveal];
  [self _actionBarDidReveal];
}

#pragma mark -
#pragma mark Action Sheet

//! IBAction method - loads card action sheet so user can choose "add to set" or "report bad data"
- (IBAction) showCardActionSheet
{
  UIActionSheet *as = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Card Actions",@"ActionBarViewController.ActionSheetTitle") delegate:self
                                             cancelButtonTitle:NSLocalizedString(@"Cancel",@"ActionBarViewController.ActionSheetCancel") destructiveButtonTitle:nil
                                             otherButtonTitles:NSLocalizedString(@"Add to Study Set",@"ActionBarViewController.ActionSheetAddToSet"),
															   NSLocalizedString(@"Tweet Card",@"ActionBarViewController.ActionSheetTweet"),
                                                               NSLocalizedString(@"Fix Card",@"ActionBarViewController.ActionSheetReportBadData"),nil];

  jFlashAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
  [as showInView:[[appDelegate rootViewController]view]]; 
  [as release];
}

#pragma mark UIActionSheetDelegate methods - for "add to set" or "report bad data" action sheet

//! UIActionSheet delegate method - which modal do we load when the user taps "add to set" or "report bad data"
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
  // we present on the appDelegates root view controller to make sure it covers everything
  jFlashAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
  
  if (buttonIndex == SVC_ACTION_REPORT_BUTTON)
  {
    // TODO: iPad customization!
    ReportBadDataViewController* rbdvc = [[ReportBadDataViewController alloc] initWithNibName:@"ReportBadDataView" forBadCard:[self currentCard]];
    UINavigationController *modalNavController = [[UINavigationController alloc] initWithRootViewController:rbdvc];
    [appDelegate.rootViewController presentModalViewController:modalNavController animated:YES];
    [modalNavController release];
    [rbdvc release];
  }
  else if (buttonIndex == SVC_ACTION_ADDTOSET_BUTTON)
  {
    AddTagViewController *tmpVC = [[AddTagViewController alloc] initWithCard:[self currentCard]];
    
    // Set up DONE button
    UIBarButtonItem* doneBtn = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Done", @"AddTagViewController.NavDoneButtonTitle") style:UIBarButtonItemStyleBordered target:appDelegate.rootViewController action:@selector(dismissModalViewControllerAnimated:)];
    tmpVC.navigationItem.leftBarButtonItem = doneBtn;
    [doneBtn release];
    
    UINavigationController *modalNavControl = [[UINavigationController alloc] initWithRootViewController:tmpVC];
    [appDelegate.rootViewController presentModalViewController:modalNavControl animated:YES];
    [tmpVC release];
    [modalNavControl release];
  }
  else if(buttonIndex == SVC_ACTION_TWEET_BUTTON)
  {
	  [self tweet];
  }
  // FYI - Receiver is automatically dismissed after this method called, no need for resignFirstResponder 
}

#pragma mark -
#pragma mark UIAlertView delegate methods

/**
 * If the user tapped OK, Follow Long WEekend on Twitter
 */
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
  if (buttonIndex == LWE_ALERT_OK_BTN)
  {
    LWE_LOG(@"Following long weekend (twitter ID 65012024)");
    [self initTwitterEngine];
    [_twitterEngine follow:@"65012024"];
  }
}


#pragma mark -
#pragma mark Tweet Word Features

/**
 * Initialize the twitter engine class if not already done
 * If called twice, this method is pretty much a NOOP
 * However, tweet and any twitter "action" will nil out the Twitter Engine, so you have to call again
 */
- (void) initTwitterEngine
{
	NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
	NSString *idCurrentUser = [NSString stringWithFormat:@"%d", [settings integerForKey:@"user_id"]];
  
  // Init twitter engine if not already done
	if ((!_twitterEngine) && (_twitterEngine == nil))
	{
    TweetWordXAuthController *controller = [[TweetWordXAuthController alloc] initWithNibName:@"TweetWordXAuthController" bundle:nil];
		_twitterEngine = [[LWETwitterEngine alloc] initWithConsumerKey:JFLASH_TWITTER_CONSUMER_KEY privateKey:JFLASH_TWITTER_PRIVATE_KEY authenticationView:controller];
    [controller release];
	}
	
  // TODO: fix this so it doesn't use App Delegate - use notifications instead
	jFlashAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];	
	UIViewController *vc = (UIViewController *)appDelegate.rootViewController;
	_twitterEngine.parentForUserAuthenticationView = vc;
	[_twitterEngine setLoggedUser:[LWETUser userWithID:idCurrentUser] authMode:LWET_AUTH_XAUTH];
	_twitterEngine.delegate = self;
}

/**
 * Tweets the current word.
 */
- (void)tweet
{
  [self initTwitterEngine];
	
	if (_twitterEngine.loggedUser.isAuthenticated)
	{
		//Set all of the data 
		NSString *tweetWord = [self getTweetWord];
		
		TweetWordViewController *twitterController = [[TweetWordViewController alloc] 
													  initWithNibName:@"TweetWordViewController"  
													  twitterEngine:_twitterEngine 
													  tweetWord:tweetWord];
    
    NSDictionary *dict = [[NSDictionary alloc] initWithObjectsAndKeys:twitterController, @"controller", nil];
		[[NSNotificationCenter defaultCenter] postNotificationName:LWEShouldShowModal object:self userInfo:dict];
		[dict release];
	}
}

#pragma mark -
#pragma mark LWETRequestDelegate

/**
 * Callback - LWETRequestDelegate - processes result data
 */
- (void)didFinishProcessWithData:(NSData *)data
{
	[[NSNotificationCenter defaultCenter] postNotificationName:LWEShouldDismissModal object:self];
	
  [LWEUIAlertView notificationAlertWithTitle:NSLocalizedString(@"Tweeted", @"ActionBarViewController.TweetSuccessAlertTitle") 
                                     message:NSLocalizedString(@"Successfully added to your Twitter feed!", @"ActionBarViewController.TweetSuccessAlertMsg")];
  
	[_twitterEngine release];
	_twitterEngine = nil;
}

/**
 * Callback - LWETRequestDelegate - processes error data
 */
- (void) didFailedWithError:(NSError *)error
{
	[[NSNotificationCenter defaultCenter] postNotificationName:LWEShouldDismissModal object:self];

  NSInteger errorCode = [error code];
  
  //TODO - change these error codes to constants
  // This is the error when the user tweets the same thing twice
  if (errorCode == 1)
  {
    [LWEUIAlertView notificationAlertWithTitle:NSLocalizedString(@"Unable to Tweet", @"ActionBarViewController.TweetFailureAlertTitle")
                                       message:NSLocalizedString(@"Did you tweet the same thing twice in a row?  Twitter doesn't let us.", @"ActionBarViewController.TweetFailureAlertMsg")];    
  }
  // CFNetwork error
  else if (errorCode == -1009)
  {
    [LWEUIAlertView noNetworkAlert];
  }
  
	[_twitterEngine release];
	_twitterEngine = nil;
}

/**
 * Did successfully auth - now see if they are following long_weekend
 */
- (void)didFinishAuth
{
	NSString *tweetWord = [self getTweetWord];
	TweetWordViewController *twitterController = [[TweetWordViewController alloc] 
												  initWithNibName:@"TweetWordViewController"  
												  twitterEngine:_twitterEngine 
												  tweetWord:tweetWord];
	
  // Show an alert view asking if they want to follow LWE
  [LWEUIAlertView confirmationAlertWithTitle:NSLocalizedString(@"Follow Long Weekend?",@"ActionBarViewController.FollowLWEAlertTitle")
                                     message:NSLocalizedString(@"Great, you're logged in.  Want to follow us?  We tweet interesting stuff.",@"ActionBarViewController.FollowLWEAlertMsg")
                                          ok:NSLocalizedString(@"Sure",@"Global.Sure")
                                      cancel:NSLocalizedString(@"No Thanks",@"Global.NoThanks")
                                    delegate:self];
  
	[self performSelector:@selector(presentModal:) 
			   withObject:twitterController 
			   afterDelay:0];
	
	[twitterController release];
}

- (void)didFailedAuth:(NSError *)error
{
	if (error)
	{
		LWE_LOG(@"Did failed auth.");
    [LWEUIAlertView notificationAlertWithTitle:NSLocalizedString(@"Unable to Login",@"ActionBarViewController.TweetLoginFailureAlertTitle")
                                       message:NSLocalizedString(@"We were unable to log in to the Twitter server.  Do you have a network connection?",@"ActionBarViewController.TweetLoginFailureAlertMsg")];
	}
	[_twitterEngine release];
	_twitterEngine = nil;
}


-(void) presentModal:(UIViewController*)modalNavController
{
	LWE_LOG(@"Presenting the modal");
	NSDictionary *dict = [[NSDictionary alloc] initWithObjectsAndKeys:modalNavController, @"controller", nil];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:LWEShouldShowModal object:self userInfo:dict];
	[dict release];
	LWE_LOG(@"Done Sending the notification");
}

#pragma mark -
#pragma mark TweetWordMethod

//! get the tweet word and try to cut the maning of the tweet word so that it gives the result of NSString which is going to fit within the allocation of twitter status update
- (NSString *)getTweetWord
{
	//Set up the tweet word, so that the str will have the following format
	//Head Word [reading] meaning
	NSMutableString *str = [[NSMutableString alloc] init];
	[str appendFormat:@"%@ [%@] ", self.currentCard.headword, self.currentCard.reading];
	
	//but in some cases, the "meaning" length, can exceed the maximum length
	//of the twitter update status lenght, so it looks for "/" and cut the meaning
	//to fit in. 
	NSString *meaning = [self.currentCard meaningWithoutMarkup];
	NSInteger charLeft = kMaxChars - [str length];
	NSInteger charAfterMeaning = charLeft - [meaning length];
	if (charAfterMeaning <= 0)
	{
		NSRange rangeToLookFor;
		rangeToLookFor.length = charLeft;
		rangeToLookFor.location = 0;
		NSRange range = [meaning rangeOfString:@"/" 
									   options:NSBackwardsSearch
										 range:rangeToLookFor];
		
		meaning = [meaning substringToIndex:range.location];
	}
	LWE_LOG(@"LOG : This is the meaning : %@", meaning);
	[str appendString:meaning];						  
	
	NSString *result = [NSString stringWithString:str];
	[str release];
	return result;
}

#pragma mark -
#pragma mark Class Plumbing

- (void)viewDidUnload
{
  self.addBtn = nil;
  self.buryCardBtn = nil;
  self.nextCardBtn = nil;
  self.prevCardBtn = nil;
  self.rightBtn = nil;
  self.wrongBtn = nil;
}

- (void)dealloc
{
  [cardMeaningBtnHint release];
  [cardMeaningBtnHintMini release];
  
  [addBtn release];
  [buryCardBtn release];
  [nextCardBtn release];
  [prevCardBtn release];
  [rightBtn release];
  [wrongBtn release];
  [super dealloc];
}
@end

//! Notification names
NSString * const actionBarWillSetupNotification = @"actionBarWillSetupNotification";
NSString * const actionBarDidSetupNotification = @"actionBarDidSetupNotification";
NSString * const actionBarWillRevealNotification = @"actionBarWillRevealNotification";
NSString * const actionBarDidRevealNotification = @"actionBarDidRevealNotification";