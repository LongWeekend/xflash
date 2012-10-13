//
//  ActionBarViewController.m
//  jFlash
//
//  Created by シャロット ロス on 6/4/10.
//  Copyright 2010 LONG WEEKEND INC. All rights reserved.
//

#import "ActionBarViewController.h"
#import <Twitter/Twitter.h>

@interface ActionBarViewController ()
- (void) _reportBadData;
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
  if (self.delegate && [self.delegate respondsToSelector:@selector(actionBarDidChangeMode:)])
  {
    [self.delegate actionBarDidChangeMode:self];
  }
}

#pragma mark - IBActions

//! IBAction method - loads card action sheet so user can choose "add to set" or "report bad data"
- (IBAction) showCardActionSheet
{
  // Show them "remove" if they happen to be studying the favorites instead of "add to favorites".
  NSString *favoriteString = @"";
  Tag *starredTag = [[CurrentState sharedCurrentState] starredTag];
  if ([TagPeer card:self.currentCard isMemberOfTag:starredTag])
  {
    favoriteString = NSLocalizedString(@"Remove from Starred",@"ActionBarViewController.ActionSheetRemoveFromFavorites");
  }
  else
  {
    favoriteString = NSLocalizedString(@"Add to Starred",@"ActionBarViewController.ActionSheetAddToFavorites");
  }
  
  UIActionSheet *as = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Card Actions",@"ActionBarViewController.ActionSheetTitle") delegate:self
                                         cancelButtonTitle:NSLocalizedString(@"Cancel",@"ActionBarViewController.ActionSheetCancel")
                                    destructiveButtonTitle:nil
                                         otherButtonTitles:favoriteString,
                                                           NSLocalizedString(@"Add to Study Set",@"ActionBarViewController.ActionSheetAddToSet"),
                                                           NSLocalizedString(@"Fix Card",@"ActionBarViewController.ActionSheetReportBadData"),
                                                           NSLocalizedString(@"Tweet This Card",@"ActionBarViewController.ActionSheetTweet"),
                                                           NSLocalizedString(@"Post On Facebook",@"Action Sheet Button to post on FB"),nil];
  
  // Yes, there is a showInTabBar: which seems like it might be good, but it makes the BG of the action sheet
  // REALLY black.  You don't want it, trust me - MMA
  jFlashAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
  [as showInView:appDelegate.tabBarController.view];
  [as release];
}

#pragma mark - SVC Subcontroller Delegate Implementation

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

#pragma mark - UIActionSheetDelegate methods

//! UIActionSheet delegate method - which modal do we load when the user taps "add to set" or "report bad data"
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
  Tag *favoritesTag = [[CurrentState sharedCurrentState] starredTag];
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
      BOOL removed = [TagPeer cancelMembership:self.currentCard fromTag:favoritesTag error:&error];
      if (removed == NO)
      {
        if (error.code == kRemoveLastCardOnATagError)
        {
          NSString *errorMessage = [error localizedDescription];
          [LWEUIAlertView notificationAlertWithTitle:NSLocalizedString(@"Last Card in Set", @"AddTagViewController.AlertViewLastCardTitle")
                                             message:errorMessage];
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
	  [self tweet];
  }
  else if (buttonIndex == SVC_ACTION_FACEBOOK_BUTTON)
  {
    [self postToFacebook];
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
    [appDelegate.tabBarController presentModalViewController:picker animated:YES];
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
  [controller dismissModalViewControllerAnimated:YES];
}

#pragma mark - UIAlertView delegate methods

/**
 * Tweets the current word.
 */
- (void)tweet
{
  Class tweetClass = NSClassFromString(@"TWTweetComposeViewController");
  if (tweetClass == nil)
  {
    // This would be iOS4, ladies & gentlemen
    [LWEUIAlertView notificationAlertWithTitle:NSLocalizedString(@"iOS5 Required", @"Cannot Tweet Title - iOS4")
                                       message:NSLocalizedString(@"Look, we're really sorry.  Apple added Twitter support into iOS5 - might we recommend you upgrade?", @"Cannot Tweet Msg - iOS4")];
    return;
  }
  
  NSString *tweet = [NSString stringWithFormat:@"%@ %@",[self getTweetWord],LWE_TWITTER_HASH_TAG];
  tweetClass = NSClassFromString(@"SLComposeViewController");
  if(tweetClass == nil)
  {
    // iOS 5 goodness here
    // OK, now let's see if they CAN tweet
    BOOL canTweet = [TWTweetComposeViewController canSendTweet];
    if (canTweet == NO)
    {
      [LWEUIAlertView notificationAlertWithTitle:NSLocalizedString(@"Twitter Not Set Up", @"Cannot Tweet Title - iOS5")
                                         message:NSLocalizedString(@"Seems like Twitter isn't set up.   Visit the Apple Settings app, and scroll down to 'Twitter'.", @"Cannot Tweet Msg - iOS5")];
      return;
    }
    // OK, tweet
    TWTweetComposeViewController *tweetVC = [[[TWTweetComposeViewController alloc] init] autorelease];
    [tweetVC setInitialText:tweet];
    tweetVC.completionHandler = ^(TWTweetComposeViewControllerResult result){
      if (result == TWTweetComposeViewControllerResultDone)
      {
        // OK, they tweeted.
        [self dismissModalViewControllerAnimated:YES];
      }
    };
    [self presentModalViewController:tweetVC animated:YES];
  }
  else
  {
    SLComposeViewController *tweetVC = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeTwitter];
    [tweetVC setInitialText:tweet];
    tweetVC.completionHandler = ^(SLComposeViewControllerResult result){
      if (result == SLComposeViewControllerResultDone)
      {
        // OK, they tweeted.
        [self dismissModalViewControllerAnimated:YES];
      }
    };
    [self presentModalViewController:tweetVC animated:YES];
  }
}

- (void) postToFacebook
{
  Class socialClass = NSClassFromString(@"SLComposeViewController");
  if(socialClass != nil && [SLComposeViewController isAvailableForServiceType:SLServiceTypeFacebook])
  {  
    SLComposeViewController *controller = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeFacebook];
    
    SLComposeViewControllerCompletionHandler completionBlock = ^(SLComposeViewControllerResult result){
      if (result == SLComposeViewControllerResultCancelled)
      {
        LWE_LOG(@"Cancelled");
      }
      else
      {
        LWE_LOG(@"Posted to facebook");
      }
      [controller dismissViewControllerAnimated:YES completion:Nil];
    };
    controller.completionHandler = completionBlock;
    
    [controller setInitialText:[self getTweetWord]];
    [controller addURL:[NSURL URLWithString:@"http://www.japaneseflash.com"]];
    
    [self presentViewController:controller animated:YES completion:Nil];    
  }
  else
  {
    [LWEUIAlertView notificationAlertWithTitle:NSLocalizedString(@"Facebook Not Available", @"Cannot Post To Facebook Title - iOS6")
                                       message:NSLocalizedString(@"We're sorry. Posting to Facebook is only available on iOS6 and above.", @"Cannot Post To FB Msg - iOS5")];
    return;
  }
}

#pragma mark - TweetWordMethod

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
  
  // Now go from most conservative (headword exceeds LWE_TWITTER_MAX_CHARS) 
  // to most liberal (the whole thing fits in LWE_TWITTER_MAX_CHARS)  
  if (headwordLength > LWE_TWITTER_MAX_CHARS)
  {
    // Headword alone is longer than kMaxChars
    str = [[NSMutableString alloc] initWithFormat:@"%@", [self.currentCard.headword substringToIndex:LWE_TWITTER_MAX_CHARS]];
  }
  else
  {
    // Add four because we add brackets and spaces
    if ((headwordLength + readingLength + 4) > LWE_TWITTER_MAX_CHARS)
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
	NSInteger charLeftBeforeMeaning = LWE_TWITTER_MAX_CHARS - [str length];
  
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
  [addBtn release];
  [buryCardBtn release];
  [nextCardBtn release];
  [prevCardBtn release];
  [rightBtn release];
  [wrongBtn release];
  [super dealloc];
}
@end
