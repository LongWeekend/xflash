//
//  HelpWebViewController.h
//  jFlash
//
//  Created by Mark Makdad on 4/10/10.
//  Copyright 2010 LONG WEEKEND INC.. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIWebView+LWENoBounces.h"

@interface HelpWebViewController : UIViewController <UIWebViewDelegate>

- (id) initWithFilename:(NSString *)filename usingTitle:(NSString*) title;
- (void) loadPageWithBundleFilename:(NSString*)fn usingTitle:(NSString*) title;

@property (nonatomic, retain) IBOutlet UIWebView *webView;

@property (nonatomic, retain) NSString *filename;

@end
