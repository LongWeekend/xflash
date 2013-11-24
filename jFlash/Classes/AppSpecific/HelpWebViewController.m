//
//  HelpWebViewController.m
//  jFlash
//
//  Created by Mark Makdad on 4/10/10.
//  Copyright 2010 LONG WEEKEND INC.. All rights reserved.
//

#import "HelpWebViewController.h"

@implementation HelpWebViewController

@synthesize filename, webView;

/**
 * Initializes the class and sets HTML filename to use and the title of the nav bar.
 * \param filename String containing the filename only (no path) of the HTML to load
 * \param title String to appear in the navigation bar
 */
- (id)initWithFilename:(NSString *)fn usingTitle:(NSString*) title
{
  if ((self = [super init]))
  {
    self.filename = fn;
    self.title = title;
  }
  return self;
}


/** Calls _loadPageWithBundleFilename and re-sets title */
- (void) loadPageWithBundleFilename:(NSString*)fn usingTitle:(NSString*) title
{
  self.filename = fn;
  self.title = title;
  [self _loadPageWithBundleFilename:fn];
}
 

/** Creates the UIWebView programmatically */
- (void) viewDidLoad
{
  [super viewDidLoad];

  [self.webView shutOffBouncing];
  [self _loadPageWithBundleFilename:self.filename];
}


/** Sets the nav bar tint to the current theme and sets the background to our standard */
- (void)viewWillAppear: (BOOL)animated
{
  self.navigationController.navigationBar.tintColor = [[ThemeManager sharedThemeManager] currentThemeTintColor];
  self.view.backgroundColor = [UIColor colorWithWhite:0.888 alpha:1.0];
}


/** Loads the filename into the _webView UIWebView - there should be no extension on the filename (but the actual file should be .html) */
- (void) _loadPageWithBundleFilename:(NSString*)fname
{
  // Prepare the URL
  NSString *urlAddress = [[NSBundle mainBundle] pathForResource:fname ofType:@"html" inDirectory:@"help"];
  NSURL *url = [NSURL fileURLWithPath:urlAddress];
  NSURLRequest *requestObj = [NSURLRequest requestWithURL:url];
  [self.webView loadRequest:requestObj];
}
 
         
//! Standard dealloc
- (void)dealloc
{
  [filename release];
  [webView release];
  [super dealloc];
}


@end
