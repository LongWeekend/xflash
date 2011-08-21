//
//  PracticeModeCardViewDelegate.m
//  jFlash
//
//  Created by シャロット ロス on 6/1/10.
//  Copyright 2010 LONG WEEKEND INC.. All rights reserved.
//

#import "PracticeModeCardViewDelegate.h"

#import "CardViewController.h"
#import "ActionBarViewController.h"

@implementation PracticeModeCardViewDelegate
@synthesize wordCardViewController;

//! Delegate messages
- (void)cardViewWillSetup:(NSNotification *)aNotification
{
	CardViewController *cardViewController = (CardViewController *) [aNotification object];
  if (self.wordCardViewController == nil)
  {
    WordCardViewController *cvc = [[WordCardViewController alloc] init];
    self.wordCardViewController = cvc;
		[cvc release];
    [cardViewController setView:self.wordCardViewController.view];
  }
  
  [self.wordCardViewController prepareView:[cardViewController currentCard]];
  // always start with the meaning hidden
  self.wordCardViewController.meaningRevealed = NO;
  [self.wordCardViewController hideMeaningWebView:YES];
  [self.wordCardViewController setupReadingVisibility];
  
  NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
  if([[settings objectForKey:APP_HEADWORD] isEqualToString:SET_E_TO_J])
  {
    self.wordCardViewController.toggleReadingBtn.hidden = YES;
    self.wordCardViewController.cardReadingLabelScrollContainer.hidden = YES;
    self.wordCardViewController.cardReadingLabel.hidden = YES;
    self.wordCardViewController.readingVisible = NO;
  }
  else
  {
    // set the toggleReadingBtn to not hidden for other modes, if this is not here the button can be missing in practice mode
    self.wordCardViewController.toggleReadingBtn.hidden = NO;
  }
}

- (BOOL)cardViewShouldReveal:(id)cardView shouldReveal:(BOOL)revealCard
{
  return YES;
}

- (void)cardViewDidReveal:(NSNotification *)aNotification
{
  [self.wordCardViewController hideMeaningWebView:NO];
  
  // TODO: MMA why are we caching the value of this only to change it on the next line?
  BOOL userSetReadingVisible = self.wordCardViewController.readingVisible;
  self.wordCardViewController.readingVisible = YES;
  self.wordCardViewController.meaningRevealed = YES;
  [self.wordCardViewController setupReadingVisibility];
  [self.wordCardViewController setReadingVisible:userSetReadingVisible];
}

#pragma mark - Action Bar Delegate Methods

-(void) actionBarWillSetup:(NSNotification *)aNotification
{
  ActionBarViewController *avc = (ActionBarViewController*)[aNotification object];
  avc.rightBtn.hidden = YES;
  avc.wrongBtn.hidden = YES;
  avc.buryCardBtn.hidden = YES;
  avc.addBtn.hidden = YES;
  avc.cardMeaningBtnHint.hidden = NO;
  avc.prevCardBtn.hidden = YES;
  avc.nextCardBtn.hidden = YES;
  
  // Move the add button back to where it belongs - if we were in browse mode, this is changed.
  CGRect rect = avc.addBtn.frame;
  rect.origin.x = 9;
  avc.addBtn.frame = rect;
}

-(void) actionBarWillReveal:(NSNotification *)aNotification
{
  ActionBarViewController *avc = (ActionBarViewController*)[aNotification object];
  avc.rightBtn.hidden = NO;
  avc.wrongBtn.hidden = NO;
  avc.buryCardBtn.hidden = NO;
  avc.addBtn.hidden = NO;
  avc.cardMeaningBtnHint.hidden = YES;
  
  // TODO: MMA is this necessray?  if it is hidden you never have to disable it.
  avc.rightBtn.enabled = YES;
  avc.wrongBtn.enabled = YES;
  avc.buryCardBtn.enabled = YES;
  avc.addBtn.enabled = YES;
}

#pragma mark - Class Plumbing

- (void)dealloc 
{
	if (self.wordCardViewController)
	{
		NSArray *views = [self.wordCardViewController.view subviews];
		LWE_LOG(@"There is %d view(s) in the card view controller's view", [views count]);
		for (UIView *view in views)
		{
			LWE_LOG(@"Removing view %@", view);
			[view removeFromSuperview];
		}
		
		LWE_LOG(@"Retain count of card view controller (being released) : %d", [wordCardViewController retainCount]);
		[wordCardViewController release];
	}

  [super dealloc];
}

@end