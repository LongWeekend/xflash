//
//  CardViewController.m
//  jFlash
//
//  Created by シャロット ロス on 5/25/10.
//  Copyright 2010 LONG WEEKEND INC.. All rights reserved.
//

#import "CardViewController.h"

@implementation CardViewControllerOld
@synthesize delegate;

#pragma mark - Flow Methods

- (void) setupWithCard:(Card*)card
{
  LWE_DELEGATE_CALL(@selector(cardViewWillSetup:),self);
  LWE_DELEGATE_CALL(@selector(cardViewDidSetup:),self);
}

/**
 * Default "reveal" behavior is no
 */
- (void) reveal
{
  if (self.delegate && [self.delegate respondsToSelector:@selector(shouldRevealCardView:)])
  {
    BOOL shouldReveal = [self.delegate shouldRevealCardView:self];
    if (shouldReveal)
    {
      LWE_DELEGATE_CALL(@selector(cardViewWillReveal:),self);
      LWE_DELEGATE_CALL(@selector(cardViewDidReveal:),self);
    }
  }
}

#pragma mark -

// I don't really like "forwarding" the delegate call here, but it's 
// better than putting the original logic/functionality in SVC as it was.
// I think the final solution is to promote the 2 delegates to be CVCs in their
// own right, instead of just the delegate of this otherwise-hollow class.
- (void) refreshSessionDetailsViews:(StudyViewController*)svc
{
  LWE_DELEGATE_CALL(@selector(refreshSessionDetailsViews:), svc);
}

- (void) setupViews:(StudyViewController*)svc
{
  LWE_DELEGATE_CALL(@selector(setupViews:), svc);
}

- (void) studyModeDidChange:(StudyViewController*)svc
{
  LWE_DELEGATE_CALL(@selector(studyModeDidChange:), svc);
}

#pragma mark -

- (void)dealloc 
{
  [super dealloc];
}

@end
