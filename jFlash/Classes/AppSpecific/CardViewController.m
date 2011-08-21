//
//  CardViewController.m
//  jFlash
//
//  Created by シャロット ロス on 5/25/10.
//  Copyright 2010 LONG WEEKEND INC.. All rights reserved.
//

#import "CardViewController.h"

@implementation CardViewController
@synthesize delegate, currentCard;

#pragma mark Delegate Methods

- (void)_cardViewWillSetup
{
  NSNotification *notification = [NSNotification notificationWithName: cardViewWillSetupNotification object:self];
  LWE_DELEGATE_CALL(@selector(cardViewWillSetup:), notification);
}

- (void)_cardViewDidSetup
{
  NSNotification *notification = [NSNotification notificationWithName: cardViewDidSetupNotification object:self];
  LWE_DELEGATE_CALL(@selector(cardViewDidSetup:), notification);
}

- (void)_cardViewWillReveal
{
  NSNotification *notification = [NSNotification notificationWithName: cardViewWillRevealNotification object:self];
  LWE_DELEGATE_CALL(@selector(cardViewWillReveal:), notification);
}

- (void)_cardViewDidReveal
{
  NSNotification *notification = [NSNotification notificationWithName: cardViewDidRevealNotification object:self];
  LWE_DELEGATE_CALL(@selector(cardViewDidReveal:), notification);
}

//Give the delegate a chance to not reveal the card
- (BOOL)_cardViewShouldReveal:(BOOL)shouldReveal
{
  if ([self.delegate respondsToSelector:@selector(cardViewShouldReveal:shouldReveal:)])
  {
    shouldReveal = [self.delegate cardViewShouldReveal:self shouldReveal:shouldReveal];
  }
  return shouldReveal;
}

#pragma mark Flow Methods

- (void) setup
{
  [self _cardViewWillSetup];
  [self _cardViewDidSetup];
}

- (void) reveal
{
  if ([self _cardViewShouldReveal:NO])
  {
    [self _cardViewWillReveal];
    [self _cardViewDidReveal];
  }
}

- (void)dealloc 
{
	if (currentCard)
  {
		[currentCard release];
	}
  [super dealloc];
}

@end

//! Notification names
NSString  *cardViewWillSetupNotification = @"cardViewWillSetupNotification";
NSString  *cardViewDidSetupNotification = @"cardViewDidSetupNotification";
NSString  *cardViewWillRevealNotification = @"cardViewWillRevealNotification";
NSString  *cardViewDidRevealNotification = @"cardViewDidRevealNotification";