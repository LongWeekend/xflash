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

//! Delegate messages
- (void)cardViewWillSetup:(NSNotification *)aNotification
{
	CardViewController *cardViewController = [aNotification object];
  if(self.wordCardViewController == nil)
  {
    WordCardViewController *cvc = [[WordCardViewController alloc] init];
    [self setWordCardViewController:cvc];
    [cardViewController setView:[self.wordCardViewController view]];
		[cvc release];
  }
  
  [self.wordCardViewController prepareView:[cardViewController currentCard]];
  [self.wordCardViewController setupReadingVisibility];
}

- (void)actionBarWillSetup:(NSNotification *)aNotification
{
  ActionBarViewController *avc = (ActionBarViewController*)[aNotification object];
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
  avc.addBtn.frame.origin.x = 128;
}

- (void)dealloc
{
	if (wordCardViewController)
	{
		NSArray *views = [wordCardViewController.view subviews];
		LWE_LOG(@"There is %d view(s) in the card view controller's view", [views count]);
		for (UIView *view in views)
		{
			LWE_LOG(@"Removing view %@", view);
			[view removeFromSuperview];
		}
		
		[wordCardViewController release];
	}
	
	[super dealloc];
}

@end