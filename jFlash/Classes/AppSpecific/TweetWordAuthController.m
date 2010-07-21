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

- (void) webView:(UIWebView *)webView 
didFailLoadWithError:(NSError *)error
{
	LWE_LOG(@"ERROR");
	LWE_LOG(@"%@", [error userInfo]);
}

- (void) webViewDidFinishLoad:(UIWebView *)aWebView
{
	if (!_firstLoaded)
	{
		NSString *script;
		script = @"(function() { return document.getElementById(\"oauth_pin\").firstChild.textContent; } ())";
		
		NSString *pin = [self.webView stringByEvaluatingJavaScriptFromString:script];
		
		if ([pin length] > 0) {
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

- (void) webViewDidStartLoad:(UIWebView *)webView
{
	LWE_LOG(@"Start Load");
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
				  initWithTitle:@"Cancel" 
				  style:UIBarButtonItemStylePlain 
				  target:self 
				  action:@selector(cancelBtnTouchedUp:)];
	
	self.title = @"Authentication";
	self.navigationItem.leftBarButtonItem = _cancelBtn;	
	_firstLoaded = YES;
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	self.navigationController.navigationBar.tintColor = [[ThemeManager sharedThemeManager]
														 currentThemeTintColor];
	self.view.backgroundColor = [UIColor colorWithPatternImage:
								 [UIImage imageNamed:TABLEVIEW_BACKGROUND_IMAGE]];
	
}

- (void)didReceiveMemoryWarning 
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
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
