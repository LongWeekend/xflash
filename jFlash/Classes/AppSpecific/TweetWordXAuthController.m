//
//  TweetWordXAuthController.m
//  jFlash
//
//  Created by Rendy Pranata on 21/07/10.
//  Copyright 2010 CRUX. All rights reserved.
//

#import "TweetWordXAuthController.h"
#import "LWETwitterOAuth.h"
#import "LWEViewAnimationUtils.h"

@implementation TweetWordXAuthController

@synthesize authEngine;
@synthesize unameTxt;
@synthesize passwordTxt;
@synthesize authBtn;

#pragma mark -
#pragma mark UITextFieldDelegate

- (BOOL) textFieldShouldReturn:(UITextField *)textField
{
	[textField resignFirstResponder];
	if ((![unameTxt.text isEqualToString:@""]) && 
		  (textField == passwordTxt))
	{
    // RENDY: 0.5f is easier to read
		[LWEViewAnimationUtils translateView:self.view 
									 byPoint:CGPointMake(0,0) 
								withInterval:.5f];
    // After delay 0.0 also works!
		[self performSelector:@selector(authenticateUser:)
				   withObject:self 
				   afterDelay:.1];
	}
	else if (textField == unameTxt)
		[passwordTxt becomeFirstResponder];
	return YES;
}

- (BOOL) textFieldShouldBeginEditing:(UITextField *)textField
{
	self.navigationItem.leftBarButtonItem = _doneBtn;
	//TODO: Calibrate this again
	if (textField == passwordTxt)
		[LWEViewAnimationUtils translateView:self.view byPoint:CGPointMake(0,-80) withInterval:.5f];
	else if (textField == unameTxt)
		[LWEViewAnimationUtils translateView:self.view byPoint:CGPointMake(0,-30) withInterval:.5f];
	return YES;
}

- (void) textFieldDidEndEditing:(UITextField *)textField
{
	self.navigationItem.leftBarButtonItem = _cancelBtn;
}

#pragma mark -
#pragma mark UIAlertViewDelegate

// RENDY: this is actually harder to read for me!
- (void) alertView:(UIAlertView *)alertView 
didDismissWithButtonIndex:(NSInteger)buttonIndex
{
	unameTxt.text = @"";
	passwordTxt.text = @"";
}

#pragma mark -
#pragma mark LWETXAuthViewProtocol

- (void)didFailAuthentication:(NSError *)error
{
	UIAlertView *alert = [[UIAlertView alloc]
						  initWithTitle:NSLocalizedString(@"Unable to Log In",@"TweetWordXAuthController.FailMsgTitle") 
						  message:NSLocalizedString(@"Please check your username and password and try again.  Also, make sure that you have a network connection.",@"TweetWordXAuthController.FailMsgMsg")
						  delegate:self
              cancelButtonTitle:NSLocalizedString(@"OK",@"Global.OK") 
						  otherButtonTitles:nil];
	[alert show];
	[alert release];
}

#pragma mark -
#pragma mark Header File Implementation

-(IBAction) authenticateUser:(id)sender
{
	[self.authEngine startXAuthProcessWithUsername:unameTxt.text 
										  password:passwordTxt.text];
}


- (void)cancelBtnTouchedUp:(id)sender
{
	//TODO: CHANGE THIS!! - This works for now
	//but i dont think this is the right way
	[self.authEngine didFailedAuthorization];
	[self dismissModalViewControllerAnimated:YES];
}

- (void)doneBtnTouchedUp:(id)sender
{
	[self textFieldResign];
}

- (void)textFieldResign
{
	if ([unameTxt isFirstResponder])
		[unameTxt resignFirstResponder];
	else if ([passwordTxt isFirstResponder])
		[passwordTxt resignFirstResponder];
	[LWEViewAnimationUtils translateView:self.view 
								 byPoint:CGPointMake(0,0) 
							withInterval:.5f];
}


#pragma mark -
#pragma mark UIViewController stuffs

- (void) touchesBegan:(NSSet *)touches 
			withEvent:(UIEvent *)event
{
	[self textFieldResign];
}


// Implement viewDidLoad to do additional setup after 
// loading the view, typically from a nib.
- (void)viewDidLoad 
{
    [super viewDidLoad];
	
	_cancelBtn = [[UIBarButtonItem alloc]
				  initWithTitle:NSLocalizedString(@"Cancel",@"Global.Cancel") 
				  style:UIBarButtonItemStylePlain 
				  target:self 
				  action:@selector(cancelBtnTouchedUp:)];
	_doneBtn = [[UIBarButtonItem alloc]
				  initWithTitle:NSLocalizedString(@"Done",@"Global.Done") 
				  style:UIBarButtonItemStyleDone
				  target:self 
				  action:@selector(doneBtnTouchedUp:)];
	
	self.title = NSLocalizedString(@"Twitter Login",@"TweetWordXAuthController.NavBarTitle");
	self.navigationItem.leftBarButtonItem = _cancelBtn;
}


- (void) viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	self.navigationController.navigationBar.tintColor = [[ThemeManager sharedThemeManager] 
														 currentThemeTintColor];
	self.view.backgroundColor = [UIColor 
								 colorWithPatternImage:[UIImage imageNamed:TABLEVIEW_BACKGROUND_IMAGE]];
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
	self.unameTxt = nil;
	self.passwordTxt = nil;
	self.authBtn = nil;
}


- (void)dealloc 
{
	[unameTxt release];
	[passwordTxt release];
	[authBtn release];
	[_cancelBtn release];
	[_doneBtn release];
	
    [super dealloc];
}


@end
