//
//  UserViewController.h
//  jFlash
//
//  Created by paul on 30/1/10.
//  Copyright 2010 LONG WEEKEND INC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "User.h"
#import "LWELoadingView.h"

/**
 * Shows a table of jFlash users, allows editing/deletion of users,
 * creation of new users
 */
@interface UserViewController : UITableViewController <UITableViewDelegate>

- (void) showUserDetailsView;
- (void) activateUserWithModal:(User*) user;

//! Loading modal when switching users on large sets
@property (nonatomic, retain) LWELoadingView *loadingView;

//! Holds an array of all users
@property (nonatomic, retain) NSMutableArray *usersArray;

//! Holds the User object of the currently selected user
@property (nonatomic, retain) User *selectedUserInArray;

@end
