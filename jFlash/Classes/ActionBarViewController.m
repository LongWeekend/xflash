//
//  ActionBarViewController.m
//  jFlash
//
//  Created by シャロット ロス on 6/4/10.
//  Copyright 2010 LONG WEEKEND INC. All rights reserved.
//

#import "ActionBarViewController.h"

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
                                             otherButtonTitles:NSLocalizedString(@"Tweet Card",@"ActionBarViewController.ActionSheetTweet"),
                                                               NSLocalizedString(@"Fix Card",@"ActionBarViewController.ActionSheetReportBadData"),
                                                               NSLocalizedString(@"Add to Study Set",@"ActionBarViewController.ActionSheetAddToSet"),nil];

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
    UIBarButtonItem* doneBtn = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Done",@"AddTagViewController.NavDoneButtonTitle") style:UIBarButtonItemStyleBordered target:appDelegate.rootViewController action:@selector(dismissModalViewControllerAnimated:)];
    tmpVC.navigationItem.leftBarButtonItem = doneBtn;
    [doneBtn release];
    
    UINavigationController *modalNavControl = [[UINavigationController alloc] initWithRootViewController:tmpVC];
    [appDelegate.rootViewController presentModalViewController:modalNavControl animated:YES];
    [tmpVC release];
    [modalNavControl release];
  }
  else if(buttonIndex == SVC_ACTION_TWEET_BUTTON)
  {
    // RENDE - DO THINGS HERE!!!!!!!!!!!
    // THIS IS THE DATA 
    NSString* tweet = [[NSString alloc] initWithFormat:@"%@", [self.currentCard headword]];
  }
  // FYI - Receiver is automatically dismissed after this method called, no need for resignFirstResponder 
}

#pragma mark -
#pragma mark Class Plumbing

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}

- (void)dealloc {
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
NSString  *actionBarWillSetupNotification = @"actionBarWillSetupNotification";
NSString  *actionBarDidSetupNotification = @"actionBarDidSetupNotification";
NSString  *actionBarWillRevealNotification = @"actionBarWillRevealNotification";
NSString  *actionBarDidRevealNotification = @"actionBarDidRevealNotification";