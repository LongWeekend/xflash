//
//  ProgressDetailsViewController.m
//  jFlash
//
//  Created by Ross Sharrott on 11/23/09.
//  Copyright 2009 LONG WEEKEND LLC. All rights reserved.
//

#import "ProgressDetailsViewController.h"
#import "UserPeer.h"

@implementation ProgressDetailsViewController
@synthesize closeBtn, currentStudySet, motivationLabel, levelDetails, streakLabel, rightStreak, wrongStreak;
@synthesize cardSetProgressLabel0, cardSetProgressLabel1, cardSetProgressLabel2, cardSetProgressLabel3, cardSetProgressLabel4, cardSetProgressLabel5;
@synthesize cardsViewedAllTime, cardsViewedNow, cardsRightNow, cardsWrongNow, progressViewTitle;
@synthesize currentNumberOfWords, totalNumberOfWords;

- (void)viewDidLoad
{
  [super viewDidLoad];
  self.view.backgroundColor = [UIColor colorWithHue:0.0 saturation:0.0 brightness:0.0 alpha:0.7 ];
  [self drawProgressBars];
  [self setStreakLabel];
  [cardsViewedAllTime setText:[NSString stringWithFormat:@"%d",[[levelDetails objectAtIndex:7]intValue]]];
  
  NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
  
  NSInteger maxStudying = [settings integerForKey:APP_MAX_STUDYING];
  NSInteger totalWords = [[levelDetails objectAtIndex:6] intValue];
  if (totalWords > maxStudying)
  {
    [self.currentNumberOfWords setText:[NSString stringWithFormat:@"%d*",maxStudying]];
    [self.totalNumberOfWords setText:[NSString stringWithFormat:@"%d",totalWords]];
  }
  else
  {
    [self.currentNumberOfWords setText:[NSString stringWithFormat:@"%d",totalWords]];
    [self.totalNumberOfWords setText:[NSString stringWithFormat:@"%d",totalWords]];
  }    
}

- (void)setStreakLabel
{
  NSString* streakText;
  if(wrongStreak > 0)
  {
    streakText = [[NSString alloc] initWithFormat:NSLocalizedString(@"%i wrong",@"ProgressDetailsViewController.NumWrongStreak"), wrongStreak];
  }
  else
  {
    streakText = [[NSString alloc] initWithFormat:NSLocalizedString(@"%i right",@"ProgressDetailsViewController.NumRightStreak"), rightStreak];
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
  for (i = 0; i < 6; i++)
  {  
    PDColoredProgressView *progressView = [[PDColoredProgressView alloc] initWithProgressViewStyle: UIProgressViewStyleDefault];
    [progressView setTintColor:[lineColors objectAtIndex: i]];
    progressView.progress = [[levelDetails objectAtIndex: i] floatValue] / [[levelDetails objectAtIndex: 6] floatValue];
    // TODO: iPad customization!
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



- (IBAction) dismiss
{
  // TODO: MMA 8/9/2010 - this is weird that we are releasing ourself
  [self.view removeFromSuperview];
  [self release];
}

//This was added for safety reason? - Rendy 13/08/10
- (void)viewDidUnload
{
	[super viewDidUnload];
	
	self.currentNumberOfWords = nil;
	self.totalNumberOfWords = nil;
	self.closeBtn = nil;
	self.currentStudySet = nil;
	self.motivationLabel = nil;
	self.streakLabel = nil;
	self.cardsViewedNow = nil;
	self.cardsViewedAllTime = nil;
	self.cardsRightNow = nil;
	self.cardsWrongNow = nil;
	self.cardSetProgressLabel0 = nil;
	self.cardSetProgressLabel1 = nil;
	self.cardSetProgressLabel2 = nil;
	self.cardSetProgressLabel3 = nil;
	self.cardSetProgressLabel4 = nil;
	self.cardSetProgressLabel5 = nil;
	self.progressViewTitle = nil;
}


- (void)dealloc
{
  [levelDetails release];
  [currentNumberOfWords release];
  [totalNumberOfWords release];
  [cardSetProgressLabel0 release];
  [cardSetProgressLabel1 release];
  [cardSetProgressLabel2 release];
  [cardSetProgressLabel3 release];
  [cardSetProgressLabel4 release];
  [cardSetProgressLabel5 release];
  [cardsViewedAllTime release];
  [cardsWrongNow release];
  [cardsRightNow release];
  [super dealloc];
}


@end
