//
//  ActionBarViewController.m
//  jFlash
//
//  Created by シャロット ロス on 6/4/10.
//  Copyright 2010 LONG WEEKEND INC. All rights reserved.
//

#import "ActionBarViewController.h"
#import "RootViewController.h"
#import "LWEJanrainLoginManager.h"
#import "LWETwitterEngine.h"

NSString * const LWEActionBarButtonWasTapped = @"LWEActionBarButtonWasTapped";

@interface ActionBarViewController ()
- (void) _reportBadData;
- (void) _initTwitterEngine;
@end

@implementation ActionBarViewController
@synthesize delegate, currentCard;
@synthesize nextCardBtn, prevCardBtn, addBtn, rightBtn, wrongBtn, buryCardBtn;
@synthesize cardMeaningBtnHint;

// MMA: 11/14/2011 -- this method appears to be unused...
//Give the delegate a chance to not reveal the card
- (BOOL)_actionBarShouldReveal:(BOOL)reveal
{
  if (self.delegate && [self.delegate respondsToSelector:@selector(actionBarShouldReveal:)])
  {
    reveal = [self.delegate actionBarShouldReveal:self];
  }
  return reveal;
}

#pragma mark - StudyViewControllerDelegate

- (void) studyViewModeDidChange:(StudyViewController*)svc
{
  if (self.delegate && [self.delegate respondsToSelector:@selector(actionBarDidChangeMode::)])
  {
    [self.delegate actionBarDidChangeMode:self];
  }
}

#pragma mark - IBActions

- (IBAction) doNextCardBtn
{
  [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:LWEActionBarButtonWasTapped object:[NSNumber numberWithInt:NEXT_BTN]]];
}

- (IBAction) doPrevCardBtn
{
  [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:LWEActionBarButtonWasTapped object:[NSNumber numberWithInt:PREV_BTN]]];
}

- (IBAction) doBuryCardBtn
{
  [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:LWEActionBarButtonWasTapped object:[NSNumber numberWithInt:BURY_BTN]]];
}

- (IBAction) doRightBtn
{
  [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:LWEActionBarButtonWasTapped object:[NSNumber numberWithInt:RIGHT_BTN]]];
}

- (IBAction) doWrongBtn
{
  [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:LWEActionBarButtonWasTapped object:[NSNumber numberWithInt:WRONG_BTN]]];
}

- (IBAction) doRevealMeaningBtn
{
  [self reveal];
}

#pragma mark - Core Class Methods

- (void) setupWithCard:(Card *)card
{
  self.currentCard = card;
  LWE_DELEGATE_CALL(@selector(actionBarWillSetup:), self);
  LWE_DELEGATE_CALL(@selector(actionBarDidSetup:), self);
}

- (void) reveal
{
  LWE_DELEGATE_CALL(@selector(actionBarWillReveal:), self);
  LWE_DELEGATE_CALL(@selector(actionBarDidReveal:), self);
}

#pragma mark - Action Sheet

//! IBAction method - loads card action sheet so user can choose "add to set" or "report bad data"
- (IBAction) showCardActionSheet
{
  // Show them "remove" if they happen to be studying the favorites instead of "add to favorites".
  NSString *favoriteString = @"";
  Tag *favoritesTag = [[CurrentState sharedCurrentState] favoritesTag];
  if ([TagPeer card:self.currentCard isMemberOfTag:favoritesTag])
  {
    favoriteString = NSLocalizedString(@"Remove from Starred",@"ActionBarViewController.ActionSheetRemoveFromFavorites");
  }
  else
  {
    favoriteString = NSLocalizedString(@"Add to Starred",@"ActionBarViewController.ActionSheetAddToFavorites");
  }

  UIActionSheet *as = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Card Actions",@"ActionBarViewController.ActionSheetTitle") delegate:self
                                             cancelButtonTitle:NSLocalizedString(@"Cancel",@"ActionBarViewController.ActionSheetCancel") destructiveButtonTitle:nil
                                             otherButtonTitles:
                       favoriteString,
                       NSLocalizedString(@"Add to Study Set",@"ActionBarViewController.ActionSheetAddToSet"),
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
  Tag *favoritesTag = [[CurrentState sharedCurrentState] favoritesTag];
  if (buttonIndex == SVC_ACTION_REPORT_BUTTON)
  {
    [self _reportBadData];
  }
  else if (buttonIndex == SVC_ACTION_ADDTOSET_BUTTON)
  {
    AddTagViewController *tmpVC = [[AddTagViewController alloc] initWithCard:self.currentCard];
    tmpVC.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc]
                                               initWithTitle:NSLocalizedString(@"Done", @"AddTagViewController.NavDoneButtonTitle")
                                                       style:UIBarButtonItemStyleBordered
                                                      target:tmpVC
                                                     action:@selector(dismissModalViewControllerAnimated:)] autorelease];

    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:tmpVC,@"controller",
                              [NSNumber numberWithBool:YES],@"useNavController",nil];
    [tmpVC release];
    [[NSNotificationCenter defaultCenter] postNotificationName:LWEShouldShowModal object:self userInfo:userInfo];
  }
  else if (buttonIndex == SVC_ACTION_ADDTOFAV_BUTTON)
  {    
    // Do something here - subscribe or cancel, depending.
    if ([TagPeer card:self.currentCard isMemberOfTag:favoritesTag])
    {
      // First of all, do it
      NSError *error = nil;
      BOOL cancelled = [TagPeer cancelMembership:self.currentCard fromTag:favoritesTag error:&error];
      if (!cancelled)
      {
        if ([error code] == kRemoveLastCardOnATagError)
        {
          NSString *errorMessage = [error localizedDescription];
          [LWEUIAlertView notificationAlertWithTitle:NSLocalizedString(@"Last Card in Set", @"AddTagViewController.AlertViewLastCardTitle")
                                             message:errorMessage];
        }
        else
        {
          LWE_LOG_ERROR(@"[UNKNOWN ERROR]%@", error);
        }
        return;
      }
    }
    else
    {
      [TagPeer subscribeCard:self.currentCard toTag:favoritesTag];
    }

  }
  else if (buttonIndex == SVC_ACTION_TWEET_BUTTON)
  {
    // couldn't quite get this working the way I wanted. Good idea in the future but stopping for now.
//    [[LWEJanrainLoginManager sharedLWEJanrainLoginManager] share:@"found a word with Japanese Flash" 
//                                                           andUrl:@"http://su.pr/1TZSd4" 
//                                                           userContentOrNil:[self getTweetWord]];
	  [self tweet];
  }
}

#pragma mark - MailCompose helper & delegate method

- (void) _reportBadData
{
  if ([MFMailComposeViewController canSendMail]) 
  {
    MFMailComposeViewController *picker = [[MFMailComposeViewController alloc] init];
    picker.mailComposeDelegate = self;
    [picker setSubject:@"Bad Data"];
    [picker setToRecipients:[NSArray arrayWithObjects:LWE_BAD_DATA_EMAIL, nil]];
    
    Tag *tmpTag = [[CurrentState sharedCurrentState] activeTag];
    NSString *messageBody = [NSString stringWithFormat:@"How can we make this awesome?\n\n\n\nInfo For Long Weekend:\n\nCard Id: %i\nCard Headword: %@\nCard Meaning: %@\nActive Tag Id: %i\nActive Tag Name: %@", self.currentCard.cardId, self.currentCard.headword, self.currentCard.meaningWithoutMarkup, tmpTag.tagId, tmpTag.tagName];
    
    [picker setMessageBody:messageBody isHTML:NO];
    
    jFlashAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    [appDelegate.rootViewController presentModalViewController:picker animated:YES];
    [picker release];
  }
  else 
  {
    [LWEUIAlertView notificationAlertWithTitle:NSLocalizedString(@"Email Not Available", @"emailVM.notAvailable.title")
                                       message:NSLocalizedString(@"Oh no!! We can't send mail right now.", @"emailVM.notAvailable.body")];
    
  }
}

//! Called when dismissing email composer
- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
  // remove the mail modal
  jFlashAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
  [appDelegate.rootViewController dismissModalViewControllerAnimated:YES];
}

#pragma mark - UIAlertView delegate methods

/**
 * If the user tapped OK, Follow Long WEekend on Twitter
 */
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
  if (buttonIndex == LWE_ALERT_OK_BTN)
  {
    LWE_LOG(@"Following long weekend (twitter ID 65012024)");
    [self _initTwitterEngine];
		[_twitterEngine performSelectorInBackground:@selector(follow:) withObject:@"65012024"];
  }
}

#pragma mark - Tweet Word Features

/**
 * Initialize the twitter engine class if not already done
 * If called twice, this method is pretty much a NOOP
 * However, tweet and any twitter "action" will nil out the Twitter Engine, so you have to call again
 */
- (void) _initTwitterEngine
{
	NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
	NSString *idCurrentUser = [NSString stringWithFormat:@"%d", [settings integerForKey:@"user_id"]];
  
  // Init twitter engine if not already done
	if (_twitterEngine == nil)
	{
    TweetWordXAuthController *controller = [[TweetWordXAuthController alloc] initWithNibName:@"TweetWordXAuthController" bundle:nil];
		_twitterEngine = [[LWETwitterEngine alloc] initWithConsumerKey:JFLASH_TWITTER_CONSUMER_KEY privateKey:JFLASH_TWITTER_PRIVATE_KEY authenticationView:controller];
    [controller release];
	}

  // TODO: fix this so it doesn't use App Delegate - use notifications instead
	jFlashAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];	
	UIViewController *vc = (UIViewController *)appDelegate.rootViewController;
	_twitterEngine.parentForUserAuthenticationView = vc;
	LWE_LOG(@"changed the user for twitter with user id %@", idCurrentUser);
	[_twitterEngine setLoggedUser:[LWETUser userWithID:idCurrentUser] authMode:LWET_AUTH_XAUTH];
	_twitterEngine.delegate = self;
}

/**
 * Tweets the current word.
 */
- (void)tweet
{
  [self _initTwitterEngine];
	
	if ((_twitterEngine.loggedUser != nil) && (_twitterEngine.loggedUser.isAuthenticated))
	{
		LWE_LOG(@"It tries to open up the tweet this words controller");
		//Set all of the data 
		NSString *tweetWord = [self getTweetWord];
		TweetWordViewController *twitterController = [[TweetWordViewController alloc] 
													  initWithNibName:@"TweetWordViewController"  
													  twitterEngine:_twitterEngine 
													  tweetWord:tweetWord];
    
    NSDictionary *dict = [[NSDictionary alloc] initWithObjectsAndKeys:twitterController, @"controller", nil];
		[[NSNotificationCenter defaultCenter] postNotificationName:LWEShouldShowModal object:self userInfo:dict];
		[twitterController release];
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
  LWE_LOG(@"Successfully tweeted");
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

  if (error.domain == LWETwitterErrorDomain && error.code == LWETwitterErrorUnableToSendTweet)
  {
    [LWEUIAlertView notificationAlertWithTitle:NSLocalizedString(@"Unable to Tweet", @"ActionBarViewController.TweetFailureAlertTitle")
                                       message:NSLocalizedString(@"Did you tweet the same thing twice in a row?  Twitter doesn't let us.", @"ActionBarViewController.TweetFailureAlertMsg")];    
  }
  else if (error.domain == NSURLErrorDomain && error.code == NSURLErrorNotConnectedToInternet)
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
	TweetWordViewController *twitterController = [[TweetWordViewController alloc] initWithNibName:@"TweetWordViewController"  
                                                                                  twitterEngine:_twitterEngine 
                                                                                      tweetWord:tweetWord];
	
  // Show an alert view asking if they want to follow LWE
  [LWEUIAlertView confirmationAlertWithTitle:NSLocalizedString(@"Follow Long Weekend?",@"ActionBarViewController.FollowLWEAlertTitle")
                                     message:NSLocalizedString(@"Great, you're logged in.  Want to follow us?  We tweet interesting stuff.",@"ActionBarViewController.FollowLWEAlertMsg")
                                          ok:NSLocalizedString(@"Sure",@"Global.Sure")
                                      cancel:NSLocalizedString(@"No Thanks",@"Global.NoThanks")
                                    delegate:self];
  
  // TODO: Why is this here?  MMA - 11/14/2011
	[self performSelector:@selector(presentModal:) withObject:twitterController afterDelay:0.1f];
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
	NSMutableString *str = nil; 
  
	//Set up the tweet word, so that the str will have the following format
	//Head Word [reading] meaning

  // Get the lengths of everyone involved
  NSInteger headwordLength = [self.currentCard.headword length];
  NSInteger readingLength = [self.currentCard.reading length];
  NSInteger meaningLength = [[self.currentCard meaningWithoutMarkup] length];
  
  // Now go from most conservative (headword exceeds kMaxChars) 
  // to most liberal (the whole thing fits in kMaxChars)  
  if (headwordLength > kMaxChars)
  {
    // Headword alone is longer than kMaxChars
    str = [[NSMutableString alloc] initWithFormat:@"%@", [self.currentCard.headword substringToIndex:kMaxChars]];
  }
  else
  {
    // Add four because we add brackets and spaces
    if ((headwordLength + readingLength + 4) > kMaxChars)
    {
      // Headword + reading is too long, so just use headword.
      str = [[NSMutableString alloc] initWithFormat:@"%@",self.currentCard.headword];
    }
    else
    {
      str = [[NSMutableString alloc] initWithFormat:@"%@ [%@] ",self.currentCard.headword,self.currentCard.reading];
    }
  }

  // Now determine if we have any space left for a meaning.
	NSInteger charLeftBeforeMeaning = kMaxChars - [str length];
  
  // If there are less than 5, just ignore - not worth it
  if (charLeftBeforeMeaning > 5)
  {
    NSString *meaning = [self.currentCard meaningWithoutMarkup];
    NSInteger charLeftAfterMeaning = charLeftBeforeMeaning - meaningLength;
    //but in some cases, the "meaning" length, can exceed the maximum length
    //of the twitter update status lenght, so it looks for "/" and cut the meaning
    //to fit in. 
    if (charLeftAfterMeaning < 0)
    {
      NSRange range = [meaning rangeOfString:@"/" options:NSBackwardsSearch];
      if (range.location != NSNotFound && (range.location < charLeftBeforeMeaning))
      {
        // We got one, and it fits
        // This is still a naive implementation, it should recursively chop off slashes until it fits...
        // AT present it only does it once
        [str appendString:[meaning substringToIndex:range.location]];
      }
      else
      {
        // Simple truncate
        [str appendString:[meaning substringToIndex:charLeftBeforeMeaning]];
      }
    }
    else
    {
      // Enough room for the whole meaning
      [str appendString:meaning];
    }
  } 
  
  // Debug output
  LWE_LOG(@"Tweet string: %@",str);
  LWE_LOG(@"Tweet length: %d",[str length]);
  
	return (NSString*)[str autorelease];
}

#pragma mark - Class Plumbing

- (void)didReceiveMemoryWarning
{
	if (_twitterEngine != nil)
	{
		[_twitterEngine release];
		_twitterEngine = nil;
	}

	[super didReceiveMemoryWarning];
}

- (void)viewDidUnload
{
	[super viewDidUnload];
	
  self.addBtn = nil;
  self.buryCardBtn = nil;
  self.nextCardBtn = nil;
  self.prevCardBtn = nil;
  self.rightBtn = nil;
  self.wrongBtn = nil;
	self.cardMeaningBtnHint = nil;
}

- (void)dealloc
{
	[currentCard release];
  [cardMeaningBtnHint release];
  
	if (_twitterEngine != nil)
	{
		[_twitterEngine release];
		_twitterEngine = nil;
	}
	
  [addBtn release];
  [buryCardBtn release];
  [nextCardBtn release];
  [prevCardBtn release];
  [rightBtn release];
  [wrongBtn release];
  [super dealloc];
}
@end
