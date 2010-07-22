//
//  TweetWordAuthController.h
//  jFlash
//
//  Created by Rendy Pranata on 20/07/10.
//  Copyright 2010 CRUX. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "LWETAuthenticationViewProtocol.h"

/**
 * This view controller is used for OAuth type of authentication, 
 * please refer to TweetWordXAuth View controller, 
 * because jFlash had been given the access to XAuth with twitter.
 * Tweet Word Authentication Controller has to conform with LWETAuthenticationViewProtocol
 * which forces the view controller to have delegate, and a web view.
 * It is used for authenticating a user with the twitter website, the web view
 * loads the website, and gives back the user PIN to be used for authenticating them in our
 * application
 */
@interface TweetWordAuthController : UIViewController <LWETAuthenticationViewProtocol, UIWebViewDelegate>
{
	id <LWETAuthenticationViewDelegate> delegate;
	UIWebView *webView;
  
@private
	UIBarButtonItem *_cancelBtn;
	BOOL _firstLoaded;
}

@property (nonatomic, retain) id<LWETAuthenticationViewDelegate> delegate;
@property (nonatomic, retain) IBOutlet UIWebView *webView;

@end
