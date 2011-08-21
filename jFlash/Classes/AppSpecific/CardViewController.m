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

#pragma mark - Flow Methods

- (void) setup
{
  LWE_DELEGATE_CALL(@selector(cardViewWillSetup:), self);
  LWE_DELEGATE_CALL(@selector(cardViewDidSetup:), self);
}

- (void) reveal
{
  if ([self.delegate respondsToSelector:@selector(cardView:shouldReveal:)])
  {
    BOOL shouldReveal = [self.delegate cardView:self shouldReveal:NO];
    if (shouldReveal)
    {
      LWE_DELEGATE_CALL(@selector(cardViewWillReveal:), self);
      LWE_DELEGATE_CALL(@selector(cardViewDidReveal:), self);
    }
  }
}

- (void)dealloc 
{
	if (self.currentCard)
  {
		[currentCard release];
	}
  [super dealloc];
}

@end
