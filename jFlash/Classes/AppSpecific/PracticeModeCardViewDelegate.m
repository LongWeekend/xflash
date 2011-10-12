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

#pragma mark - Card View Controller Delegate

- (void)cardViewWillSetup:(CardViewController*)cardViewController
{
  NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
  NSString *studyDirection = [settings objectForKey:APP_HEADWORD];
  BOOL useMainHeadword = [studyDirection isEqualToString:SET_J_TO_E];
  if (self.wordCardViewController == nil)
  {
    self.wordCardViewController = [[[WordCardViewController alloc] initDisplayMainHeadword:useMainHeadword] autorelease];
    cardViewController.view = self.wordCardViewController.view;
  }
  
  [self.wordCardViewController prepareView:cardViewController.currentCard];

  // always start with the meaning hidden
  [self.wordCardViewController hideMeaningWebView:YES];
  [self.wordCardViewController resetReadingVisibility];
  
  if (useMainHeadword == NO)
  {
    self.wordCardViewController.toggleReadingBtn.hidden = YES;
    self.wordCardViewController.cardReadingLabelScrollContainer.hidden = YES;
    self.wordCardViewController.readingVisible = NO;
  }
  else
  {
    // set the toggleReadingBtn to not hidden for other modes,
    // if this is not here the button can be missing in practice mode
    self.wordCardViewController.toggleReadingBtn.hidden = NO;
  }
}

- (BOOL)cardView:(CardViewController*)cvc shouldReveal:(BOOL)shouldReveal;
{
  return YES;
}

- (void)cardViewDidReveal:(CardViewController*)cardViewController
{
  [self.wordCardViewController hideMeaningWebView:NO];
  
  // TODO: MMA why are we caching the value of this only to change it on the next line?
  // EDIT: I guess this is because we show the card AFTER reveal, but want it to be hidden again
  // on the next card (in practice mode)
  BOOL userSetReadingVisible = self.wordCardViewController.readingVisible;
  [self.wordCardViewController turnReadingOn];
  self.wordCardViewController.readingVisible = userSetReadingVisible;
}

#pragma mark - Action Bar Delegate Methods

-(void) actionBarWillSetup:(ActionBarViewController*)avc
{
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

-(void) actionBarWillReveal:(ActionBarViewController*)avc
{
  avc.rightBtn.hidden = NO;
  avc.wrongBtn.hidden = NO;
  avc.buryCardBtn.hidden = NO;
  avc.addBtn.hidden = NO;
  avc.cardMeaningBtnHint.hidden = YES;
}

#pragma mark - Class Plumbing

- (void)dealloc 
{
  [wordCardViewController release];
  [super dealloc];
}

@end