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
  LWE_DELEGATE_CALL(@selector(cardViewWillSetup:), self);
}

- (void)_cardViewDidSetup
{
  LWE_DELEGATE_CALL(@selector(cardViewDidSetup:), self);
}

- (void)_cardViewWillReveal
{
  LWE_DELEGATE_CALL(@selector(cardViewWillReveal:), self);
}

- (void)_cardViewDidReveal
{
  LWE_DELEGATE_CALL(@selector(cardViewDidReveal:), self);
}

//Give the delegate a chance to not reveal the card
- (BOOL)_cardViewShouldReveal:(BOOL)shouldReveal
{
  if ([self.delegate respondsToSelector:@selector(cardView:shouldReveal:)])
  {
    shouldReveal = [self.delegate cardView:self shouldReveal:shouldReveal];
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
