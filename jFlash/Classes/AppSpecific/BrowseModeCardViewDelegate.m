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
  [[[aNotification object] addBtn] setHidden:YES];
  [[[aNotification object] cardMeaningBtnHint] setHidden:YES];
  [[[aNotification object] cardMeaningBtnHintMini] setHidden:YES];

  // kana....?
  // TODO: this needs to be called on studyviewcontroller
  //[[[aNotification object] superview] doTogglePercentCorrectBtn];
}

@end