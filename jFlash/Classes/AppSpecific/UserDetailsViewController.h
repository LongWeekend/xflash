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

/**
 * I'm not sure I like this in general, but it's better than linking the 2 
 * VCs with notifications, as we were doing
 * MMA - Dec.02.2011
 */
@protocol UserDetailsViewControllerDelegate <NSObject>
- (void) userDetailsDidChange:(User*)user;
- (void) activateUser:(User*)user;
@end

@interface UserDetailsViewController : UIViewController <UIActionSheetDelegate>

- (id)initWithUserDetails:(User*)aUser;
- (IBAction) doCommitChanges;
- (IBAction) doActivateUser;
- (IBAction) doUpdateUserNickname:(id)sender;

@property (assign) id<UserDetailsViewControllerDelegate> delegate;

@property (nonatomic) NSInteger mode;
@property (nonatomic,retain) User *selectedUser;
@property (nonatomic,retain) UITextField *userNicknameTextField;
@property (nonatomic,retain) UIButton *commitChangesBtn;
@property (nonatomic,retain) UIButton *activateUserBtn;
@property (nonatomic,retain) NSString *originalUserNickname;

@end
