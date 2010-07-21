//
//  UserDetailsViewController.h
//  jFlash
//
//  Created by paul on 1/2/10.
//  Copyright 2010 LONG WEEKEND INC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "User.h"

enum userViewMode {
  kUserViewModeAdd = 0,
  kUserViewModeEdit = 1,
  kUserViewModeLength
};

@interface UserDetailsViewController : UIViewController <UIActionSheetDelegate>
{
  User* selectedUser;
  IBOutlet UITextField *userNicknameTextField;
  IBOutlet UIButton *commitChangesBtn;
  IBOutlet UIButton *activateUserBtn;
  NSString* originalUserNickname;
  NSInteger mode;
}

- (IBAction) doShowImagePickerModalAction;
- (IBAction) doCommitChanges;
- (IBAction) doActivateUser;
- (IBAction) doUpdateUserNickname:(id)sender;

- (void) setUser:(User *)sourceUser;

@property (nonatomic) NSInteger mode;
@property (nonatomic,retain) User *selectedUser;
@property (nonatomic,retain) UITextField *userNicknameTextField;
@property (nonatomic,retain) UIButton *commitChangesBtn;
@property (nonatomic,retain) UIButton *activateUserBtn;
@property (nonatomic,retain) NSString* originalUserNickname;

@end
