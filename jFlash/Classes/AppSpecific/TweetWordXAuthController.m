//
//  TweetWordXAuthController.m
//  jFlash
//
//  Created by Rendy Pranata on 21/07/10.
//  Copyright 2010 Long Weekend LLC. All rights reserved.
//

#import "TweetWordXAuthController.h"
#import "LWETwitterOAuth.h"
#import "LWEViewAnimationUtils.h"

@implementation TweetWordXAuthController

@synthesize authEngine;
@synthesize unameTxt;
@synthesize passwordTxt;
@synthesize authBtn;
@synthesize signupBtn;

#pragma mark - UITextFieldDelegate

//! This method is used mainly for usability, and user experience for the easiness of use
- (BOOL) textFieldShouldReturn:(UITextField *)textField
{
	[textField resignFirstResponder];
	//When the textfield is the password, and
	//the username text field is not empty, goes straight to the authentication.
	//It makes the user not needed to click the authentication button.
	//If its the username text field, move to password text field
	if ((![unameTxt.text isEqualToString:@""]) && (textField == passwordTxt))
	{
		[LWEViewAnimationUtils translateView:self.view byPoint:CGPointMake(0,0) withInterval:0.5f];
		[self performSelector:@selector(authenticateUser:)
				   withObject:self 
				   afterDelay:0.0];
	}
	else if (textField == unameTxt)
	{
		[passwordTxt becomeFirstResponder];
	}
	return YES;
}

//! Moves the view, so the keyboard is not on top of the text field
- (BOOL) textFieldShouldBeginEditing:(UITextField *)textField
{
	//TODO: Calibrate this again
	if (textField == passwordTxt)
  {
		[LWEViewAnimationUtils translateView:self.view byPoint:CGPointMake(0,-75) withInterval:0.5f];
  }
	else if (textField == unameTxt)
  {
		[LWEViewAnimationUtils translateView:self.view byPoint:CGPointMake(0,-75) withInterval:0.5f];
  }
	return YES;
}

- (void) textFieldDidBeginEditing:(UITextField *)textField
{
	self.navigationItem.leftBarButtonItem = _doneBtn;
}

//! Bring back the cancel button, after done editing the text box. (For cancelling authentication)
- (void) textFieldDidEndEditing:(UITextField *)textField
{
	self.navigationItem.leftBarButtonItem = _cancelBtn;
}

#pragma mark - UIAlertViewDelegate

//! After the alert view is dismissed, clearing all the text fields.
- (void) alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
	self.passwordTxt.text = @"";
}

#pragma mark - LWETXAuthViewProtocol

//! This is the method called when authentication is failing. Either caused by the server, or the wrong username and password
- (void)didFailAuthentication:(NSError *)error
{
	if (_lv != nil)
	{
		[_lv removeFromSuperview];
		_lv = nil;
	}
	//Pop up an alert message for user, telling that the authentication is not successful.
  [LWEUIAlertView notificationAlertWithTitle:NSLocalizedString(@"Unable to Log In",@"TweetWordXAuthController.FailMsgTitle")
                                     message:NSLocalizedString(@"Please check your username and password and try again.  Also, make sure that you have a network connection.", @"TweetWordXAuthController.FailMsgMsg")];
}

#pragma mark - Header File Implementation

//! IBAction for "Authentication" button being clicked. It fires the authentication engine being passed to this view controller.
- (IBAction)authenticateUser:(id)sender
{
	_lv = [LWELoadingView loadingView:self.parentViewController.view withText:NSLocalizedString(@"Logging In",@"Logging In")];
  // TODO: MMA Danger Will Robinson, afterDelay:0.0
	[self performSelector:@selector(_performAuthentication) withObject:nil afterDelay:0.0];
}

/**
 * Jumps the user to the Twitter signup page
 */
- (IBAction) signupUser:(id)sender
{
  UIApplication *app = [UIApplication sharedApplication];
  NSURL *url = [NSURL URLWithString:@"https://twitter.com/signup"];
  [app openURL:url];
}

/**
 * Does the actual authentication
 */
- (void)_performAuthentication
{
	[self.authEngine startXAuthProcessWithUsername:self.unameTxt.text password:self.passwordTxt.text];
}

//! IBAction for cancelling the authentication proccess, and report back to the auth engine that the authorization has just failed.
- (void)cancelBtnTouchedUp:(id)sender
{
	//Notify the auth engine that authentication is failed. Caused by the user pressing "cancel" button.
	//IMPORTANT: Its not didFailedXAuth with ticket, because if its didFailedXAuth, the method is actually
	//going to call this view controller again, saying 
	//"Hey, the XAuth process is failed, prob caused by the user not giving the right username and password".
	[self.authEngine didFailedAuthorization];
	[self dismissModalViewControllerAnimated:YES];
}

//! Done button replaced the cancel button in the navigation controller, is used after the user is done with the text field.
- (void)doneBtnTouchedUp:(id)sender
{
	[self _textFieldResign];
}

//! Handy method to resign the responder, check which text box is currently is the first responder, and resign it. 
- (void)_textFieldResign
{
	if ([unameTxt isFirstResponder])
  {
		[unameTxt resignFirstResponder];
  }
	else if ([passwordTxt isFirstResponder])
  {
		[passwordTxt resignFirstResponder];
  }
	
	//Put the view back to the normal view
	[LWEViewAnimationUtils translateView:self.view byPoint:CGPointMake(0,0) withInterval:0.5f];
}


#pragma mark - UIViewController stuffs

//! When the view is touched, resign all of the text boxes
- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	[self _textFieldResign];
}


//! Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad 
{
    [super viewDidLoad];
	
	_cancelBtn = [[UIBarButtonItem alloc]
				  initWithTitle:NSLocalizedString(@"Cancel", @"Global.Cancel") 
				  style:UIBarButtonItemStylePlain 
				  target:self 
				  action:@selector(cancelBtnTouchedUp:)];
	_doneBtn = [[UIBarButtonItem alloc]
				  initWithTitle:NSLocalizedString(@"Done", @"Global.Done") 
				  style:UIBarButtonItemStyleDone
				  target:self 
				  action:@selector(doneBtnTouchedUp:)];
	
	self.title = NSLocalizedString(@"Log In to Twitter", @"TweetWordXAuthController.NavBarTitle");
	self.navigationItem.leftBarButtonItem = _cancelBtn;
}

//! Implemented because the view controller will have the same theme with the current theme selected
- (void) viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	self.navigationController.navigationBar.tintColor = [[ThemeManager sharedThemeManager] currentThemeTintColor];
	self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:TABLEVIEW_BACKGROUND_IMAGE]];
	
	self.unameTxt.text = @"";
	self.passwordTxt.text = @"";
}


- (void)viewDidUnload 
{
  [super viewDidUnload];
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

#pragma mark -

@end
