//
//  UserDetailsView.m
//  jFlash
//
//  Created by paul on 1/2/10.
//  Copyright 2010 LONG WEEKEND INC. All rights reserved.
//

#import "UserDetailsView.h"
#import "UserView.h"

@implementation UserDetailsView
@synthesize selectedUser, mode, userNicknameTextField, originalUserNickname, userAvatarPreviewBtn, commitChangesBtn, activateUserBtn, userImagePickerView, selectedUserImage;

- (id)init {
  self = [super init];
  if(self){
    mode = kUserViewModeAdd;
    avatarUpdated = false;
    if(mode == kUserViewModeAdd) {
      self.selectedUser = [[[User alloc] init] autorelease];      
    }
  }
  return self;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  [userNicknameTextField becomeFirstResponder]; // makes keyboard cancellable
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(saveAvatarImage) name:@"newImagePicked" object:nil];
  [userNicknameTextField addTarget:self action:@selector(doUpdateUserNickname:) forControlEvents:UIControlEventEditingChanged];

  if(mode == kUserViewModeAdd){
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
  NSLog(@"img path: %@",[selectedUser avatarImagePath]);
  [userAvatarPreviewBtn setBackgroundImage:[selectedUser getUserThumbnailLarge] forState:UIControlStateNormal];
  self.navigationController.navigationBar.tintColor = [ApplicationSettings getThemeTintColor];
  self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:TABLEVIEW_BACKGROUND_IMAGE]];
  userNicknameTextField.backgroundColor = [UIColor whiteColor];
}

# pragma mark UI Responders

- (IBAction) doUpdateUserNickname:(id)sender;
{
  [selectedUser setUserNickname:[userNicknameTextField text]];
  if(mode == kUserViewModeEdit)
  {
    if([[userNicknameTextField text] isEqualToString:originalUserNickname] && !avatarUpdated)
      [commitChangesBtn setHidden:YES];
    else if([userNicknameTextField.text length] == 0)
      [commitChangesBtn setHidden:YES];
    else 
      [commitChangesBtn setHidden:NO];
  }
}

- (IBAction) doShowImagePickerModalAction
{
  UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Choose avatar image from?" 
    delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Photo Library", @"Take Photo With Camera", nil];
  [actionSheet showInView:self.parentViewController.tabBarController.view];
  [actionSheet release];
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
  if(avatarUpdated){
    [selectedUser saveAvatarImage:selectedUserImage];
  }
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

-(void) actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex{
  userImagePickerView = [[UserImagePicker alloc] init];
  if(buttonIndex == 0){
		userImagePickerView.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
  } else{
		userImagePickerView.sourceType = UIImagePickerControllerSourceTypeCamera;
  }
  [self.navigationController presentModalViewController:userImagePickerView animated:YES];
}

- (BOOL)textFieldShouldReturn:(UITextField *)theTextField 
{
  if([theTextField.text length] == 0)
  {
    UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:@"Enter User Name" message:@"Please enter a user name or click the arrow to go back." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alertView show];
    [alertView release];
    return NO;
  }
  [self doCommitChanges];
  return YES;
}

# pragma mark Other functions

- (void) saveAvatarImage
{
  // Show button to save changes
  [commitChangesBtn setHidden:NO];

  // Update on screen image only
  avatarUpdated = true;
  [userAvatarPreviewBtn setBackgroundImage:[userImagePickerView selectedImage] forState:UIControlStateNormal];

  // Save image in object so it doesn't go out of scope when it closes
  selectedUserImage = [userImagePickerView selectedImage]; // autoreleases!
}

- (void) setUser:(User *)sourceUser{
  // Make local copy or user
  self.selectedUser = [User getUser:[sourceUser userId]];
  originalUserNickname = [selectedUser userNickname];
  [originalUserNickname retain];
}

- (void)dealloc 
{
  [originalUserNickname release];
  [selectedUser release];
  [userNicknameTextField release];
  [userAvatarPreviewBtn release];
  [commitChangesBtn release];
  [activateUserBtn release];
  [super dealloc];
}

@end