//
//  LWEChineseSearchBar.m
//  jFlash
//
//  Created by Mark Makdad on 10/18/11.
//  Copyright 2011 Long Weekend LLC. All rights reserved.
//

#import "LWEChineseSearchBar.h"

@implementation LWEChineseSearchBar

@synthesize inputAccessoryView, accessoryKeysBackgroundView;

#pragma mark - Class Setup & Teardown

- (id)initWithFrame:(CGRect)rect
{
  self = [super initWithFrame:rect];
  if (self)
  {
    // Load the input accessory view from a custom XIB file
    [[NSBundle mainBundle] loadNibNamed:@"LWEChineseSearchBarInput" owner:self options:NULL];
  }
  return self;
}

- (void) dealloc
{
  [accessoryKeysBackgroundView release];
  [inputAccessoryView release];
  [super dealloc];
}

#pragma mark - IBAction Methods

- (IBAction) toneButtonPressed:(id)sender
{
  // Get the tone from the button's tag!
  NSInteger whichTone = [(UIView*)sender tag];
  if (whichTone != 5)
  {
    self.text = [self.text stringByAppendingFormat:@"%d ",whichTone];
  }
  else
  {
    self.text = [self.text stringByAppendingString:@"? "];
  }
}

@end