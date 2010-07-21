//
//  TweetWordXAuthController.h
//  jFlash
//
//  Created by Rendy Pranata on 21/07/10.
//  Copyright 2010 CRUX. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "LWETXAuthViewProtocol.h"

@interface TweetWordXAuthController : UIViewController
<LWETXAuthViewProtocol, UITextFieldDelegate, UIAlertViewDelegate>
{
	LWETwitterOAuth *authEngine;
	
	UIBarButtonItem *_cancelBtn;
	UIBarButtonItem *_doneBtn;
	IBOutlet UITextField *unameTxt;
	IBOutlet UITextField *passwordTxt;
	IBOutlet UIButton *authBtn;
}

- (IBAction)authenticateUser:(id)sender;

- (void)textFieldResign; 

@property (nonatomic, assign) LWETwitterOAuth *authEngine;
@property (nonatomic, retain) IBOutlet UITextField *unameTxt;
@property (nonatomic, retain) IBOutlet UITextField *passwordTxt;
@property (nonatomic, retain) IBOutlet UIButton *authBtn;

@end
