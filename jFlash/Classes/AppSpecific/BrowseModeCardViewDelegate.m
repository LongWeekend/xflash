//
//  BrowseModeCardViewDelegate.m
//  jFlash
//
//  Created by シャロット ロス on 6/1/10.
//  Copyright 2010 LONG WEEKEND INC.. All rights reserved.
//

#import "BrowseModeCardViewDelegate.h"
#import "CardViewController.h"

@implementation BrowseModeCardViewDelegate
@synthesize cardViewController;

//! Delegate messages
- (void)cardViewWillSetup:(NSNotification *)aNotification
{
  if([self cardViewController] == nil)
  {
    WordCardViewController *cvc = [[WordCardViewController alloc] init];
    [self setCardViewController:cvc];
    NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
    [[self cardViewController] layoutCardContentForStudyDirection:[settings objectForKey:APP_HEADWORD]];
    [[aNotification object] setView:[[self cardViewController] view]];
  }
  
  [[self cardViewController] prepareView:[[aNotification object] currentCard]];
  [[self cardViewController] setupReadingVisibility];
}

@end
