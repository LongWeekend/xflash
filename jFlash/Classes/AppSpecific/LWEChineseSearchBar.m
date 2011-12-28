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
  // Get the pasteboard
  UIPasteboard *generalPasteboard = [UIPasteboard generalPasteboard];
  NSArray *pasteboardItems = [generalPasteboard.items copy];
  
  // Get the tone from the button's tag!
  NSInteger whichTone = [(UIView*)sender tag];
  if (whichTone != 5)
  {
    generalPasteboard.string = [NSString stringWithFormat:@"%d ",whichTone];
  }
  else
  {
    generalPasteboard.string = @"? ";
  }
  
  // This is ghetto, but UISearchBar doesn't expose its text field directly, so you have to
  // find the subview with it.
  BOOL found = NO;
  for (UIView *subview in self.subviews)
  {
    if ([subview isKindOfClass:[UITextField class]])
    {
      found = YES;
      [subview paste:subview];
    }
  }
  
  if (found == NO)
  {
    // Do it the old way, something CRAZY happened
    self.text = [self.text stringByAppendingString:generalPasteboard.string];
  }
  
  // Put everything back
  generalPasteboard.items = pasteboardItems;
  [pasteboardItems release];
}

@end