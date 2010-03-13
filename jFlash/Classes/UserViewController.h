//
//  UserViewController.h
//  jFlash
//
//  Created by paul on 30/1/10.
//  Copyright 2010 LONG WEEKEND INC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "User.h"

@interface UserViewController : UITableViewController {
	NSMutableArray* usersArray;
  UIAlertView* statusMsgBox;
  User* selectedUserInArray; // Ptr to the selected user in usersArray
}

- (void)addUser:sender;
- (void)doActivateUser;

@property (nonatomic, retain) NSMutableArray *usersArray;
@property (nonatomic, retain) UIAlertView *statusMsgBox;
@property (nonatomic, retain) User* selectedUserInArray;

@end
