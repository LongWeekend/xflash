//
//  TweetWordViewController.m
//  jFlash
//
//  Created by Rendy Pranata on 19/07/10.
//  Copyright 2010 Long Weekend LLC. All rights reserved.
//

#import "TweetWordViewController.h"
#import "LWETwitterEngine.h"
#import "LWETUser.h"
#import "Constants.h"

@implementation TweetWordViewController

@synthesize tweetTxt;
@synthesize tweetBtn;
@synthesize counterLbl;
@synthesize _tweetWord;
@synthesize _twitterEngine;

#pragma mark - Private Methods

//! Handy method to take care all of the text field keyboards.
- (void)_resignTextFieldKeyboard
{
	if ([self.tweetTxt isFirstResponder])
	{
		[self.tweetTxt resignFirstResponder];
		//get rid of the done button for the keyboard, replace w/ sign out button; get rid of cancel btn
		self.navigationItem.rightBarButtonItem = _signOutBtn;
		self.navigationItem.leftBarButtonItem = _cancelBtn;
		
		// Move the view up so the keyboard doesn't block the input
		[LWEViewAnimationUtils translateView:self.view byPoint:CGPointMake(0,0) withInterval:0.5f];
	}
}

#pragma mark -
#pragma mark IBAction

//! Tweet the text in the text fields, and add the " #xflash" after.
- (IBAction)tweet
{
  // Make sure they have network!
  if ([LWENetworkUtils networkAvailable])
  {
    [self _resignTextFieldKeyboard];
    NSString *tweet = [NSString stringWithFormat:@"%@ %@", tweetTxt.text, LWE_TWITTER_HASH_TAG];
    [_twitterEngine performSelectorInBackground:@selector(tweet:) withObject:tweet];
    
    _loadingView = [LWELoadingView loadingView:self.parentViewController.view withText:@"Tweeting..."];
  }
  else
  {
    [LWEUIAlertView noNetworkAlert];
  }

}

//! Sign out from the twitter engine.
- (IBAction) signUserOutOfTwitter:(id)sender
{
	[self._twitterEngine signOutForTheCurrentUser];
	[self dismissModalViewControllerAnimated:YES];
}

#pragma mark - UITextViewDelegate

//! Its handy to resign all of the keyboard it the user touch the view.
- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	[self _resignTextFieldKeyboard];
}

//! When the text view begins edit, change the cancel button on top of the navigation bar with the done button.
- (void) textViewDidBeginEditing:(UITextView *)textView
{
	self.navigationItem.leftBarButtonItem = nil;
	self.navigationItem.rightBarButtonItem = _doneBtn;	
	
	//Move the view up so the keyboard doesn't block the input
	[LWEViewAnimationUtils translateView:self.view byPoint:CGPointMake(0,-105) withInterval:0.5f];
}

//! The characters left label will update based on this method.
- (void) textViewDidChange:(UITextView *)textView
{
	NSUInteger c = [self.tweetTxt.text length];
	NSInteger length = LWE_TWITTER_MAX_CHARS - c;
	if (length >= 0)
	{
		self.counterLbl.text = [NSString stringWithFormat:@"%d", length];
	}
	else
	{
    self.counterLbl.text = [NSString stringWithFormat:@"%d", 0];
		textView.text = [textView.text substringToIndex:LWE_TWITTER_MAX_CHARS];
	}
}

#pragma mark - UIViewController stuffs

// The designated initializer.  Override if you 
// create the controller programmatically and want to 
// perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil 
{
	[NSException raise:NSGenericException format:@"Do not init without a twitter engine."];
	return self;
}

- (id)init
{
	[NSException raise:NSGenericException format:@"Do not init without a twitter engine."];
	return self;
}

//! This is the designated initialiser. 
- (id)initWithNibName:(NSString *)nibName twitterEngine:(LWETwitterEngine *)twitterEngine tweetWord:(NSString *)tweetWord
{
	if ((self = [super initWithNibName:nibName bundle:nil]))
	{
    _loadingView = nil;
		self._twitterEngine = twitterEngine;
		self._tweetWord = tweetWord;
	}
	return self;
}

//! Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad 
{
	[super viewDidLoad];
	_signOutBtn = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Logout",@"TweetWordViewController.LogOutFromTwitterBtn")
                                                style:UIBarButtonItemStyleBordered
                                                target:self
                                                action:@selector(signUserOutOfTwitter:)];
	
  _doneBtn = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(_resignTextFieldKeyboard)];
	_cancelBtn = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self.parentViewController action:@selector(dismissModalViewControllerAnimated:)];
	
	self.navigationItem.leftBarButtonItem = _cancelBtn;
	self.navigationItem.rightBarButtonItem = _signOutBtn;
	self.navigationItem.title = NSLocalizedString(@"Tweet this Card", @"TweetWordViewController.TweetThisCard");
	self.tweetTxt.text = _tweetWord;
	self.counterLbl.text = [NSString stringWithFormat:@"%d",(LWE_TWITTER_MAX_CHARS-[_tweetWord length])];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	self.navigationController.navigationBar.tintColor = [[ThemeManager sharedThemeManager] currentThemeTintColor];
	self.view.backgroundColor = [UIColor colorWithPatternImage: [UIImage imageNamed:LWETableBackgroundImage]];
}

- (void)viewDidUnload 
{
  [super viewDidUnload];
	self.tweetTxt = nil;
	self.tweetBtn = nil;
	self.counterLbl = nil;
}

- (void)dealloc 
{
	[_twitterEngine release];
	[_tweetWord release];
		
	if (_cancelBtn)
	{
		[_cancelBtn release];
	}
	
	if (_signOutBtn)
	{
		[_signOutBtn release];
	}
	
	if (_doneBtn)
	{
		[_doneBtn release];
	}
	
	[tweetTxt release];
	[tweetBtn release];
	[counterLbl release];
  [super dealloc];
}


@end