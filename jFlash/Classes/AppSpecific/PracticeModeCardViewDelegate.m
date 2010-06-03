//
//  PracticeModeCardViewDelegate.m
//  jFlash
//
//  Created by シャロット ロス on 6/1/10.
//  Copyright 2010 LONG WEEKEND INC.. All rights reserved.
//

#import "PracticeModeCardViewDelegate.h"


@implementation PracticeModeCardViewDelegate
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
  
  // always start with the meaning hidden
  [[self cardViewController] setMeaningRevealed: NO];
  [[self cardViewController] hideMeaningWebView:YES];
  [[self cardViewController] setupReadingVisibility];
  
  NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
  if([[settings objectForKey:APP_HEADWORD] isEqualToString:SET_E_TO_J])
  {
    [[[self cardViewController] toggleReadingBtn] setHidden:YES];
    [[[self cardViewController] cardReadingLabelScrollContainer] setHidden:YES];
    [[[self cardViewController] cardReadingLabel] setHidden:YES];
    [[self cardViewController] setReadingVisible: NO];
  }
  else
  {
    // set the toggleReadingBtn to not hidden for other modes, if this is not here the button can be missing in practice mode
    [[[self cardViewController] toggleReadingBtn] setHidden:NO];
  }
}

- (BOOL)cardViewShouldReveal:(id)cardView shouldReveal:(BOOL)revealCard
{
  return YES;
}

- (void)cardViewDidReveal:(NSNotification *)aNotification
{
  [[self cardViewController] hideMeaningWebView:NO];
  BOOL userSetReadingVisible = [[self cardViewController] readingVisible];
  [[self cardViewController] setReadingVisible: YES];
  [[self cardViewController] setMeaningRevealed: YES];
  [[self cardViewController] setupReadingVisibility];
  [[self cardViewController] setReadingVisible:userSetReadingVisible];
}

- (void)dealloc 
{
  [cardViewController release];  
  [super dealloc];
}

@end
