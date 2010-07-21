//
//  TweetWordViewController.m
//  jFlash
//
//  Created by Rendy Pranata on 19/07/10.
//  Copyright 2010 CRUX. All rights reserved.
//

#import "TweetWordViewController.h"
#import "LWETwitterEngine.h"
#import "LWETUser.h"
#import "Constants.h"

@implementation TweetWordViewController

@synthesize tweetTxt;
@synthesize tweetBtn;
@synthesize counterLbl;

#pragma mark -
#pragma mark Private Methods

- (void)_resignTextFieldKeyboard
{
	if ([tweetTxt isFirstResponder])
	{
		[tweetTxt resignFirstResponder];
		//get rid of the done button for the keyboard
		self.navigationItem.rightBarButtonItem = nil;
		//set back the cancel button
		self.navigationItem.leftBarButtonItem = _cancelBtn;
		
		// Move the view up so the keyboard doesn't block the input
		[LWEViewAnimationUtils translateView:self.view byPoint:CGPointMake(0,0) withInterval:0.5f];
	}
}

#pragma mark -
#pragma mark IBAction

- (IBAction)tweet
{
	[self _resignTextFieldKeyboard];
	NSString *string = [NSString stringWithFormat:@"%@ #jFlash", tweetTxt.text];
	[_twitterEngine tweet:string];
}

#pragma mark -
#pragma mark UITextViewDelegate

- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	[self _resignTextFieldKeyboard];
}

- (void) textViewDidBeginEditing:(UITextView *)textView
{
	UIBarButtonItem *doneBtn = [[UIBarButtonItem alloc]
								initWithTitle:NSLocalizedString(@"Done", 
																@"Global.Done") 
								style:UIBarButtonItemStyleDone 
								target:self 
								action:@selector(_resignTextFieldKeyboard)];
	self.navigationItem.leftBarButtonItem = nil;
	self.navigationItem.rightBarButtonItem = doneBtn;	
	
	// Move the view up so the keyboard doesn't block the input
	//TODO: Calibrate the point after set everything up
	[LWEViewAnimationUtils translateView:self.view 
								 byPoint:CGPointMake(0,-70) 
							withInterval:0.5f];
}

- (void) textViewDidChange:(UITextView *)textView
{
	NSUInteger c = [tweetTxt.text length];
	NSInteger length = kMaxChars - c;
	if (length >= 0)
		counterLbl.text = [NSString stringWithFormat:@"%d", length];
	else
		textView.text = [textView.text substringToIndex:kMaxChars];
}

#pragma mark -
#pragma mark UIViewController stuffs

// The designated initializer.  Override if you 
// create the controller programmatically and want to 
// perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil 
			   bundle:(NSBundle *)nibBundleOrNil 
{
	[NSException raise:NSGenericException 
				format:@"Do not init without a twitter engine."];
	return self;
}

- (id)init
{
	[NSException raise:NSGenericException 
				format:@"Do not init without a twitter engine."];
	return self;
}
							  
- (id)initWithNibName:(NSString *)nibName 
		twitterEngine:(LWETwitterEngine *)twitterEngine 
			tweetWord:(NSString *)tweetWord
{
	if (self = [super initWithNibName:nibName bundle:nil])
	{
		_twitterEngine = [twitterEngine retain];
		_tweetWord = [tweetWord retain];
	}
	return self;
}

// Implement viewDidLoad to do additional setup after loading the view, 
// typically from a nib.
- (void)viewDidLoad 
{		
    [super viewDidLoad];
	
	_cancelBtn = [[UIBarButtonItem alloc]
				  initWithTitle:NSLocalizedString(@"Cancel", @"Global.Cancel")
				  style:UIBarButtonItemStylePlain 
				  target:self.parentViewController 
				  action:@selector(dismissModalViewControllerAnimated:)];
	self.navigationItem.leftBarButtonItem = _cancelBtn;
	//TODO: CHANGE TO LOCALIZED STRING
	self.navigationItem.title = @"Tweet Card";
	self.tweetTxt.text = _tweetWord;
	self.counterLbl.text = [NSString stringWithFormat:@"%d", 
							(kMaxChars-[_tweetWord length])];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	self.navigationController.navigationBar.tintColor = [[ThemeManager sharedThemeManager] 
														 currentThemeTintColor];
	self.view.backgroundColor = [UIColor colorWithPatternImage:
								 [UIImage imageNamed:TABLEVIEW_BACKGROUND_IMAGE]];
}


/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

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
	self.tweetTxt = nil;
	self.tweetBtn = nil;
	self.counterLbl = nil;
}

- (void)dealloc 
{
	[_twitterEngine release];
	if (_tweetWord)
		[_tweetWord release];
	if (_cancelBtn)
		[_cancelBtn release];
	[tweetTxt release];
	[tweetBtn release];
	[counterLbl release];
    [super dealloc];
}


@end