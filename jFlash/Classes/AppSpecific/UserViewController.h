//
//  UserViewController.h
//  jFlash
//
//  Created by paul on 30/1/10.
//  Copyright 2010 LONG WEEKEND INC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "User.h"
#import "LoadingView.h"

/**
 * Shows a table of jFlash users, allows editing/deletion of users,
 * creation of new users
 */
@interface UserViewController : UITableViewController <UITableViewDelegate>
{
	NSMutableArray* usersArray;     //! Holds an array of all users
  User* selectedUserInArray;      //! Holds the User object of the currently selected user
  LoadingView *loadingView;       //! Loading modal when switching users on large sets
}

- (void) showUserDetailsView;
- (void) activateUserWithModal:(User*) user;

@property (nonatomic, retain) LoadingView *loadingView;
@property (nonatomic, retain) NSMutableArray *usersArray;
@property (nonatomic, retain) User* selectedUserInArray;

@end
