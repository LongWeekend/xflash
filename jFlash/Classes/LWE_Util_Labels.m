//
//  LWE_Util_Labels.m
//  jFlash
//
//  Created by シャロット ロス on 2/13/10.
//  Copyright 2010 LONG WEEKEND INC.. All rights reserved.
//

#import "LWE_Util_Labels.h"


@implementation LWE_Util_Labels

// Shorter Convenience Method: Resize without parentViewSize option
+ (void) resizeLabelWithConstraints: (UILabel *)theLabel minFontSize:(NSInteger)minFontSize maxFontSize:(NSInteger)maxFontSize  {
  [LWE_Util_Labels resizeLabelWithConstraints:theLabel minFontSize:minFontSize maxFontSize:maxFontSize forParentViewSize:CGSizeMake(0, 0)];
}

// Resize UIScrollView.contentSize based on expected label size and reset scroll pos!
+ (void) autosizeLabelText: (UILabel *)theLabel forScrollView:(UIScrollView *)scrollViewContainer withText:(NSString *)theText minFontSize:(NSInteger)minFontSize maxFontSize:(NSInteger)maxFontSize {
  
  // Scroll to 0,0
  [scrollViewContainer setContentOffset:CGPointMake(0, 0) animated: YES];
  
  // Use our snazzy font resizer (works with multiple lines!)
  [LWE_Util_Labels resizeLabelWithConstraints:theLabel minFontSize:minFontSize maxFontSize:maxFontSize forParentViewSize:scrollViewContainer.frame.size];
  CGSize expectedLabelSize = theLabel.frame.size;
  
  // Resize label according to expected label text size
  CGRect newLabelFrame = theLabel.frame;
  newLabelFrame.size.height = expectedLabelSize.height;
  theLabel.frame = newLabelFrame;
  
  // Update the contentSize attrib
  scrollViewContainer.contentSize = CGSizeMake(theLabel.frame.size.width, theLabel.frame.size.height);
  
  // Vertically align the reading label
  CGSize labelSize = theLabel.frame.size;
  if(labelSize.height < scrollViewContainer.frame.size.height)
  {
    CGRect labelFrame = theLabel.frame;
    int yOffset = (int) ((scrollViewContainer.frame.size.height - labelSize.height)/2);
    labelFrame.origin.y = yOffset;
    theLabel.frame = labelFrame;
  }
  
}

// Shorter Convenience Method: AutoSize without specifying font sizes!
+ (void) autosizeLabelText: (UILabel *)theLabel forScrollView:(UIScrollView *)scrollViewContainer withText:(NSString *)theText  {
  [LWE_Util_Labels autosizeLabelText:theLabel forScrollView:scrollViewContainer withText:theText minFontSize:READING_MIN_FONTSIZE maxFontSize:READING_MAX_FONTSIZE];
}

// Resize font within constraints, works with multi-line labels.
+ (void) resizeLabelWithConstraints: (UILabel *)theLabel minFontSize:(NSInteger)minFontSize maxFontSize:(NSInteger)maxFontSize forParentViewSize:(CGSize)parentViewSize {
  UIFont *newFont = theLabel.font;
  CGRect newFrame = theLabel.frame;
  CGSize expectedLabelSize;
  
  // Loop from Max Font to Min Font Size until one fits, or scrolling is inevitable
  for(int i = (int)maxFontSize; i > (int)minFontSize; i=i-2){
    
    // Set next font size.
    newFont = [newFont fontWithSize:i];
    CGSize constraintSize = theLabel.frame.size;
    constraintSize.width = constraintSize.width-5;
    constraintSize.height = 6000.0f;
    
    // WARNING: this uses "word wrap" (not good for very long JPN strings!)
    expectedLabelSize = [theLabel.text sizeWithFont:newFont constrainedToSize:constraintSize lineBreakMode:theLabel.lineBreakMode];
    
    // Break if this fontsize fits within the available scrollable height?
    if(parentViewSize.height != 0 && expectedLabelSize.height < parentViewSize.height)
      break;
  }
  newFrame.size.height = expectedLabelSize.height;
  theLabel.frame = newFrame;
  theLabel.font = newFont;
}


@end
