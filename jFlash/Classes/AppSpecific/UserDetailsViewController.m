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

- (id)init
{
  if ((self = [super init]))
  {
    [self setMode:kUserViewModeAdd];
    if ([self mode] == kUserViewModeAdd)
    {
      self.selectedUser = [[[User alloc] init] autorelease];      
    }
  }
  return self;
}

- (void) viewDidLoad
{
  [super viewDidLoad];
  [userNicknameTextField becomeFirstResponder]; // makes keyboard cancellable
  [userNicknameTextField addTarget:self action:@selector(doUpdateUserNickname:) forControlEvents:UIControlEventEditingChanged];

  if ([self mode] == kUserViewModeAdd)
  {
    [commitChangesBtn setHidden:YES];
    [activateUserBtn setHidden:YES];
  }
}

- (void)viewDidAppear:(BOOL)animated 
{
  [super viewDidAppear:animated];
  userNicknameTextField.text = [selectedUser userNickname];
}

- (void)viewWillAppear:(BOOL)animated 
{
  [super viewWillAppear:animated];
  userNicknameTextField.returnKeyType = UIReturnKeyDone;
  userNicknameTextField.placeholder = @"Type your name here";
	self.navigationController.navigationBar.tintColor = [[ThemeManager sharedThemeManager] currentThemeTintColor];
  // TODO: iPad customization!
  self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:TABLEVIEW_BACKGROUND_IMAGE]];
}

# pragma mark UI Responders

- (IBAction) doUpdateUserNickname:(id)sender;
{
  [selectedUser setUserNickname:[userNicknameTextField text]];
  if(mode == kUserViewModeEdit)
  {
    if([[userNicknameTextField text] isEqualToString:originalUserNickname])
      [commitChangesBtn setHidden:YES];
    else if([userNicknameTextField.text length] == 0)
      [commitChangesBtn setHidden:YES];
    else 
      [commitChangesBtn setHidden:NO];
  }
}

- (IBAction) doActivateUser
{
  // Activate, post notification and dismiss view
  [selectedUser activateUser];
  [[NSNotificationCenter defaultCenter] postNotificationName:@"settingsWereChanged" object:self];
  [self.navigationController popToRootViewControllerAnimated:YES];
}

- (IBAction) doCommitChanges
{
  // Save user details

  // Escape the string for SQLITE-style escapes (cannot use backslash!)
  NSMutableString* newUser = [[NSMutableString alloc] initWithString:[userNicknameTextField text]];
  [newUser replaceOccurrencesOfString:@"'" withString:@"''" options:NSLiteralSearch range:NSMakeRange(0, [newUser length])];
  [selectedUser setUserNickname:newUser];
  [selectedUser save];
  [newUser release];  
  
  // Close view and post notification
  [[NSNotificationCenter defaultCenter] postNotificationName:@"userSettingsWereChanged" object:self];
  [self.navigationController popViewControllerAnimated:YES];
}

- (BOOL)textFieldShouldReturn:(UITextField *)theTextField 
{
  if([theTextField.text length] == 0)
  {
    [LWEUIAlertView notificationAlertWithTitle:NSLocalizedString(@"Enter a Name",@"UserDetailsViewController.EnterNameAlertTitle")
                                       message:NSLocalizedString(@"Please enter a user name or click the arrow to go back.",@"UserDetailsViewController.EnterNameAlertMsg")];
    return NO;
  }
  [self doCommitChanges];
  return YES;
}

# pragma mark Other functions

- (void) setUser:(User *)sourceUser
{
  // Make local copy or user
  self.selectedUser = [UserPeer getUserByPK:[sourceUser userId]];
  originalUserNickname = [selectedUser userNickname];
  [originalUserNickname retain];
}

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