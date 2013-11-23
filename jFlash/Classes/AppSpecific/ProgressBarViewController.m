//
//  ProgressBarViewController.m
//  jFlash
//
//  Created by シャロット ロス on 5/27/10.
//  Copyright 2010 LONG WEEKEND INC.. All rights reserved.
//

#import "ProgressBarViewController.h"
#import "PDColoredProgressView.h"

// The label tags are set in the NIB file!! Be careful!  (That's how we find out what the labels are, not a reference)
#define PROGRESS_BAR_TAG 100
#define PROGRESS_LABEL_TAG 200

@interface ProgressBarViewController ()
- (PDColoredProgressView *)_progressBarForLevel:(NSInteger)i;
@end

@implementation ProgressBarViewController
@synthesize tag;

- (UIProgressView *)_progressBarForLevel:(NSInteger)i
{
    // Get the current progress view for this guy and remove him (we are going to re-add)
    UIProgressView *progressView = (UIProgressView *)[self.view viewWithTag:(i+PROGRESS_BAR_TAG)];
    if (progressView == nil)
    {
        NSArray *lineColors = [NSArray arrayWithObjects:[UIColor darkGrayColor],[UIColor redColor],[UIColor darkGrayColor],[UIColor cyanColor],[UIColor orangeColor],[UIColor greenColor], nil];
        progressView = [[[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault] autorelease];
        progressView.tag = i+PROGRESS_BAR_TAG;
        [progressView setProgressTintColor:[lineColors objectAtIndex:i]];
        [progressView setTrackTintColor:[UIColor whiteColor]];
        [self.view addSubview:progressView];
    }
    return progressView;
}

// draws the progress bar
- (void) drawProgressBar
{
  // TODO: iPad customization
  NSInteger pbOrigin = 7;
  NSInteger thisLevelCount = self.tag.seenCardCount;
  
  // For levels 1-5
  for (NSInteger i = 1; i < 6; i++)
  {
    // This call handles the creation and/or getting of the progress bar
    UIProgressView *progressView = [self _progressBarForLevel:i];

    if (i > 1)
    {
      thisLevelCount -= [[self.tag.cardLevelCounts objectAtIndex:i-1] intValue];
    }
    CGFloat progress = 0.0f;
    if (self.tag.seenCardCount > 0)
    {
      progress = ((CGFloat)thisLevelCount / (CGFloat)tag.seenCardCount);
    }
    progressView.progress = progress;
    
    // TODO: iPad customization!
    //move the origin of the next progress bar over
    progressView.frame = CGRectMake(pbOrigin, 19, 57, 14);
    pbOrigin += progressView.frame.size.width + 5;
  }
  
  // Finally bring all the labels to the front
  for (NSInteger i = 1; i < 6; i++)
  {
    // Update the label
    UILabel *progressLabel = (UILabel*)[self.view viewWithTag:(i+PROGRESS_LABEL_TAG)];
    if (progressLabel)
    {
      progressLabel.text = [NSString stringWithFormat:@"%d",[[self.tag.cardLevelCounts objectAtIndex:i] integerValue]];
      [self.view bringSubviewToFront:progressLabel];
    }
  }
        
  [self.view setNeedsLayout];
}

- (void)dealloc 
{
  [tag release];
  [super dealloc];
}


@end
