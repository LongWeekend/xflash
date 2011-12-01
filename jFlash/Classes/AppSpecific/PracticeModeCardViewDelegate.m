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
#import "RootViewController.h"

@interface PracticeModeCardViewDelegate()
@property (nonatomic, assign, getter=hasfinishedSetAlertShowed) BOOL finishedSetAlertShowed;
- (void) _notifyUserStudySetHasBeenLearned;
@end

@implementation PracticeModeCardViewDelegate

@synthesize currentPercentageCorrect;
@synthesize finishedSetAlertShowed = _finishedSetAlertShowed;

#pragma mark - Init

- (id) init
{
  self = [super init];
  if (self)
  {
    self.currentPercentageCorrect = 100.0f;
    self.finishedSetAlertShowed = NO;
  }
  return self;
}

#pragma mark - Card View Controller Delegate

- (void) cardViewDidChangeMode:(CardViewController *)cardViewController
{
  // You can tap the HH in practice mode.
  cardViewController.moodIcon.moodIconBtn.enabled = YES;

  // Show the percent correct when in practice mode
  [cardViewController.moodIcon turnPercentCorrectOn];
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

- (Card*) getFirstCard:(Tag*)cardSet
{
  self.finishedSetAlertShowed = NO; // must be a new set if they want the first card
  NSError* error = nil;
  Card* firstCard = [cardSet getFirstCardWithError:&error];
  if ((firstCard.levelId == 5) && ([error code] == kAllBuriedAndHiddenError))
  {
    [self _notifyUserStudySetHasBeenLearned];
  }
  return firstCard;
}

- (Card*) getNextCard:(Tag*)cardSet afterCard:(Card*)currentCard direction:(NSString*)directionOrNil
{
  NSError* error = nil;
  Card* nextCard = [cardSet getRandomCard:currentCard.cardId error:&error];
  if ((nextCard.levelId == 5) && ([error code] == kAllBuriedAndHiddenError))
  {
    [self _notifyUserStudySetHasBeenLearned];
  }
  else // we are not showing the setHasBeenLearned - so it hasn't been
  {
    self.finishedSetAlertShowed = NO;
  }
  return nextCard;
}

- (UIViewController<StudyViewSubcontrollerDelegate> *)cardViewControllerForStudyView:(StudyViewController *)svc
{
  BOOL useMainHeadword = [[[NSUserDefaults standardUserDefaults] objectForKey:APP_HEADWORD] isEqualToString:SET_J_TO_E];
	CardViewController *tmpCVC = [[CardViewController alloc] initDisplayMainHeadword:useMainHeadword];
  // This class isn't just a delegate for SVC, it's also the card view controller's delegate!
  tmpCVC.delegate = self;
  return [tmpCVC autorelease];
}

- (UIViewController<StudyViewSubcontrollerDelegate> *)actionBarViewControllerForStudyView:(StudyViewController *)svc
{
  ActionBarViewController *tmpABVC = [[ActionBarViewController alloc] initWithNibName:@"ActionBarViewController" bundle:nil];
  tmpABVC.delegate = self;
  return [tmpABVC autorelease];
}

- (void) studyViewWillSetup:(StudyViewController*)svc
{
  // If practice mode, show the quiz stuff.
  svc.tapForAnswerImage.hidden = NO;
  svc.revealCardBtn.hidden = NO;

	// In practice mode, scroll view should always start disabled!
  svc.scrollView.pagingEnabled = NO;
  svc.scrollView.scrollEnabled = NO;
}

- (void) studyViewWillReveal:(StudyViewController *)svc
{
  svc.revealCardBtn.hidden = YES;
  svc.tapForAnswerImage.hidden = YES;
  
  // Now update scrollability (page control doesn't change)
  BOOL hasExampleSentences = [svc hasExampleSentences];
  svc.scrollView.pagingEnabled = hasExampleSentences; 
  svc.scrollView.scrollEnabled = hasExampleSentences;
}

- (void) updateStudyViewLabels:(StudyViewController*)svc
{
  NSInteger unseen = [[svc.currentCardSet.cardLevelCounts objectAtIndex:0] intValue];
  NSInteger total = svc.currentCardSet.cardCount;
  svc.remainingCardsLabel.text = [NSString stringWithFormat:@"%d / %d",unseen,total];
  
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

#pragma mark - Study set has been learnt.

- (void)_notifyUserStudySetHasBeenLearned
{
  if (self.hasfinishedSetAlertShowed == NO)
  {
    UIAlertView *alertView = [[UIAlertView alloc] 
                              initWithTitle:@"Study Set Learned" 
                              message:@"Congratulations! You've already learned this set. We will show cards that would usually be hidden."
                              delegate:self 
                              cancelButtonTitle:@"Change Set"
                              otherButtonTitles:@"OK", nil];
    
    [alertView setTag:STUDY_SET_HAS_FINISHED_ALERT_TAG];
    [alertView show];
    [alertView release];
    self.finishedSetAlertShowed = YES;
  }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
  NSUInteger tag = [alertView tag];
  if (tag == STUDY_SET_HAS_FINISHED_ALERT_TAG)
  {
    switch (buttonIndex)
    {
      case STUDY_SET_SHOW_BURIED_IDX:
        LWE_LOG(@"Study set show burried has been selected after a study set has been master.");
        break;
      case STUDY_SET_CHANGE_SET_IDX:
        LWE_LOG(@"Study set change set has been decided after a study set has been master.");
        [[NSNotificationCenter defaultCenter] postNotificationName:LWEShouldShowStudySetView object:self userInfo:nil];
        break;
    }
  }
}

@end