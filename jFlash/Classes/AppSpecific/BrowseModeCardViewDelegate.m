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
  cardViewController.view = self.wordCardViewController.view;
  [self.wordCardViewController prepareView:cardViewController.currentCard];
  [self.wordCardViewController resetReadingVisibility];
}

- (void) refreshSessionDetailsViews:(StudyViewController*)svc
{
  NSInteger currIndex = svc.currentCardSet.currentIndex + 1;
  NSInteger total = svc.currentCardSet.cardCount;
  [self.wordCardViewController turnPercentCorrectOff];
  svc.remainingCardsLabel.text = [NSString stringWithFormat:@"%d / %d",currIndex,total];
  
  // If practice mode, show the quiz stuff.
  svc.tapForAnswerImage.hidden = YES;
  svc.revealCardBtn.hidden = YES;
}

- (void) setupViews:(StudyViewController *)svc
{
	// In browse mode, scroll view should be enabled if the example sentences view is available
  BOOL hasExampleSentences = [svc hasExampleSentences];
  svc.scrollView.pagingEnabled = hasExampleSentences; 
  svc.scrollView.scrollEnabled = hasExampleSentences;
}

- (void)studyModeDidChange:(StudyViewController*)svc
{
  // You can't tap the HH in browse mode.
  self.wordCardViewController.moodIconBtn.enabled = NO;
  
  // Reading should start as "on" in browse mode
  [self.wordCardViewController turnReadingOn];
  
  // Change action bar view to other XIB
  [[NSBundle mainBundle] loadNibNamed:@"ActionBarViewController-Browse" owner:svc.actionBarController options:nil];
}

#pragma mark -

- (id) init
{
  self = [super init];
  if (self)
  {
    NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
    NSString *studyDirection = [settings objectForKey:APP_HEADWORD];
    BOOL useMainHeadword = [studyDirection isEqualToString:SET_J_TO_E];
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