//
//  TweetWordAuthController.m
//  jFlash
//
//  Created by Rendy Pranata on 20/07/10.
//  Copyright 2010 CRUX. All rights reserved.
//

#import "TweetWordAuthController.h"
#import "Constants.h"
#import "LWEDebug.h"

@implementation TweetWordAuthController

@synthesize webView;
@synthesize delegate;

#pragma mark -
#pragma mark UIWebViewDelegate

//! Using the UIWebViewDelegate to get the report if the web view is loaded with some error
- (void) webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
	//TODO: Deal with the error
	//and if its fatal might as well get back to the delegate, or refreshing the web view?
	LWE_LOG(@"Error: Web view authentication is loaded with this error : %@", [error userInfo]);
}


//! Using the UIWebViewDelegate to get the report if the web view finishes loading.
- (void) webViewDidFinishLoad:(UIWebView *)aWebView
{
	if (!_firstLoaded)
	{
		NSString *script;
		//Get the pin out of the pin div that are provided by the twitter website with help of javascript.
		script = @"(function() { return document.getElementById(\"oauth_pin\").firstChild.textContent; } ())";
		
		NSString *pin = [self.webView stringByEvaluatingJavaScriptFromString:script];
		
		//if the user goes to the right page with the "pin div" it gives the pin back
		//to the delegate, however, if the pin is not there. It will still keep going. 
		if ([pin length] > 0)
		{
			NSLog(@"pin %@", pin);
			
			if ([delegate respondsToSelector:@selector(didFinishAuthorizationWithPin:)])
				[delegate didFinishAuthorizationWithPin:pin];
			
			[self dismissModalViewControllerAnimated:NO];	
		}
	}
	else 
	{
		//scroll the view, so the user is presented with the username and
		//password staright away
		[aWebView stringByEvaluatingJavaScriptFromString:@"window.scrollTo(0,350);"];
		_firstLoaded = NO;
	}
}

#pragma mark -
#pragma mark Header File Implementation

- (void)cancelBtnTouchedUp:(id)sender
{
	if ([delegate respondsToSelector:@selector(didFailedAuthorization)])
		[delegate didFailedAuthorization];
	[self dismissModalViewControllerAnimated:NO];
}


#pragma mark -
#pragma mark UIViewController stuffs

- (void) viewDidLoad
{
	[super viewDidLoad];
	
	_cancelBtn = [[UIBarButtonItem alloc]
				  initWithTitle:NSLocalizedString(@"Cancel",@"Global.Cancel") 
				  style:UIBarButtonItemStylePlain 
				  target:self 
				  action:@selector(cancelBtnTouchedUp:)];
	
	self.title = NSLocalizedString(@"Twitter Sign-in",@"TweetWordAuthController.NavBarTitle");
	self.navigationItem.leftBarButtonItem = _cancelBtn;	
	_firstLoaded = YES;
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	self.navigationController.navigationBar.tintColor = [[ThemeManager sharedThemeManager]
														 currentThemeTintColor];
	//IPAD customization?
	self.view.backgroundColor = [UIColor colorWithPatternImage:
								 [UIImage imageNamed:TABLEVIEW_BACKGROUND_IMAGE]];
	
}

- (void)viewDidUnload 
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
	self.webView = nil;
}


- (void)dealloc 
{
	[webView release];
	[_cancelBtn release];
    [super dealloc];
}


@end