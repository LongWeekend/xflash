//
//  ActionBarViewController.m
//  jFlash
//
//  Created by シャロット ロス on 6/4/10.
//  Copyright 2010 LONG WEEKEND INC. All rights reserved.
//

#import "ActionBarViewController.h"

@interface ActionBarViewController ()
- (void) _reportBadData;
- (void) _applyModernStyle:(UIButton *)btn symbolName:(NSString *)name label:(NSString *)labelText color:(UIColor *)color;
@end

@implementation ActionBarViewController
@synthesize delegate, currentCard;
@synthesize nextCardBtn, prevCardBtn, addBtn, rightBtn, wrongBtn, buryCardBtn;
@synthesize cardMeaningBtnHint;

#pragma mark - View lifecycle

- (void)viewDidLoad
{
  [super viewDidLoad];
  if (@available(iOS 13.0, *)) {
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    [self _applyModernStyle:self.addBtn      symbolName:@"plus.circle.fill"      label:@"actions" color:[UIColor systemBlueColor]];
    [self _applyModernStyle:self.rightBtn    symbolName:@"checkmark.circle.fill" label:@"right"   color:[UIColor systemGreenColor]];
    [self _applyModernStyle:self.wrongBtn    symbolName:@"xmark.circle.fill"     label:@"wrong"   color:[UIColor systemRedColor]];
    [self _applyModernStyle:self.buryCardBtn symbolName:@"archivebox.circle.fill" label:@"bury it" color:[UIColor systemOrangeColor]];
  }
}

- (void)_applyModernStyle:(UIButton *)btn symbolName:(NSString *)name label:(NSString *)labelText color:(UIColor *)color
{
  if (!btn) return;
  if (@available(iOS 13.0, *)) {
    UIImage *icon = [UIImage systemImageNamed:name];
    if (icon) {
      UIImageSymbolConfiguration *config = [UIImageSymbolConfiguration configurationWithPointSize:34 weight:UIImageSymbolWeightMedium];
      icon = [icon imageByApplyingSymbolConfiguration:config];
    }
    [btn setImage:icon forState:UIControlStateNormal];
    [btn setImage:nil forState:UIControlStateHighlighted];
    [btn setBackgroundImage:nil forState:UIControlStateNormal];
    [btn setBackgroundImage:nil forState:UIControlStateHighlighted];
    [btn setTitle:@"" forState:UIControlStateNormal];
    btn.tintColor = color;
    btn.backgroundColor = [UIColor clearColor];

    UILabel *lbl = (UILabel *)[btn viewWithTag:9002];
    if (!lbl) {
      lbl = [[UILabel alloc] init];
      lbl.tag = 9002;
      lbl.textAlignment = NSTextAlignmentCenter;
      lbl.font = [UIFont systemFontOfSize:11 weight:UIFontWeightMedium];
      lbl.textColor = [UIColor secondaryLabelColor];
      [btn addSubview:lbl];
      [lbl release];
    }
    lbl.text = labelText;
  }
}

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
                                                           NSLocalizedString(@"Share This Card",@"Action Sheet Button to post on FB"),nil];
  
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
  else if (buttonIndex == SVC_ACTION_SHARE_BUTTON)
  {
    [self shareWord];
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

- (void) shareWord
{
  NSMutableArray *sharingItems = [NSMutableArray new];
  [sharingItems addObject:[self getTweetWord]];
  [sharingItems addObject:@"https://itunes.apple.com/us/app/japanese-flash-vocabulary/id367216357?mt=8"];
          
  UIActivityViewController *activityController = [[UIActivityViewController alloc] initWithActivityItems:sharingItems applicationActivities:nil];
  [self presentViewController:activityController animated:YES completion:nil];
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

#pragma mark - Layout

- (void)distributeButtonsEvenly
{
  CGFloat width = self.view.bounds.size.width;
  if (width <= 0) return;

  NSMutableArray *buttons = [NSMutableArray array];
  if (self.prevCardBtn) [buttons addObject:self.prevCardBtn];
  if (self.addBtn)      [buttons addObject:self.addBtn];
  if (self.rightBtn)    [buttons addObject:self.rightBtn];
  if (self.wrongBtn)    [buttons addObject:self.wrongBtn];
  if (self.buryCardBtn) [buttons addObject:self.buryCardBtn];
  if (self.nextCardBtn) [buttons addObject:self.nextCardBtn];

  if (buttons.count == 0) return;

  CGFloat totalBtnWidth = 0;
  for (UIButton *btn in buttons) totalBtnWidth += btn.bounds.size.width;
  CGFloat gap = (width - totalBtnWidth) / ((CGFloat)buttons.count + 1);

  CGFloat x = gap;
  for (UIButton *btn in buttons) {
    CGRect f = btn.frame;
    f.origin.x = roundf(x);
    btn.frame = f;
    x += f.size.width + gap;
  }
}

- (void)viewDidLayoutSubviews
{
  [super viewDidLayoutSubviews];
  [self distributeButtonsEvenly];

  if (@available(iOS 13.0, *)) {
    NSMutableArray *btns = [NSMutableArray array];
    if (self.addBtn)      [btns addObject:self.addBtn];
    if (self.rightBtn)    [btns addObject:self.rightBtn];
    if (self.wrongBtn)    [btns addObject:self.wrongBtn];
    if (self.buryCardBtn) [btns addObject:self.buryCardBtn];
    for (UIButton *btn in btns) {
      UILabel *lbl = (UILabel *)[btn viewWithTag:9002];
      if (lbl) {
        [lbl sizeToFit];
        CGFloat bW = btn.bounds.size.width;
        CGFloat bH = btn.bounds.size.height;
        lbl.frame = CGRectMake(0, bH - lbl.bounds.size.height - 5, bW, lbl.bounds.size.height);
      }
    }
  }
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
