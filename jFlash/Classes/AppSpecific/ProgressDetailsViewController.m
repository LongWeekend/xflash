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
@synthesize bgView;

#pragma mark - UIViewController Methods

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  // Set the background view to be semi-transparent to shadow over the study view 
  self.view.backgroundColor = [UIColor colorWithHue:0.0 saturation:0.0 brightness:0.0 alpha:0.7];

  // Draw the border & the rounded corners on the background view
  self.bgView.layer.cornerRadius = 10.0f;
  self.bgView.layer.borderWidth = 2.0f;
  self.bgView.layer.borderColor = [[UIColor whiteColor] CGColor];

  [self drawProgressBars];
  [self setStreakLabel];
  
  NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
  NSInteger maxStudying = [settings integerForKey:APP_MAX_STUDYING];
  NSInteger totalWords = [[self.levelDetails objectAtIndex:6] intValue];
  if (totalWords > maxStudying)
  {
    self.currentNumberOfWords.text = [NSString stringWithFormat:@"%d*",maxStudying];
    self.totalNumberOfWords.text = [NSString stringWithFormat:@"%d",totalWords];
  }
  else
  {
    self.currentNumberOfWords.text = [NSString stringWithFormat:@"%d",totalWords];
    self.totalNumberOfWords.text = [NSString stringWithFormat:@"%d",totalWords];
  }    

  self.cardsViewedAllTime.text = [NSString stringWithFormat:@"%d",[[self.levelDetails objectAtIndex:7] intValue]];
  self.currentStudySet.text = [[[CurrentState sharedCurrentState] activeTag] tagName];
}


- (void)viewDidUnload
{
	[super viewDidUnload];
  self.bgView = nil;
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

#pragma mark -

- (void)setStreakLabel
{
  NSString *streakText = nil;
  if (self.wrongStreak > 0)
  {
    streakText = [[NSString alloc] initWithFormat:NSLocalizedString(@"%i wrong",@"ProgressDetailsViewController.NumWrongStreak"), self.wrongStreak];
  }
  else
  {
    streakText = [[NSString alloc] initWithFormat:NSLocalizedString(@"%i right",@"ProgressDetailsViewController.NumRightStreak"), self.rightStreak];
  }
  self.streakLabel.text = streakText;
  [streakText release];
}

- (void)drawProgressBars
{  
  NSString *labelText = nil;
  NSArray *labelsArray = [[NSArray alloc] initWithObjects: cardSetProgressLabel0, cardSetProgressLabel1, cardSetProgressLabel2 , cardSetProgressLabel3, cardSetProgressLabel4, cardSetProgressLabel5, nil];
  for (NSInteger i = 0; i < 6; i++)
  {
    labelText = [NSString stringWithFormat:@"%.0f%% ~ %i", 100*[[levelDetails objectAtIndex: i] floatValue] / [[levelDetails objectAtIndex: 6] floatValue], [[levelDetails objectAtIndex:i]intValue]];
    [[labelsArray objectAtIndex:i] setText:labelText];
  }
  [labelsArray release];
  
  NSArray *lineColors = [NSArray arrayWithObjects:[UIColor darkGrayColor],[UIColor redColor],[UIColor lightGrayColor],[UIColor cyanColor],[UIColor orangeColor],[UIColor greenColor], nil];
  NSInteger pbOrigin = 203;
  for (NSInteger i = 0; i < 6; i++)
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

#pragma mark - IBActions

- (IBAction)switchToSettings:(id)sender
{
  // And switch to settings
  NSNumber *index = [NSNumber numberWithInt:SETTINGS_VIEW_CONTROLLER_TAB_INDEX];
  NSDictionary *userInfo = [NSDictionary dictionaryWithObject:index forKey:@"index"];
  [[NSNotificationCenter defaultCenter] postNotificationName:LWEShouldSwitchTab object:self userInfo:userInfo];
  
  // Make sure to call this last
  [self dismiss];
}

- (IBAction) dismiss
{
  [self.view removeFromSuperview];
}

#pragma mark - Class Plumbing

- (void)dealloc
{
  [bgView release];
  [currentStudySet release];
  [closeBtn release];
  [streakLabel release];
  [motivationLabel release];
  [cardsViewedNow release];
  [progressViewTitle release];
  
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
