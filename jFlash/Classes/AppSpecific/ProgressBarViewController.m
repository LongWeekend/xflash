//
//  ProgressBarViewController.m
//  jFlash
//
//  Created by シャロット ロス on 5/27/10.
//  Copyright 2010 LONG WEEKEND INC.. All rights reserved.
//

#import "ProgressBarViewController.h"


@implementation ProgressBarViewController
@synthesize cardSetProgressLabel1, cardSetProgressLabel2, cardSetProgressLabel3, cardSetProgressLabel4, cardSetProgressLabel5;
@synthesize levelDetails;


// draws the progress bar
- (void) drawProgressBar
{
  if ([self levelDetails])
  {
    [cardSetProgressLabel1 setText:[NSString stringWithFormat:@"%d",[[levelDetails objectAtIndex:1]intValue]]];  
    [cardSetProgressLabel2 setText:[NSString stringWithFormat:@"%d",[[levelDetails objectAtIndex:2]intValue]]];  
    [cardSetProgressLabel3 setText:[NSString stringWithFormat:@"%d",[[levelDetails objectAtIndex:3]intValue]]];  
    [cardSetProgressLabel4 setText:[NSString stringWithFormat:@"%d",[[levelDetails objectAtIndex:4]intValue]]];  
    [cardSetProgressLabel5 setText:[NSString stringWithFormat:@"%d",[[levelDetails objectAtIndex:5]intValue]]];
  }
  
  NSArray* lineColors = [NSArray arrayWithObjects:[UIColor darkGrayColor],[UIColor redColor],[UIColor lightGrayColor],[UIColor cyanColor],[UIColor orangeColor],[UIColor greenColor], nil];
  int i;
  int pbOrigin = 7;
  float thisCount;
  
  for (i = 1; i < 6; i++)
  {
    // Get the current progress view for this guy and remove him (we are going to re-add)
    UIView *aView = [self.view viewWithTag:i];
    if (aView)
    {
      [aView removeFromSuperview];
    }
    
    PDColoredProgressView *progressView = [[PDColoredProgressView alloc] initWithProgressViewStyle: UIProgressViewStyleDefault];
    progressView.tag = i;
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
    [self.view addSubview:progressView];
    [progressView release];
    
    //move the origin of the next progress bar over
    pbOrigin += frame.size.width + 5;
  }
  
  //TODO - There should be a way not to need this.
  [self.view bringSubviewToFront:cardSetProgressLabel1];
  [self.view bringSubviewToFront:cardSetProgressLabel2];
  [self.view bringSubviewToFront:cardSetProgressLabel3];
  [self.view bringSubviewToFront:cardSetProgressLabel4];
  [self.view bringSubviewToFront:cardSetProgressLabel5];
  
  [self.view setNeedsLayout];
}

- (void)dealloc 
{
  [cardSetProgressLabel1 release];
  [cardSetProgressLabel2 release];
  [cardSetProgressLabel3 release];
  [cardSetProgressLabel4 release];
  [cardSetProgressLabel5 release];
  [levelDetails release];
  [super dealloc];
}


@end
