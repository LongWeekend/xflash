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

/**
 * Initializes the class and sets HTML filename to use and the title of the nav bar.
 * \param filename String containing the filename only (no path) of the HTML to load
 * \param title String to appear in the navigation bar
 */
- (id)initWithFilename:(NSString *)fn usingTitle:(NSString*) title
{
  if ((self = [super init]))
  {
    [self setFilename:fn];
    [self setTitle:title];
  }
  return self;
}


/** Calls _loadPageWithBundleFilename and re-sets title */
- (void) loadPageWithBundleFilename:(NSString*)fn usingTitle:(NSString*) title
{
  [self setFilename:fn];
  [self setTitle:title];
  [self _loadPageWithBundleFilename:[self filename]];
}
 

/** Creates the UIWebView programmatically */
- (void)loadView
{
  [super loadView];
  self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:TABLEVIEW_BACKGROUND_IMAGE]];
  
  _webView = [[UIWebView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 320.0f, 375.0f)];
  _webView.delegate = self;
  _webView.opaque = NO;
  _webView.backgroundColor = [UIColor clearColor];

  [_webView shutOffBouncing];
  [self _loadPageWithBundleFilename:[self filename]];
  [[self view] addSubview:_webView];
}


/** Sets the nav bar tint to the current theme and sets the background to our standard */
- (void)viewWillAppear: (BOOL)animated
{
  self.navigationController.navigationBar.tintColor = [[ThemeManager sharedThemeManager] currentThemeTintColor];
  self.navigationController.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:TABLEVIEW_BACKGROUND_IMAGE]];
}


/** Loads the filename into the _webView UIWebView - there should be no extension on the filename (but the actual file should be .html) */
- (void) _loadPageWithBundleFilename:(NSString*)fname
{
  // Prepare the URL
  NSString *urlAddress = [[NSBundle mainBundle] pathForResource:fname ofType:@"html" inDirectory:@"help"];
  NSURL *url = [NSURL fileURLWithPath:urlAddress];
  NSURLRequest *requestObj = [NSURLRequest requestWithURL:url];
  [_webView loadRequest:requestObj];
}
 
         
//! Standard dealloc
- (void)dealloc
{
  [super dealloc];
  [_webView release];
}


@end
