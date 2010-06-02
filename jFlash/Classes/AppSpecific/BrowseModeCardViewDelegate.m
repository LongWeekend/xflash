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

//! Delegate messages
- (BOOL)meaningWebView:(id)meaningWebView shouldHide:(BOOL)displayMeaning
{
  // always show the meaningWebView in Browse Mode
  return NO;
}

- (void)cardViewWillSetup:(NSNotification *)aNotification
{
  [[aNotification object] setupReadingVisibility];
}

@end
