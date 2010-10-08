//
//  ProgressBarViewController.m
//  jFlash
//
//  Created by シャロット ロス on 5/27/10.
//  Copyright 2010 LONG WEEKEND INC.. All rights reserved.
//

#import "ProgressBarViewController.h"

// The label tags are set in the NIB file!! Be careful!  (That's how we find out what the labels are, not a reference)
#define PROGRESS_BAR_TAG 100
#define PROGRESS_LABEL_TAG 200

@implementation ProgressBarViewController
@synthesize levelDetails;

// draws the progress bar
- (void) drawProgressBar
{
  NSArray *lineColors = [NSArray arrayWithObjects:[UIColor darkGrayColor],[UIColor redColor],[UIColor lightGrayColor],[UIColor cyanColor],[UIColor orangeColor],[UIColor greenColor], nil];
  NSInteger i;
  NSInteger pbOrigin = 7;
  float thisCount;
  
  for (i = 1; i < 6; i++)
  {
    // Get the current progress view for this guy and remove him (we are going to re-add)
    PDColoredProgressView *progressView = (PDColoredProgressView*)[self.view viewWithTag:(i+PROGRESS_BAR_TAG)];
    if (!progressView)
    {
      progressView = [[PDColoredProgressView alloc] initWithProgressViewStyle: UIProgressViewStyleDefault];
      progressView.tag = i+PROGRESS_BAR_TAG;
      [self.view addSubview:progressView];
      // TODO: i dont like the fact that this is manupulated by this method after being released... relying on view to retain.
      [progressView release];
    }

    
    [progressView setTintColor:[lineColors objectAtIndex: i]];
    if(i == 1)
    {
      thisCount = [[levelDetails objectAtIndex: 7] floatValue];
    }
    else
    {
      thisCount -= [[levelDetails objectAtIndex: i-1] floatValue]; 
    }
    float seencount = [[levelDetails objectAtIndex: 7] floatValue];
    float progress;
    if(seencount == 0)
    {
      progress = 0;
    }
    else
    {
      progress = thisCount / seencount;
    }
    progressView.progress = progress;
    // TODO: iPad customization!
    CGRect frame = progressView.frame;
    frame.size.width = 57;
    frame.size.height = 14;
    frame.origin.x = pbOrigin;
    frame.origin.y = 19;
    
    progressView.frame = frame;
    
    //move the origin of the next progress bar over
    pbOrigin += frame.size.width + 5;
    
  }
  
  // Finally bring all the labels to the front
  for (i = 1; i < 6; i++)
  {
    // Update the label
    UILabel *progressLabel = (UILabel*)[self.view viewWithTag:(i+PROGRESS_LABEL_TAG)];
    if (progressLabel && [self levelDetails])
    {
      [progressLabel setText:[NSString stringWithFormat:@"%d",[[levelDetails objectAtIndex:i] integerValue]]];
      [self.view bringSubviewToFront:progressLabel];
    }
  }
        
  [self.view setNeedsLayout];
}

- (void)dealloc 
{
  [levelDetails release];
  [super dealloc];
}


@end
