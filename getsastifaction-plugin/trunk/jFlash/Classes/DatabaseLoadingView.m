//
//  DatabaseLoadingView.m
//  jFlash
//
//  Created by Mark Makdad on 2/20/10.
//  Copyright 2010 LONG WEEKEND INC.. All rights reserved.
//

#import "DatabaseLoadingView.h"

@implementation DatabaseLoadingView

@synthesize delegate;
@synthesize loadingView;
@synthesize i;

- (id)init
{
  if (self = [super initWithFrame:[[UIScreen mainScreen] applicationFrame]])
  {
    NSString* tmpStr = [[NSString alloc] initWithFormat:@"/%@theme-cookie-cutters/Default.png",[ApplicationSettings getThemeName]];
    self.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:tmpStr]];
    [tmpStr release];
    i = 0;
  }
  
  // Get the notification for dismissing this view
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dismissView) name:@"databaseOpened" object:nil];
    
	return self;
}

- (void)startView
{
  // Set up the window
	[[[[UIApplication sharedApplication] windows] objectAtIndex:0] addSubview:self];

  loadingView = [[PDColoredProgressView alloc] initWithProgressViewStyle: UIProgressViewStyleDefault];
  [loadingView setTintColor:[UIColor yellowColor]]; //or any other color you like

  CGRect viewFrame = loadingView.frame;
  viewFrame.origin.x = 81;
  viewFrame.origin.y = 412;
  loadingView.frame = viewFrame;
	[self addSubview:loadingView];
  
  // Copy the database
  ApplicationSettings *appSettings = [ApplicationSettings sharedApplicationSettings];
  [appSettings performSelectorInBackground:@selector(openedDatabase) withObject:nil];
//  [appSettings openedDatabase];
  [self checkIfDoneYet];
  
}

- (void) checkIfDoneYet
{
  if (i < 15)
  {
    float k = ((float)i/15.0f);
    LWE_LOG(@"float val : %f %d",k,i);
    [[self loadingView] setProgress:k];
    i++;
    [self performSelector:@selector(checkIfDoneYet) withObject:nil afterDelay:0.25];
  }
  else
  {
    [self dismissView];
  }
}

- (void)dismissView
{
	if (loadingView) {
		[loadingView removeFromSuperview];
		[self removeFromSuperview];
		[loadingView release];
	}		
	if (self.delegate != NULL && [self.delegate respondsToSelector:@selector(dbIsReady)])
  {
		[delegate dbIsReady];
	}
  [[NSNotificationCenter defaultCenter] postNotificationName:@"setWasChanged" object:self];
}

- (void)dealloc
{
  [super dealloc];
}

@end
