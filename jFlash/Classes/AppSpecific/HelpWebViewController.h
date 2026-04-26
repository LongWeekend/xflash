//
//  HelpWebViewController.h
//  jFlash
//
//  Created by Mark Makdad on 4/10/10.
//  Copyright 2010 LONG WEEKEND INC.. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>

@interface HelpWebViewController : UIViewController <WKNavigationDelegate>
{
  WKWebView *_webView;
}

- (id) initWithFilename:(NSString *)filename usingTitle:(NSString*) title;
- (void) loadPageWithBundleFilename:(NSString*)fn usingTitle:(NSString*) title;

//! Container view (XIB-instantiated UIView) that hosts the WKWebView added in viewDidLoad.
@property (nonatomic, retain) IBOutlet UIView *webViewContainer;

@property (nonatomic, retain) NSString *filename;

@end
