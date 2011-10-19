//
//  UserDetailsViewController.h
//  jFlash
//
//  Created by paul on 1/2/10.
//  Copyright 2010 LONG WEEKEND INC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "User.h"

enum userViewMode
{
  kUserViewModeAdd = 0,
  kUserViewModeEdit = 1,
  kUserViewModeLength
};

@interface UserDetailsViewController : UIViewController <UIActionSheetDelegate>

- (id)initWithUserDetails:(User*)aUser;
- (IBAction) doCommitChanges;
- (IBAction) doActivateUser;
- (IBAction) doUpdateUserNickname:(id)sender;

@property (nonatomic) NSInteger mode;
@property (nonatomic,retain) User *selectedUser;
@property (nonatomic,retain) UITextField *userNicknameTextField;
@property (nonatomic,retain) UIButton *commitChangesBtn;
@property (nonatomic,retain) UIButton *activateUserBtn;
@property (nonatomic,retain) NSString *originalUserNickname;

@end
