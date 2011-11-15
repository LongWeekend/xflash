//
//  PracticeModeCardViewDelegate.m
//  jFlash
//
//  Created by シャロット ロス on 6/1/10.
//  Copyright 2010 LONG WEEKEND INC.. All rights reserved.
//

#import "PracticeModeCardViewDelegate.h"

#import "CardViewController.h"
#import "ActionBarViewController.h"
#import "StudyViewController.h"

@implementation PracticeModeCardViewDelegate

@synthesize currentPercentageCorrect;

#pragma mark - Init

- (id) init
{
  self = [super init];
  if (self)
  {
    self.currentPercentageCorrect = 100.0f;
  }
  return self;
}

#pragma mark - Card View Controller Delegate

- (void) cardViewDidChangeMode:(CardViewController *)cardViewController
{
  // You can tap the HH in practice mode.
  cardViewController.moodIconBtn.enabled = YES;

  // Show the percent correct when in practice mode
  [cardViewController turnPercentCorrectOn];
}

- (void)cardViewWillSetup:(CardViewController*)cardViewController
{
  // always start with the meaning hidden, reset the reading to whatever state it should be
  [cardViewController setMeaningWebViewHidden:YES];
  [cardViewController resetReadingVisibility];

  NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
  BOOL useMainHeadword = [[settings objectForKey:APP_HEADWORD] isEqualToString:SET_J_TO_E];
  if (useMainHeadword == NO)
  {
    cardViewController.toggleReadingBtn.hidden = YES;
    cardViewController.cardReadingLabelScrollContainer.hidden = YES;
    cardViewController.readingVisible = NO;
  }
  else
  {
    // set the toggleReadingBtn to not hidden for other modes,
    // if this is not here the button can be missing in practice mode
    cardViewController.toggleReadingBtn.hidden = NO;
  }
  
  [cardViewController.moodIcon updateMoodIcon:self.currentPercentageCorrect];
}

- (BOOL)shouldRevealCardView:(CardViewController *)cvc
{
  // We always want to reveal in practice mode
  return YES;
}

- (void)cardViewDidReveal:(CardViewController*)cardViewController
{
  [cardViewController setMeaningWebViewHidden:NO];
  
  // TODO: MMA why are we caching the value of this only to change it on the next line?
  // EDIT: I guess this is because we show the card AFTER reveal, but want it to be hidden again
  // on the next card (in practice mode)
  BOOL userSetReadingVisible = cardViewController.readingVisible;
  [cardViewController turnReadingOn];
  cardViewController.readingVisible = userSetReadingVisible;
}


#pragma mark - StudyViewControllerDelegate Methods

- (void) studyViewWillSetup:(StudyViewController*)svc
{
	// In practice mode, scroll view should always start disabled!
  svc.scrollView.pagingEnabled = NO;
  svc.scrollView.scrollEnabled = NO;
}

- (void) updateStudyViewLabels:(StudyViewController*)svc
{
  NSInteger unseen = [[svc.currentCardSet.cardLevelCounts objectAtIndex:0] intValue];
  NSInteger total = svc.currentCardSet.cardCount;
  svc.remainingCardsLabel.text = [NSString stringWithFormat:@"%d / %d",unseen,total];
  
  // If practice mode, show the quiz stuff.
  svc.tapForAnswerImage.hidden = NO;
  svc.revealCardBtn.hidden = NO;
  
  // Update mood icon percentage (TODO: this is a hack, we have it as a 
  // local property and then update it when cardViewWillSetup: is called)
  // The problem here is that SVC has "knowledge" of right & wrong counts, even
  // though it should be mode agnostic.
  CGFloat tmpRatio = 100;
  if (svc.numViewed > 0)
  {
    tmpRatio = 100*((CGFloat)svc.numRight / (CGFloat)svc.numViewed);
  }
  self.currentPercentageCorrect = tmpRatio;
}

#pragma mark - Action Bar Delegate Methods

- (void)actionBarDidChangeMode:(ActionBarViewController *)avc
{
  // Change action bar view to original XIB
  [[NSBundle mainBundle] loadNibNamed:@"ActionBarViewController" owner:avc options:nil];
}

-(void) actionBarWillSetup:(ActionBarViewController*)avc
{
  avc.rightBtn.hidden = YES;
  avc.wrongBtn.hidden = YES;
  avc.buryCardBtn.hidden = YES;
  avc.addBtn.hidden = YES;
  avc.cardMeaningBtnHint.hidden = NO;
}

-(void) actionBarWillReveal:(ActionBarViewController*)avc
{
  avc.rightBtn.hidden = NO;
  avc.wrongBtn.hidden = NO;
  avc.buryCardBtn.hidden = NO;
  avc.addBtn.hidden = NO;
  avc.cardMeaningBtnHint.hidden = YES;
}

@end