//
//  CardViewController.m
//  jFlash
//
//  Created by シャロット ロス on 5/25/10.
//  Copyright 2010 LONG WEEKEND INC.. All rights reserved.
//

#import "CardViewController.h"

//! Informal protocol defined messages sent to delegate
@interface NSObject (CardViewDelegateSupport)

// setup card to unrevealed state
- (void)cardViewWillSetup:(NSNotification *)aNotification;
- (void)cardViewDidSetup:(NSNotification *)aNotification;

// reveal card
- (void)cardViewWillReveal:(NSNotification *)aNotification;
- (void)cardViewDidReveal:(NSNotification *)aNotification;
- (BOOL)cardViewShouldReveal:(id)cardView shouldReveal:(BOOL)revealCard;

@end

@implementation CardViewController
@synthesize delegate, currentCard;

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad 
{
  [super viewDidLoad];
}

#pragma mark Delegate Methods

- (void)_cardViewWillSetup
{
  NSNotification *notification = [NSNotification notificationWithName: cardViewWillSetupNotification object:self];
  
  // send the selector to the delegate if it responds
  if([[self delegate] respondsToSelector:@selector(cardViewWillSetup:)])
  {
    [[self delegate] cardViewWillSetup:notification];
  }
  
  //in case something else cares.  Seems to be the pattern from the book but I don't know if we really need this
  [[NSNotificationCenter defaultCenter] postNotification:notification];
}

- (void)_cardViewDidSetup
{
  NSNotification *notification = [NSNotification notificationWithName: cardViewDidSetupNotification object:self];
  
  // send the selector to the delegate if it responds
  if([[self delegate] respondsToSelector:@selector(cardViewDidSetup:)])
  {
    [[self delegate] cardViewDidSetup:notification];
  }
  
  //in case something else cares.  Seems to be the pattern from the book but I don't know if we really need this
  [[NSNotificationCenter defaultCenter] postNotification:notification];
}

- (void)_cardViewWillReveal
{
  NSNotification *notification = [NSNotification notificationWithName: cardViewWillRevealNotification object:self];
  
  // send the selector to the delegate if it responds
  if([[self delegate] respondsToSelector:@selector(cardViewWillReveal:)])
  {
    [[self delegate] cardViewWillReveal:notification];
  }
  
  //in case something else cares.  Seems to be the pattern from the book but I don't know if we really need this
  [[NSNotificationCenter defaultCenter] postNotification:notification];
}

- (void)_cardViewDidReveal
{
  // we created this name previously
  NSNotification *notification = [NSNotification notificationWithName: cardViewDidRevealNotification object:self];
  
  // send the selector to the delegate if it responds
  if([[self delegate] respondsToSelector:@selector(cardViewDidReveal:)])
  {
    [[self delegate] cardViewDidReveal:notification];
  }
  
  //in case something else cares.  Seems to be the pattern from the book but I don't know if we really need this
  [[NSNotificationCenter defaultCenter] postNotification:notification];
}

//Give the delegate a chance to not reveal the card
- (BOOL)_cardViewShouldReveal:(BOOL)shouldReveal
{
  if([[self delegate] respondsToSelector:@selector(cardViewShouldReveal:shouldReveal:)])
  {
    shouldReveal = [[self delegate] cardViewShouldReveal:self shouldReveal:shouldReveal];
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
  if([self _cardViewShouldReveal:NO])
  {
    [self _cardViewWillReveal];
    [self _cardViewDidReveal];
  }
}

- (void)dealloc 
{
	if (currentCard)
		[currentCard release];
	
  [super dealloc];
}

@end

//! Notification names
NSString  *cardViewWillSetupNotification = @"cardViewWillSetupNotification";
NSString  *cardViewDidSetupNotification = @"cardViewDidSetupNotification";
NSString  *cardViewWillRevealNotification = @"cardViewWillRevealNotification";
NSString  *cardViewDidRevealNotification = @"cardViewDidRevealNotification";