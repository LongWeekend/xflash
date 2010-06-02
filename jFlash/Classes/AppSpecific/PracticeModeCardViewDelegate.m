//
//  PracticeModeCardViewDelegate.m
//  jFlash
//
//  Created by シャロット ロス on 6/1/10.
//  Copyright 2010 LONG WEEKEND INC.. All rights reserved.
//

#import "PracticeModeCardViewDelegate.h"


@implementation PracticeModeCardViewDelegate
@synthesize meaningRevealed;

//! Delegate messages
- (BOOL)meaningWebView:(id)meaningWebView shouldHide:(BOOL)displayMeaning
{
  if(meaningRevealed)
  {
    return NO;
  }
  else
  {
    return YES;
  }
}

- (void)meaningWebViewDidDisplay:(NSNotification *)aNotification
{
  if(meaningRevealed)
  {
    // Always show reading on reveal
    [[aNotification object] hideShowReadingBtn];
    [[[aNotification object] cardReadingLabelScrollContainer] setHidden:NO];
    [[[aNotification object] cardReadingLabel] setHidden:NO];
  }
  else
  {
    [[aNotification object] setupReadingVisibility];
  }
}

- (void)cardViewWillSetup:(NSNotification *)aNotification
{
  // always start with the meaning hidden
  [self setMeaningRevealed: NO];
  
  NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
  if([[settings objectForKey:APP_HEADWORD] isEqualToString:SET_E_TO_J])
  {
    [[[aNotification object] toggleReadingBtn] setHidden:YES];
    [[[aNotification object] cardReadingLabelScrollContainer] setHidden:YES];
    [[[aNotification object] cardReadingLabel] setHidden:YES];
    [[aNotification object] setReadingVisible: NO];
  }
  else
  {
    // set the toggleReadingBtn to not hidden for other modes, if this is not here the button can be missing in practice mode
    [[[aNotification object] toggleReadingBtn] setHidden:NO];
  }
}

@end
