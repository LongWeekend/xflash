//
//  TweetWordXAuthController.h
//  jFlash
//
//  Created by Rendy Pranata on 21/07/10.
//  Copyright 2010 Long Weekend LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "LWETXAuthViewProtocol.h"

/**
 * This view controller is used for authenticating a user, with their username and password. 
 * This view controller is intended to use with the XAuth type of authentication, therefore it has to conform
 * to the LWETXAuthViewProtocol forces the controller to have the LWETwitterOAuth as the authentication engine. 
 * It also acts as the UITextFieldDelegate, and UIAlertViewDelegate. So every text fields in the XIB will have this 
 * controller as their delegate. 
 */
@interface TweetWordXAuthController : UIViewController <LWETXAuthViewProtocol, UITextFieldDelegate, UIAlertViewDelegate>
{
	LWETwitterOAuth *authEngine;
	
@private
	UIBarButtonItem *_cancelBtn;
	UIBarButtonItem *_doneBtn;
}

- (IBAction)authenticateUser:(id)sender;
- (IBAction) signupUser:(id)sender;

- (void)_textFieldResign; 
- (void)_performAuthentication;

@property (nonatomic, assign) LWETwitterOAuth *authEngine;
@property (nonatomic, retain) IBOutlet UITextField *unameTxt;
@property (nonatomic, retain) IBOutlet UITextField *passwordTxt;
@property (nonatomic, retain) IBOutlet UIButton *authBtn;
@property (nonatomic, retain) IBOutlet UIButton *signupBtn;

@end
