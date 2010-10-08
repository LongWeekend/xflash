//
//  PracticeModeCardViewDelegate.m
//  jFlash
//
//  Created by シャロット ロス on 6/1/10.
//  Copyright 2010 LONG WEEKEND INC.. All rights reserved.
//

#import "PracticeModeCardViewDelegate.h"

@implementation PracticeModeCardViewDelegate
@synthesize wordCardViewController;

//! Delegate messages
- (void)cardViewWillSetup:(NSNotification *)aNotification
{
	CardViewController *cardViewController = (CardViewController *) [aNotification object];
  if([self wordCardViewController] == nil)
  {
    WordCardViewController *cvc = [[WordCardViewController alloc] init];
    [self setWordCardViewController:cvc];
		[cvc release];
		
    [cardViewController setView:[[self wordCardViewController] view]];
  }
  
  [[self wordCardViewController] prepareView:[cardViewController currentCard]];
  // always start with the meaning hidden
  [[self wordCardViewController] setMeaningRevealed: NO];
  [[self wordCardViewController] hideMeaningWebView:YES];
  [[self wordCardViewController] setupReadingVisibility];
  
  NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
  if([[settings objectForKey:APP_HEADWORD] isEqualToString:SET_E_TO_J])
  {
    [[[self wordCardViewController] toggleReadingBtn] setHidden:YES];
    [[[self wordCardViewController] cardReadingLabelScrollContainer] setHidden:YES];
    [[[self wordCardViewController] cardReadingLabel] setHidden:YES];
    [[self wordCardViewController] setReadingVisible: NO];
  }
  else
  {
    // set the toggleReadingBtn to not hidden for other modes, if this is not here the button can be missing in practice mode
    [[[self wordCardViewController] toggleReadingBtn] setHidden:NO];
  }
}

- (BOOL)cardViewShouldReveal:(id)cardView shouldReveal:(BOOL)revealCard
{
  return YES;
}

- (void)cardViewDidReveal:(NSNotification *)aNotification
{
  [[self wordCardViewController] hideMeaningWebView:NO];
  BOOL userSetReadingVisible = [[self wordCardViewController] readingVisible];
  [[self wordCardViewController] setReadingVisible: YES];
  [[self wordCardViewController] setMeaningRevealed: YES];
  [[self wordCardViewController] setupReadingVisibility];
  [[self wordCardViewController] setReadingVisible:userSetReadingVisible];
}

#pragma mark -
#pragma mark Action Bar Delegate Methods

-(void) actionBarWillSetup:(NSNotification *)aNotification
{
  [[[aNotification object] rightBtn] setHidden:YES];
  [[[aNotification object] wrongBtn] setHidden:YES];
  [[[aNotification object] buryCardBtn] setHidden:YES];
  [[[aNotification object] addBtn] setHidden:YES];
  [[[aNotification object] cardMeaningBtnHint] setHidden:NO];
  [[[aNotification object] prevCardBtn] setHidden:YES];
  [[[aNotification object] nextCardBtn] setHidden:YES];
  
  CGRect frame = [[[aNotification object] addBtn] frame];
  frame.origin.x = 9;
  [[[aNotification object] addBtn] setFrame:frame];
}

-(void) actionBarWillReveal:(NSNotification *)aNotification
{
	[[[aNotification object] cardMeaningBtnHint] setHidden:YES];
  
	[[[aNotification object] rightBtn] setHidden:NO];
	[[[aNotification object] wrongBtn] setHidden:NO];
  [[[aNotification object] addBtn] setHidden:NO];
  [[[aNotification object] buryCardBtn] setHidden:NO];
  
  [[[aNotification object] rightBtn] setEnabled: YES];
	[[[aNotification object] wrongBtn] setEnabled: YES];	
  [[[aNotification object] buryCardBtn] setEnabled:YES];
  [[[aNotification object] addBtn] setEnabled:YES];
}

#pragma mark -
#pragma mark Clas Plumbing

- (void)dealloc 
{
	if (wordCardViewController)
	{
		NSArray *views = [wordCardViewController.view subviews];
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
