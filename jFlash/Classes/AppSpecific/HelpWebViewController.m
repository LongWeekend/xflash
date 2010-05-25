//
//  HelpWebViewController.m
//  jFlash
//
//  Created by Mark Makdad on 4/10/10.
//  Copyright 2010 LONG WEEKEND INC.. All rights reserved.
//

#import "HelpWebViewController.h"


@implementation HelpWebViewController

@synthesize filename;

 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithFilename:(NSString *)fn usingTitle:(NSString*) title
{
  if (self = [super init])
  {
    [self setFilename:fn];
    [self setTitle:title];
  }
  return self;
}


- (void)loadView
{
  [super loadView];
  
  // Prepare the URL
  NSString *urlAddress = [[NSBundle mainBundle] pathForResource:[self filename] ofType:@"html" inDirectory:@"help"];
  NSURL *url = [NSURL fileURLWithPath:urlAddress];
  NSURLRequest *requestObj = [NSURLRequest requestWithURL:url];
  
  // Set up the views
  UIView *baseView = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];
  UIWebView *htmlView = [[UIWebView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 320.0f, 420.0f)];
  [htmlView setBackgroundColor:[UIColor clearColor]];
  [htmlView loadRequest:requestObj];
  [baseView addSubview:htmlView];
  baseView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:TABLEVIEW_BACKGROUND_IMAGE]];
  self.view = baseView;
}


- (void)dealloc
{
  [super dealloc];
}


@end
