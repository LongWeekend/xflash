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

//! This method will be called when the cardViewController enters browse mode.
- (void) cardViewDidChangeMode:(CardViewController*)cardViewController
{
  // You can't tap the HH in browse mode.
  cardViewController.moodIconBtn.enabled = NO;
  
  // Reading should start as "on" in browse mode no matter what
  [cardViewController turnReadingOn];
  
  // We never want to see "% correct" in browse mode
  [cardViewController turnPercentCorrectOff];
}

//! This method will be called when the cardViewController will set up a new card.
- (void)cardViewWillSetup:(CardViewController*)cardViewController
{
  [cardViewController resetReadingVisibility];
}

#pragma mark StudyViewControllerDelegate Methods

//! This method will be called when StudyViewController will set up a new card.
- (void) studyViewWillSetup:(StudyViewController*)svc
{
  // TODO: Note that our delegate here is making decisions about example sentences
  // even though ex sentences have nothing to do with the card view controller (and only have to
  // do with SVC because of the scrollView & pageControl (MMA - 11.14.2011)
  
	// In browse mode, scroll view should be enabled if the example sentences view is available
  BOOL hasExampleSentences = [svc hasExampleSentences];
  svc.scrollView.pagingEnabled = hasExampleSentences; 
  svc.scrollView.scrollEnabled = hasExampleSentences;
}

//! This method will be called when StudyViewController needs its labels updated
- (void) updateStudyViewLabels:(StudyViewController *)svc
{
  // Set the remainingCardsLabel based on the currentIndex (browse mode)
  NSInteger currIndex = svc.currentCardSet.currentIndex + 1;
  NSInteger total = svc.currentCardSet.cardCount;
  svc.remainingCardsLabel.text = [NSString stringWithFormat:@"%d / %d",currIndex,total];
  
  // These buttons should be hidden at all times in browse mode.
  svc.tapForAnswerImage.hidden = YES;
  svc.revealCardBtn.hidden = YES;
}

#pragma mark - ActionBarViewControllerDelegate Methods

- (void) actionBarDidChangeMode:(ActionBarViewController *)avc
{
  // Change action bar view to browse XIB
  [[NSBundle mainBundle] loadNibNamed:@"ActionBarViewController-Browse" owner:avc options:nil];
}

@end