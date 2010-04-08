//
//  ProgressView.m
//  jFlash
//
//  Created by Ross Sharrott on 11/23/09.
//  Copyright 2009 LONG WEEKEND LLC. All rights reserved.
//

#import "ProgressView.h"

@implementation ProgressView
@synthesize closeBtn, currentStudySet, motivationLabel, levelDetails, streakLabel, rightStreak, wrongStreak;
@synthesize cardSetProgressLabel0, cardSetProgressLabel1, cardSetProgressLabel2, cardSetProgressLabel3, cardSetProgressLabel4, cardSetProgressLabel5;
@synthesize cardsViewedAllTime, cardsViewedNow, cardsRightNow, cardsWrongNow, cardsWrongAllTime, cardsRightAllTime;

- (void)viewDidLoad {
  [super viewDidLoad];
  self.view.backgroundColor = [UIColor colorWithHue:0.0 saturation:0.0 brightness:0.0 alpha:0.7 ];
  [self drawProgressBars];
  [self setStreakLabel];
  [cardsViewedAllTime setText:[NSString stringWithFormat:@"%d",[[levelDetails objectAtIndex:7]intValue]]];
}

- (void)setStreakLabel{
  NSString* streakText;
  if(wrongStreak > 0)
  {
    streakText = [[NSString alloc] initWithFormat:@"%i Wrong", wrongStreak];
  }
  else
  {
    streakText = [[NSString alloc] initWithFormat:@"%i Right", rightStreak];
  }
  streakLabel.text = streakText;
  [streakText release];
}

- (void)drawProgressBars
{  
  NSString* labelText;
  NSArray* labelsArray = [[NSArray alloc] initWithObjects: cardSetProgressLabel0, cardSetProgressLabel1, cardSetProgressLabel2 , cardSetProgressLabel3, cardSetProgressLabel4, cardSetProgressLabel5, nil];
  int i;
  for(i = 0; i < 6; i++)
  {
    labelText = [NSString stringWithFormat:@"%.0f%% ~ %i", 100*[[levelDetails objectAtIndex: i] floatValue] / [[levelDetails objectAtIndex: 6] floatValue], [[levelDetails objectAtIndex:i]intValue]];
    [[labelsArray objectAtIndex:i] setText:labelText];
  }
  [labelsArray release];
  
  NSArray* lineColors = [NSArray arrayWithObjects:[UIColor darkGrayColor],[UIColor redColor],[UIColor lightGrayColor],[UIColor cyanColor],[UIColor orangeColor],[UIColor greenColor], nil];
  int pbOrigin = 203;
  for (i = 0; i < 6; i++) {  
    PDColoredProgressView *progressView = [[PDColoredProgressView alloc] initWithProgressViewStyle: UIProgressViewStyleDefault];
    [progressView setTintColor:[lineColors objectAtIndex: i]];
    progressView.progress = [[levelDetails objectAtIndex: i] floatValue] / [[levelDetails objectAtIndex: 6] floatValue];
    CGRect frame = progressView.frame;
    frame.size.width = 80;
    frame.size.height = 14;
    frame.origin.x = 120;
    frame.origin.y = pbOrigin;
    
    progressView.frame = frame;
    
    [self.view addSubview:progressView];
    
    //move the origin of the next progress bar over
    pbOrigin += frame.size.height + 6;
  }
}


- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}


- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}


- (IBAction) dismiss {
  [self.view removeFromSuperview];
  [self release];
}


- (void)dealloc {
  [levelDetails release];
  [cardSetProgressLabel0 release];
  [cardSetProgressLabel1 release];
  [cardSetProgressLabel2 release];
  [cardSetProgressLabel3 release];
  [cardSetProgressLabel4 release];
  [cardSetProgressLabel5 release];
  [cardsViewedAllTime release];
  [cardsWrongNow release];
  [cardsWrongAllTime release];
  [cardsRightNow release];
  [cardsRightAllTime release];
  [super dealloc];
}


@end
