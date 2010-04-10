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

- (HelpViewController*) init
{
  if (self = [super init])
  {
    // Set the tab bar controller image png to the targets
    self.tabBarItem.image = [UIImage imageNamed:@"90-lifebuoy.png"];
    self.title = @"Help";
  }
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
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateHTMlViewTheme) name:@"themeWasChanged" object:nil];
  self.htmlView.delegate = self;
}

- (void) viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  htmlView.opaque = NO;
  htmlView.backgroundColor = [UIColor clearColor];
  
  UIScrollView *scrollView = [htmlView.subviews objectAtIndex:0];
  SEL aSelector = NSSelectorFromString(@"setAllowsRubberBanding:");
  if([scrollView respondsToSelector:aSelector])
  {
    [scrollView performSelector:aSelector withObject:NO];
  }
  
  self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:TABLEVIEW_BACKGROUND_IMAGE]];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {  
  [self updateHTMlViewTheme];
}

// Quits the app opens in safari.app
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
  if (
      // URL to launch itunes app store on phone
      [[[request URL] absoluteString] isEqual:@"http://itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?id=367216357&onlyLatestVersion=true&pageNumber=0&sortOrdering=1&type=Purple+Software"]
  || 
      // URL to get satisfaction page
      [[[request URL] absoluteString] isEqual:@"http://support.longweekendmobile.com/"]
  ||
      // URL to our twitter page
      [[[request URL] absoluteString] isEqual:@"http://twitter.com/long_weekend"] 
  )
  {
    // Open links in safari.app
    [[UIApplication sharedApplication] openURL:[request URL]];
    return NO;
  }
  else 
  {
    return YES;
  }
}

// uses jQuery to update the fake nav controller theme colors in JQTouch
// This relies upon assets that have been hand-matched to the original UIKit components
// If you change any colors, these assets need to be changed too!
- (void)updateHTMlViewTheme
{
  NSString *themeName = [CurrentState getThemeName];
  NSString *selectColor;
  if([themeName isEqual:@"red"]) {
    selectColor = THEME_FIRE_WEB_SELECTED;
  } else {
    selectColor = THEME_WATER_WEB_SELECTED;
  }
  NSString *mystr = [NSString stringWithFormat:@""
   "$(document).ready(function(){ "
     "$('.toolbar').css('background', 'url(jqtouch/themes/jqt/img/toolbar-jflash-%@.png) #000000 repeat-x');"
     "$('.button, .back, .cancel, .add').css('-webkit-border-image', 'url(jqtouch/themes/jqt/img/button-jflash-%@.png) 0 5 0 5');"
     "$('.back').css('-webkit-border-image','url(jqtouch/themes/jqt/img/back_button-jflash-%@.png) 0 8 0 14');"
     "$('.back.active').css('-webkit-border-image','url(jqtouch/themes/jqt/img/back_button_clicked-jflash-%@.png) 0 8 0 14');"
     "$('ul li a.active').css('background-color','#%@');"
     "$('ul li a.active').css('color','#ffffff');"
   "});", themeName, themeName, themeName, themeName, selectColor];
 [htmlView stringByEvaluatingJavaScriptFromString:mystr];
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