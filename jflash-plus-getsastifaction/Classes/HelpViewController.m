//
//  HelpViewController.m
//  jFlash
//
//  Created by シャロット ロス on 12/28/09.
//  Copyright 2009 LONG WEEKEND INC.. All rights reserved.
//

#import "HelpViewController.h"

@implementation HelpViewController
@synthesize baseView, htmlView;

- (HelpViewController*) init {
	self = [super init];
  return self;
}

- (void)loadView
{
  [super loadView];
	// Load an application image and set it as the primary view
	baseView = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];
  htmlView = [[UIWebView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 320.0f, 420.0f)];
  [baseView addSubview:htmlView];
	self.view = baseView;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  [self loadWebView];
  self.htmlView.delegate = self;
}

- (void) viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  [self loadWebView];
  htmlView.opaque = NO;
  htmlView.backgroundColor = [UIColor clearColor];
  self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:TABLEVIEW_BACKGROUND_IMAGE]];
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
  if ([[[request URL] absoluteString] isEqual:@"http://getsatisfaction.com/longweekend"] || [[[request URL] absoluteString] isEqual:@"http://www.getsatisfaction.com/longweekend"])
  {
    // Open getsatisfaction.com link in safari.app
    [[UIApplication sharedApplication] openURL:[request URL]];
    return NO;
  }
  else 
  {
    return YES;
  }
}

- (void) loadWebView
{
  NSString *urlAddress = [[NSBundle mainBundle] pathForResource:@"help" ofType:@"html" inDirectory:@"help"];
  NSURL *url = [NSURL fileURLWithPath:urlAddress];
  NSURLRequest *requestObj = [NSURLRequest requestWithURL:url];
  [htmlView loadRequest:requestObj];
}

- (void)dealloc {
  [baseView release];
  htmlView.delegate = nil;
  [htmlView release];
  [super dealloc];
}

@end