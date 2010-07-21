//
//  TweetWordAuthController.h
//  jFlash
//
//  Created by Rendy Pranata on 20/07/10.
//  Copyright 2010 CRUX. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "LWETAuthenticationViewProtocol.h"


@interface TweetWordAuthController : UIViewController 
<LWETAuthenticationViewProtocol, UIWebViewDelegate>
{
	id <LWETAuthenticationViewDelegate> delegate;
	UIWebView *webView;
	UIBarButtonItem *_cancelBtn;
	BOOL _firstLoaded;
}

@property (nonatomic, retain) 
id<LWETAuthenticationViewDelegate> delegate;
@property (nonatomic, retain) IBOutlet UIWebView *webView;

@end
