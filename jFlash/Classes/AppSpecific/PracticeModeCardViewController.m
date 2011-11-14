//
//  PracticeModeCardViewDelegate.m
//  jFlash
//
//  Created by シャロット ロス on 6/1/10.
//  Copyright 2010 LONG WEEKEND INC.. All rights reserved.
//

#import "PracticeModeCardViewController.h"

#import "CardViewController.h"
#import "ActionBarViewController.h"
#import "StudyViewController.h"

@implementation PracticeModeCardViewController
@synthesize wordCardViewController;

#pragma mark - Card View Controller Delegate

- (void)cardViewWillSetup:(CardViewController*)cardViewController
{
  cardViewController.view = self.wordCardViewController.view;
  [self.wordCardViewController prepareView:cardViewController.currentCard];

  // always start with the meaning hidden
  [self.wordCardViewController hideMeaningWebView:YES];
  [self.wordCardViewController resetReadingVisibility];
  
  NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
  BOOL useMainHeadword = [[settings objectForKey:APP_HEADWORD] isEqualToString:SET_J_TO_E];
  if (useMainHeadword == NO)
  {
    self.wordCardViewController.toggleReadingBtn.hidden = YES;
    self.wordCardViewController.cardReadingLabelScrollContainer.hidden = YES;
    self.wordCardViewController.readingVisible = NO;
  }
  else
  {
    // set the toggleReadingBtn to not hidden for other modes,
    // if this is not here the button can be missing in practice mode
    self.wordCardViewController.toggleReadingBtn.hidden = NO;
  }
}

- (BOOL)cardView:(CardViewController*)cvc shouldReveal:(BOOL)shouldReveal;
{
  return YES;
}

- (void)cardViewDidReveal:(CardViewController*)cardViewController
{
  [self.wordCardViewController hideMeaningWebView:NO];
  
  // TODO: MMA why are we caching the value of this only to change it on the next line?
  // EDIT: I guess this is because we show the card AFTER reveal, but want it to be hidden again
  // on the next card (in practice mode)
  BOOL userSetReadingVisible = self.wordCardViewController.readingVisible;
  [self.wordCardViewController turnReadingOn];
  self.wordCardViewController.readingVisible = userSetReadingVisible;
}

- (void) refreshSessionDetailsViews:(StudyViewController*)svc
{
  NSInteger unseen = [[svc.currentCardSet.cardLevelCounts objectAtIndex:0] intValue];
  NSInteger total = svc.currentCardSet.cardCount;
  svc.remainingCardsLabel.text = [NSString stringWithFormat:@"%d / %d",unseen,total];
  [self.wordCardViewController turnPercentCorrectOn];
  
  // If practice mode, show the quiz stuff.
  svc.tapForAnswerImage.hidden = NO;
  svc.revealCardBtn.hidden = NO;
  
  // Update the speech bubble
  
  // Update mood icon
  CGFloat tmpRatio = 100;
  if (svc.numViewed > 0)
  {
    tmpRatio = 100*((CGFloat)svc.numRight / (CGFloat)svc.numViewed);
  }
  [self.wordCardViewController.moodIcon updateMoodIcon:tmpRatio];
}

- (void) setupViews:(StudyViewController *)svc
{
	// In practice mode, scroll view should always start disabled
  svc.scrollView.pagingEnabled = NO;
  svc.scrollView.scrollEnabled = NO;
}

- (void)studyModeDidChange:(StudyViewController*)svc
{
  // You can tap the HH in practice mode.
  self.wordCardViewController.moodIconBtn.enabled = YES;
  
  // Change action bar view to other XIB
  [[NSBundle mainBundle] loadNibNamed:@"ActionBarViewController" owner:svc.actionBarController options:nil];
}

#pragma mark - Action Bar Delegate Methods

-(void) actionBarWillSetup:(ActionBarViewController*)avc
{
  // Hide all the buttons but show the hint
  avc.rightBtn.hidden = YES;
  avc.wrongBtn.hidden = YES;
  avc.buryCardBtn.hidden = YES;
  avc.addBtn.hidden = YES;
  avc.cardMeaningBtnHint.hidden = NO;
}

-(void) actionBarWillReveal:(ActionBarViewController*)avc
{
  // Show all the buttons & hide the hint
  avc.rightBtn.hidden = NO;
  avc.wrongBtn.hidden = NO;
  avc.buryCardBtn.hidden = NO;
  avc.addBtn.hidden = NO;
  avc.cardMeaningBtnHint.hidden = YES;
}

#pragma mark - Class Plumbing

- (id) init
{
  self = [super init];
  if (self)
  {
    NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
    BOOL useMainHeadword = [[settings objectForKey:APP_HEADWORD] isEqualToString:SET_J_TO_E];
    self.wordCardViewController = [[[WordCardViewController alloc] initDisplayMainHeadword:useMainHeadword] autorelease];
  }
  return self;
}

- (void)dealloc 
{
  [wordCardViewController release];
  [super dealloc];
}

@end