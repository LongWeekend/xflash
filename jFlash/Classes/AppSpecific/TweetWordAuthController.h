//
//  TweetWordAuthController.h
//  jFlash
//
//  Created by Rendy Pranata on 20/07/10.
//  Copyright 2010 CRUX. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "LWETAuthenticationViewProtocol.h"

// RENDY:  Comment should go here about what this class does
@interface TweetWordAuthController : UIViewController <LWETAuthenticationViewProtocol, UIWebViewDelegate>
{
	id <LWETAuthenticationViewDelegate> delegate;
	UIWebView *webView;
  
  // RENDY:  @private keyword is helpful
	UIBarButtonItem *_cancelBtn;
	BOOL _firstLoaded;
}

// RENDY:  Don't worry about linebreak on 1. method signatures and 2. variable declarations
@property (nonatomic, retain) id<LWETAuthenticationViewDelegate> delegate;
@property (nonatomic, retain) IBOutlet UIWebView *webView;

@end
