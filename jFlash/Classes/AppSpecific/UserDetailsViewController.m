//
//  UserDetailsViewController.m
//  jFlash
//
//  Created by paul on 1/2/10.
//  Copyright 2010 LONG WEEKEND INC. All rights reserved.
//

#import "UserDetailsViewController.h"
#import "UserViewController.h"
#import "UserPeer.h"

@implementation UserDetailsViewController
@synthesize selectedUser, mode, userNicknameTextField, originalUserNickname, commitChangesBtn, activateUserBtn;
@synthesize delegate;

- (id)initWithUserDetails:(User*)aUser
{
  if ((self = [super init]))
  {
    if (aUser)
    {
      self.mode = kUserViewModeEdit;
      self.originalUserNickname = aUser.userNickname;
      self.title = aUser.userNickname;
      self.selectedUser = aUser;
    }
    else
    {
      self.title = NSLocalizedString(@"Add User",@"UserDetailsViewController.NavBarTitle");
      self.mode = kUserViewModeAdd;
      self.selectedUser = [[[User alloc] init] autorelease];
    }
  }
  return self;
}

- (void) viewDidLoad
{
  [super viewDidLoad];
  
  // Start editing right away
  [self.userNicknameTextField becomeFirstResponder];

  // Hide all the buttons if we are adding a new user
  if (self.mode == kUserViewModeAdd)
  {
    self.commitChangesBtn.hidden = YES;
    self.activateUserBtn.hidden = YES;
  }
  else
  {
    self.userNicknameTextField.text = [self.selectedUser userNickname];
  }
  
  // Finally, customize the buttons
  [self.commitChangesBtn useGreenConfirmStyle];
  self.commitChangesBtn.layer.borderWidth = 2.5f;
  self.commitChangesBtn.layer.cornerRadius = 9.0f;

  [self.activateUserBtn useGreenConfirmStyle];
  self.activateUserBtn.layer.borderWidth = 2.5f;
  self.activateUserBtn.layer.cornerRadius = 9.0f;
}

- (void)viewWillAppear:(BOOL)animated 
{
  [super viewWillAppear:animated];
  // TODO: iPad customization!
	self.navigationController.navigationBar.tintColor = [[ThemeManager sharedThemeManager] currentThemeTintColor];
  self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:LWETableBackgroundImage]];
}

# pragma mark UI Responders

- (IBAction) doActivateUser
{
  // Dismiss this VC
  [self.navigationController popToRootViewControllerAnimated:YES];

  // Activate
  if (self.delegate && [self.delegate respondsToSelector:@selector(activateUser:)])
  {
    [self.delegate activateUser:self.selectedUser];
  }
}

// Save user details
- (IBAction) doCommitChanges
{
  // Escape the string for SQLITE-style escapes (cannot use backslash!)
  NSMutableString *newUser = [[NSMutableString alloc] initWithString:self.userNicknameTextField.text];
  // TODO: When we switch to parameter binding, this can go
  [newUser replaceOccurrencesOfString:@"'" withString:@"''" options:NSLiteralSearch range:NSMakeRange(0, [newUser length])];
  [self.selectedUser setUserNickname:newUser];
  [self.selectedUser save];
  [newUser release];
  
  // We're done with this VC
  [self.navigationController popViewControllerAnimated:YES];

  if (self.delegate && [self.delegate respondsToSelector:@selector(userDetailsDidChange:)])
  {
    [self.delegate userDetailsDidChange:self.selectedUser];
  }
}

#pragma mark - UITextFieldDelegate Methods 

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
  if (self.mode == kUserViewModeEdit && textField == self.userNicknameTextField)
  {
    // Hide the "Save" button if the user's input is blank or equal to the old nickname.
    NSString *proposedNewString = [self.userNicknameTextField.text stringByReplacingCharactersInRange:range withString:string];
    BOOL noChanges = [proposedNewString isEqualToString:self.originalUserNickname];
    BOOL noInput = ([proposedNewString length] == 0);
    self.commitChangesBtn.hidden = (noChanges || noInput);
  }
  return YES;
}

- (BOOL)textFieldShouldClear:(UITextField *)textField
{
  self.commitChangesBtn.hidden = YES;
  return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)theTextField 
{
  if ([theTextField.text length] == 0)
  {
    [LWEUIAlertView notificationAlertWithTitle:NSLocalizedString(@"Enter a Name",@"UserDetailsViewController.EnterNameAlertTitle")
                                       message:NSLocalizedString(@"Please enter a user name or tap back to cancel.",@"UserDetailsViewController.EnterNameAlertMsg")];
    return NO;
  }
  [self doCommitChanges];
  return YES;
}

# pragma mark Other functions

- (void)dealloc 
{
  [originalUserNickname release];
  [selectedUser release];
  [userNicknameTextField release];
  [commitChangesBtn release];
  [activateUserBtn release];
  [super dealloc];
}

@end