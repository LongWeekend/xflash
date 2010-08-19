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
  if([self wordCardViewController] == nil)
  {
    WordCardViewController *cvc = [[WordCardViewController alloc] init];
    [self setWordCardViewController:cvc];
    [cardViewController setView:[[self wordCardViewController] view]];
		[cvc release];
  }
  
  [[self wordCardViewController] prepareView:[cardViewController currentCard]];
  [[self wordCardViewController] setupReadingVisibility];
}

- (void)actionBarWillSetup:(NSNotification *)aNotification
{
  [[[aNotification object] cardMeaningBtnHint] setHidden:YES];
  [[[aNotification object] prevCardBtn] setHidden:NO];
  [[[aNotification object] nextCardBtn] setHidden:NO];
  
  // tell the practice mode to piss off
  [[[aNotification object] rightBtn] setHidden:YES];
  [[[aNotification object] wrongBtn] setHidden:YES];
  [[[aNotification object] buryCardBtn] setHidden:YES];
  [[[aNotification object] addBtn] setHidden:NO];
  [[[aNotification object] cardMeaningBtnHint] setHidden:YES];
  [[[aNotification object] cardMeaningBtnHintMini] setHidden:YES];
  
  // move the action button to the middle
  CGRect frame = [[[aNotification object] addBtn] frame];
  frame.origin.x = 128;
  [[[aNotification object] addBtn] setFrame:frame];
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