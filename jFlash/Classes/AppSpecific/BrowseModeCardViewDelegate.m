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
@synthesize cardViewController;

//! Delegate messages
- (void)cardViewWillSetup:(NSNotification *)aNotification
{
  if([self cardViewController] == nil)
  {
    WordCardViewController *cvc = [[WordCardViewController alloc] init];
    [self setCardViewController:cvc];
    [[aNotification object] setView:[[self cardViewController] view]];
		
		//TODO: Remove this if this is crash. Shouldn't the cvc be released cause the card view controller property is retain?, and it uses the setter method?
		LWE_LOG(@"Rendy just added this, not sure, and please clarify");
		[cvc release];
  }
  
  [[self cardViewController] prepareView:[[aNotification object] currentCard]];
  [[self cardViewController] setupReadingVisibility];
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

@end