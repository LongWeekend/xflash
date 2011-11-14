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

#pragma mark - CardViewControllerDelegate Methods

- (void) cardViewDidChangeMode:(CardViewController*)cardViewController
{
  // You can't tap the HH in browse mode.
  cardViewController.moodIconBtn.enabled = NO;
  
  // Reading should start as "on" in browse mode
  [cardViewController turnReadingOn];
}

- (void)cardViewWillSetup:(CardViewController*)cardViewController
{
  [cardViewController turnPercentCorrectOff];
  [cardViewController resetReadingVisibility];
}

#pragma mark StudyViewControllerDelegate Methods

- (void) studyViewWillSetup:(StudyViewController*)svc
{
	// In browse mode, scroll view should be enabled if the example sentences view is available
  BOOL hasExampleSentences = [svc hasExampleSentences];
  svc.scrollView.pagingEnabled = hasExampleSentences; 
  svc.scrollView.scrollEnabled = hasExampleSentences;
}

- (void) updateStudyViewLabels:(StudyViewController *)svc
{
  NSInteger currIndex = svc.currentCardSet.currentIndex + 1;
  NSInteger total = svc.currentCardSet.cardCount;
  svc.remainingCardsLabel.text = [NSString stringWithFormat:@"%d / %d",currIndex,total];
  
  // If practice mode, show the quiz stuff.
  svc.tapForAnswerImage.hidden = YES;
  svc.revealCardBtn.hidden = YES;
}

#pragma mark - ActionBarViewControllerDelegate Methods

- (void) actionBarDidChangeMode:(ActionBarViewController *)avc
{
  // Change action bar view to other XIB
  [[NSBundle mainBundle] loadNibNamed:@"ActionBarViewController-Browse" owner:avc options:nil];
}

@end