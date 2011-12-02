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
  [self.userNicknameTextField becomeFirstResponder]; // makes keyboard cancellable
  [self.userNicknameTextField addTarget:self action:@selector(doUpdateUserNickname:) forControlEvents:UIControlEventEditingChanged];

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
}

- (void)viewWillAppear:(BOOL)animated 
{
  [super viewWillAppear:animated];
  // TODO: iPad customization!
	self.navigationController.navigationBar.tintColor = [[ThemeManager sharedThemeManager] currentThemeTintColor];
  self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:LWETableBackgroundImage]];
}

# pragma mark UI Responders

- (IBAction) doUpdateUserNickname:(id)sender;
{
  [self.selectedUser setUserNickname:[self.userNicknameTextField text]];
  if (self.mode == kUserViewModeEdit)
  {
    if([self.userNicknameTextField.text isEqualToString:self.originalUserNickname])
    {
      // User hasn't changed their name
      self.commitChangesBtn.hidden = YES;
    }
    else if ([self.userNicknameTextField.text length] == 0)
    {
      // You can't save it if there is no name
      self.commitChangesBtn.hidden = YES;
    }
    else 
    {
      // Otherwise show
      self.commitChangesBtn.hidden = NO;
    }
  }
}

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

- (IBAction) doCommitChanges
{
  // Save user details

  // Escape the string for SQLITE-style escapes (cannot use backslash!)
  NSMutableString* newUser = [[NSMutableString alloc] initWithString:[userNicknameTextField text]];
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

- (BOOL)textFieldShouldReturn:(UITextField *)theTextField 
{
  if ([theTextField.text length] == 0)
  {
    [LWEUIAlertView notificationAlertWithTitle:NSLocalizedString(@"Enter a Name",@"UserDetailsViewController.EnterNameAlertTitle")
                                       message:NSLocalizedString(@"Please enter a user name or click the arrow to go back.",@"UserDetailsViewController.EnterNameAlertMsg")];
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