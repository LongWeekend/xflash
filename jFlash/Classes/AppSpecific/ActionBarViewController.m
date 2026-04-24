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
    [self _applyModernStyle:self.addBtn      symbolName:@"plus.circle.fill"           label:@"actions" color:[UIColor systemBlueColor]];
    [self _applyModernStyle:self.rightBtn    symbolName:@"checkmark.circle.fill"      label:@"right"   color:[UIColor systemGreenColor]];
    [self _applyModernStyle:self.wrongBtn    symbolName:@"xmark.circle.fill"          label:@"wrong"   color:[UIColor systemRedColor]];
    [self _applyModernStyle:self.buryCardBtn symbolName:@"archivebox.circle.fill"     label:@"bury it" color:[UIColor systemOrangeColor]];
    [self _applyModernStyle:self.prevCardBtn symbolName:@"chevron.left.circle.fill"   label:@"prev"    color:[UIColor systemGrayColor]];
    [self _applyModernStyle:self.nextCardBtn symbolName:@"chevron.right.circle.fill"  label:@"next"    color:[UIColor systemGrayColor]];
  }
}

- (void)_applyModernStyle:(UIButton *)btn symbolName:(NSString *)name label:(NSString *)labelText color:(UIColor *)color
{
  if (!btn) return;
  if (@available(iOS 13.0, *)) {
    UIImage *icon = [UIImage systemImageNamed:name];
    if (icon) {
      UIImageSymbolConfiguration *config = [UIImageSymbolConfiguration configurationWithPointSize:44 weight:UIImageSymbolWeightMedium];
      icon = [icon imageByApplyingSymbolConfiguration:config];
    }
    [btn setImage:icon forState:UIControlStateNormal];
    [btn setImage:nil forState:UIControlStateHighlighted];
    [btn setBackgroundImage:nil forState:UIControlStateNormal];
    [btn setBackgroundImage:nil forState:UIControlStateHighlighted];
    [btn setTitle:@"" forState:UIControlStateNormal];
    btn.tintColor = color;
    btn.backgroundColor = [UIColor clearColor];
    btn.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 20, 0);

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

//! IBAction method - shows card action sheet for starred, add to set, fix, and share
- (IBAction) showCardActionSheet
{
  Tag *starredTag = [[CurrentState sharedCurrentState] starredTag];
  NSString *favoriteTitle = [TagPeer card:self.currentCard isMemberOfTag:starredTag]
    ? NSLocalizedString(@"Remove from Starred", @"ActionBarViewController.ActionSheetRemoveFromFavorites")
    : NSLocalizedString(@"Add to Starred",       @"ActionBarViewController.ActionSheetAddToFavorites");

  UIAlertController *sheet = [UIAlertController
    alertControllerWithTitle:NSLocalizedString(@"Card Actions", @"ActionBarViewController.ActionSheetTitle")
                     message:nil
              preferredStyle:UIAlertControllerStyleActionSheet];

  Card *card = self.currentCard;
  Tag  *favTag = starredTag;

  [sheet addAction:[UIAlertAction actionWithTitle:favoriteTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
    if ([TagPeer card:card isMemberOfTag:favTag]) {
      NSError *err = nil;
      BOOL removed = [TagPeer cancelMembership:card fromTag:favTag error:&err];
      if (!removed && err.code == kRemoveLastCardOnATagError) {
        [LWEUIAlertView notificationAlertWithTitle:NSLocalizedString(@"Last Card in Set", @"AddTagViewController.AlertViewLastCardTitle")
                                           message:[err localizedDescription]];
      }
    } else {
      [TagPeer subscribeCard:card toTag:favTag];
    }
  }]];

  [sheet addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Add to Study Set", @"ActionBarViewController.ActionSheetAddToSet") style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
    AddTagViewController *tmpVC = [[AddTagViewController alloc] initWithCard:card];
    tmpVC.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc]
      initWithTitle:NSLocalizedString(@"Done", @"AddTagViewController.NavDoneButtonTitle")
              style:UIBarButtonItemStyleBordered
             target:tmpVC
             action:@selector(dismissModalViewControllerAnimated:)] autorelease];
    NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:tmpVC, @"controller",
                          [NSNumber numberWithBool:YES], @"useNavController", nil];
    [tmpVC release];
    [[NSNotificationCenter defaultCenter] postNotificationName:LWEShouldShowModal object:self userInfo:info];
  }]];

  [sheet addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Fix Card", @"ActionBarViewController.ActionSheetReportBadData") style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
    [self _reportBadData];
  }]];

  [sheet addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Share This Card", @"Action Sheet Button to post on FB") style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
    [self shareWord];
  }]];

  [sheet addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"ActionBarViewController.ActionSheetCancel") style:UIAlertActionStyleCancel handler:nil]];

  // iPad needs a source for the popover anchor
  sheet.popoverPresentationController.sourceView = self.addBtn;
  sheet.popoverPresentationController.sourceRect = self.addBtn.bounds;

  [self presentViewController:sheet animated:YES completion:nil];
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
  CGFloat height = self.view.bounds.size.height;
  if (width <= 0 || height <= 0) return;

  NSMutableArray *buttons = [NSMutableArray array];
  if (self.prevCardBtn) [buttons addObject:self.prevCardBtn];
  if (self.addBtn)      [buttons addObject:self.addBtn];
  if (self.rightBtn)    [buttons addObject:self.rightBtn];
  if (self.wrongBtn)    [buttons addObject:self.wrongBtn];
  if (self.buryCardBtn) [buttons addObject:self.buryCardBtn];
  if (self.nextCardBtn) [buttons addObject:self.nextCardBtn];

  if (buttons.count == 0) return;

  CGFloat btnWidth = floorf(width / (CGFloat)buttons.count);
  for (NSUInteger i = 0; i < buttons.count; i++) {
    UIButton *btn = buttons[i];
    CGFloat x = i * btnWidth;
    CGFloat w = (i == buttons.count - 1) ? (width - x) : btnWidth;
    btn.frame = CGRectMake(x, 0, w, height);
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
    if (self.prevCardBtn) [btns addObject:self.prevCardBtn];
    if (self.nextCardBtn) [btns addObject:self.nextCardBtn];
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
