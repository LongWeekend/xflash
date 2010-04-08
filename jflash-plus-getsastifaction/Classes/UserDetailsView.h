//
//  UserDetailsView.h
//  jFlash
//
//  Created by paul on 1/2/10.
//  Copyright 2010 LONG WEEKEND INC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "User.h"
#import "UserImagePicker.h"

enum userViewMode {
  kUserViewModeAdd = 0,
  kUserViewModeEdit = 1,
  kUserViewModeLength
};

@interface UserDetailsView : UIViewController <UIActionSheetDelegate> {
  User* selectedUser;
  UserImagePicker *userImagePickerView;
  UIImage *selectedUserImage;
  IBOutlet UITextField *userNicknameTextField;
  IBOutlet UIButton *userAvatarPreviewBtn;
  IBOutlet UIButton *commitChangesBtn;
  IBOutlet UIButton *activateUserBtn;
  BOOL avatarUpdated;
  NSString* originalUserNickname;
  NSInteger mode;
}

- (IBAction) doShowImagePickerModalAction;
- (IBAction) doCommitChanges;
- (IBAction) doActivateUser;
- (IBAction) doUpdateUserNickname:(id)sender;

- (void) saveAvatarImage;
- (void) setUser:(User *)sourceUser;

@property (nonatomic) NSInteger mode;
@property (nonatomic,retain) User *selectedUser;
@property (nonatomic,retain) UITextField *userNicknameTextField;
@property (nonatomic,retain) UIButton *userAvatarPreviewBtn;
@property (nonatomic,retain) UIButton *commitChangesBtn;
@property (nonatomic,retain) UIButton *activateUserBtn;
@property (nonatomic,retain) UserImagePicker* userImagePickerView;
@property (nonatomic,retain) UIImage *selectedUserImage;
@property (nonatomic,retain) NSString* originalUserNickname;

@end
