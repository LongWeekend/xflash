//
//  BrowseModeCardViewDelegate.m
//  jFlash
//
//  Created by シャロット ロス on 6/1/10.
//  Copyright 2010 LONG WEEKEND INC.. All rights reserved.
//

#import "BrowseModeCardViewDelegate.h"

#import "CardViewController.h"
#import "ActionBarViewController.h"
#import "StudyViewController.h"

@implementation BrowseModeCardViewDelegate
@synthesize wordCardViewController;

#pragma mark - Card View Controller Delegate

- (void)cardViewWillSetup:(CardViewController*)cardViewController
{
  if (self.wordCardViewController == nil)
  {
    NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
    NSString *studyDirection = [settings objectForKey:APP_HEADWORD];
    BOOL useMainHeadword = [studyDirection isEqualToString:SET_J_TO_E];
    self.wordCardViewController = [[[WordCardViewController alloc] initDisplayMainHeadword:useMainHeadword] autorelease];
    cardViewController.view = self.wordCardViewController.view;
  }
  
  [self.wordCardViewController prepareView:cardViewController.currentCard];
  [self.wordCardViewController resetReadingVisibility];
}

- (void) refreshSessionDetailsViews:(StudyViewController*)svc
{
  NSInteger currIndex = svc.currentCardSet.currentIndex + 1;
  NSInteger total = svc.currentCardSet.cardCount;
  [svc turnPercentCorrectOff];
  svc.remainingCardsLabel.text = [NSString stringWithFormat:@"%d / %d",currIndex,total];
  
  // If practice mode, show the quiz stuff.
  svc.tapForAnswerImage.hidden = YES;
  svc.revealCardBtn.hidden = YES;
}

- (void) setupViews:(StudyViewController *)svc
{
  // You can't tap the HH in browse mode.
  svc.moodIconBtn.enabled = NO;

	// In browse mode, scroll view should be enabled if the example sentences view is available
  BOOL hasExampleSentences = [svc hasExampleSentences];
  svc.scrollView.pagingEnabled = hasExampleSentences; 
  svc.scrollView.scrollEnabled = hasExampleSentences;
}

#pragma mark - Action Bar View Controller Delegate

- (void)actionBarWillSetup:(ActionBarViewController*)avc
{
  avc.prevCardBtn.hidden = NO;
  avc.nextCardBtn.hidden = NO;
  avc.addBtn.hidden = NO;
  
  // tell the practice mode to piss off
  avc.cardMeaningBtnHint.hidden = YES;
  avc.cardMeaningBtnHintMini.hidden = YES;
  avc.rightBtn.hidden = YES;
  avc.wrongBtn.hidden = YES;
  avc.buryCardBtn.hidden = YES;

  // move the action button to the middle (it is on the left in practice mode)
  CGRect rect = avc.addBtn.frame;
  rect.origin.x = 128;
  avc.addBtn.frame = rect;
}

#pragma mark -

- (void)dealloc
{
  [wordCardViewController release];
	[super dealloc];
}

@end