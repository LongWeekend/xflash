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

@implementation BrowseModeCardViewDelegate
@synthesize wordCardViewController;

#pragma mark - Card View Controller Delegate

- (void)cardViewWillSetup:(CardViewController*)cardViewController
{
  if (self.wordCardViewController == nil)
  {
    // Note the custom NIB name that has a different positioning for all of the elements
    self.wordCardViewController = [[[WordCardViewController alloc] initWithNibName:@"WordCardViewController-Browse" bundle:nil] autorelease];
    cardViewController.view = self.wordCardViewController.view;
  }
  
  [self.wordCardViewController prepareView:[cardViewController currentCard]];
  [self.wordCardViewController setupReadingVisibility];
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