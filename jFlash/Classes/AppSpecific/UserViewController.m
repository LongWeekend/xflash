//
//  UserViewController.m
//  jFlash
//
//  Created by paul on 30/1/10.
//  Copyright 2010 LONG WEEKEND INC. All rights reserved.
//

#import "UserViewController.h"
#import "UserDetailsViewController.h"
#import "CustomCellBackgroundView.h"
#import "UserPeer.h"

/**
 * Grouped Table View where the user can select which user they will study as
 */
@implementation UserViewController
@synthesize usersArray, selectedUserInArray, loadingView;

- (id) init
{
	if ((self = [super initWithStyle:UITableViewStyleGrouped]))
  {
    self.title = NSLocalizedString(@"Choose User",@"UserViewController.NavBarTitle");
    self.tableView.delegate = self;
    [self setUsersArray:[UserPeer getUsers]];
  }
  return self;
}


/** UIView delegate - sets up add user button and reload observer */
- (void) loadView
{
  [super loadView];
  UIBarButtonItem *bbi = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(showUserDetailsView)];
  self.navigationItem.rightBarButtonItem = bbi;
  [bbi release];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadTableData) name:@"userSettingsWereChanged" object:nil];
}


/** Fetch user data and then call a table reload */
- (void)reloadTableData
{
  [self setUsersArray:[UserPeer getUsers]];
  [[self tableView] reloadData];
}

/** Update the view if any theme info changed */
- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  self.navigationController.navigationBar.tintColor = [[ThemeManager sharedThemeManager] currentThemeTintColor];
  // TODO: iPad customization!
  self.navigationController.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:TABLEVIEW_BACKGROUND_IMAGE]];
  [[self tableView] setSeparatorColor:[UIColor lightGrayColor]];
  [[self tableView] setBackgroundColor: [UIColor clearColor]];
  // MMA not sure if this is necessary
  [[self tableView] reloadData];
}

#pragma mark Table view methods

//! Hardcoded to return 1
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
  return 1;
}

//! Returns the number of users in the usersArray
- (NSInteger)tableView:(UITableView *)lclTableView numberOfRowsInSection:(NSInteger)section
{
  return [[self usersArray] count];
}

//! Reloads specific cells
- (void)reloadRowsAtIndexPaths:(NSArray *)indexPaths withRowAnimation:(UITableViewRowAnimation)animation
{
  for (NSIndexPath *indexPath in indexPaths)
  {
    [self tableView:[self tableView] cellForRowAtIndexPath:indexPath];
  }
}

- (UITableViewCell *)tableView:(UITableView *)lclTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{

  NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
  NSString* tmpNickname = [[usersArray objectAtIndex:indexPath.row] userNickname];
  UITableViewCell *cell;

  // Selected cells are highlighted
  if([settings integerForKey:@"user_id"] == [[usersArray objectAtIndex:indexPath.row] userId])
  {
    cell = [LWEUITableUtils reuseCellForIdentifier:@"CellHighlighted" onTable:lclTableView usingStyle:UITableViewCellStyleDefault];
    
    CustomCellBackgroundView *bgView = [[CustomCellBackgroundView alloc] initWithFrame:CGRectZero];
    [bgView setCellIndexPath:indexPath tableLength:[usersArray count]];
    [bgView setBorderColor:[lclTableView separatorColor]];
    [bgView setFillColor:[[ThemeManager sharedThemeManager] currentThemeTintColor]];
    cell.textLabel.backgroundColor = [UIColor clearColor];
    cell.textLabel.textColor = [UIColor whiteColor];
    cell.backgroundView = bgView;
    [bgView release];
  }
  // Unselected cells are white
  else 
  {
    cell = [LWEUITableUtils reuseCellForIdentifier:@"CellWhite" onTable:lclTableView usingStyle:UITableViewCellStyleDefault];

    cell.textLabel.backgroundColor = [UIColor clearColor];
    cell.textLabel.textColor = [UIColor blackColor];
    cell.backgroundColor = [UIColor whiteColor];
  }

  cell.textLabel.text = tmpNickname;
  cell.accessoryType  = UITableViewCellAccessoryDetailDisclosureButton;
  cell.accessoryView = nil;
  cell.selectionStyle = UITableViewCellSelectionStyleNone;
  
  return cell;
}

- (void)tableView:(UITableView *)lclTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  selectedUserInArray = [[self usersArray] objectAtIndex:(NSInteger)indexPath.row];
  NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
  if ([selectedUserInArray userId] == [settings integerForKey:@"user_id"])
  {
    return; 
  }
  [lclTableView deselectRowAtIndexPath:indexPath animated:NO];
  selectedUserInArray = [[self usersArray] objectAtIndex:(NSInteger)indexPath.row];
  NSString* message = [NSString stringWithFormat:NSLocalizedString(@"Set the active user to %@?",@"UserViewController.ChangeUser_AlertViewMessage"), [selectedUserInArray userNickname]];
  [LWEUIAlertView confirmationAlertWithTitle:NSLocalizedString(@"Activate User",@"UserViewController.ChangeUser_AlertViewTitle") message:message delegate:self];
}


- (void) alertView: (UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
  // user activation confirmed 
  if (buttonIndex == LWE_ALERT_OK_BTN)
  {
    [self activateUserWithModal:[self selectedUserInArray]];
  }
}


/**
 * Load UserDetailsViewController onto the navigation controller stack
 * Allows user to edit user info 
 */
- (void)tableView:(UITableView *)lclTableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
  [lclTableView deselectRowAtIndexPath:indexPath animated:NO];
  UserDetailsViewController *userDetailsView = [[UserDetailsViewController alloc] init];
  User* currUser = [[self usersArray] objectAtIndex:indexPath.row];
  [userDetailsView setUser:currUser];
  [userDetailsView setTitle: [currUser userNickname]];
  [userDetailsView setMode: kUserViewModeEdit];
  [self.navigationController pushViewController:userDetailsView animated:YES];
  [userDetailsView release];
}

//! Delete row from table
- (void)tableView:(UITableView *)lclTableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
  if (editingStyle == UITableViewCellEditingStyleDelete)
  {
    // Cancel deletion if the user is ID=1
    NSInteger selectedUserId = [[usersArray objectAtIndex:indexPath.row] userId];
    if (selectedUserId == DEFAULT_USER_ID)
    {
      [LWEUIAlertView notificationAlertWithTitle:NSLocalizedString(@"Cannot Delete User",@"UserViewController.CannotDelete_AlertViewTitle")
                                         message:NSLocalizedString(@"The default user can be edited, but not deleted.",@"UserViewController.CannotDelete_AlertViewMessage")];
      return;
    }

    // Delete the row from the data source
    User *tmpUser = [usersArray objectAtIndex:indexPath.row];
    [tmpUser deleteUser];

    // Remove from usersArray
    [usersArray removeObjectAtIndex:indexPath.row];

    // If we just deleted the active user, change to iPhone Owner
    NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
    if (selectedUserId == [settings integerForKey:@"user_id"])
    {
      [self activateUserWithModal:[UserPeer getUserByPK:DEFAULT_USER_ID]];
    }
    
    // Delete from table
    [lclTableView deleteRowsAtIndexPaths:[NSArray arrayWithObjects:indexPath,nil] withRowAnimation:UITableViewRowAnimationRight];

    // Redraw table if needed
    [[self tableView] reloadData];
  }
}

# pragma mark UI Responders

/** Takes a user objects and activates it, calling notifications appropriately */
- (void) activateUserWithModal:(User*) user
{
  // First, show the loading modal, then call selector after delay to allow it to appear
  self.loadingView = [LWELoadingView loadingView:[self view] withText:NSLocalizedString(@"Switching User...",@"UserViewController.SwitchingUserDialog")];

  // Now do it
  [self performSelector:@selector(_activateUser:) withObject:user afterDelay:0.0];
}


/**
 * Called exclusively by activateUserWithModal
 * Completes the activation and dismisses the modal set up by
 * activateUserWithModal
 */
- (void) _activateUser:(User*) user 
{
  // Activate, post notification and dismiss view
  [user activateUser];
  [[NSNotificationCenter defaultCenter] postNotificationName:@"userWasChanged" object:self];
  [self.loadingView removeFromSuperview];
  [self.navigationController popViewControllerAnimated:YES];
}


/** Pushs the user details view controller onto the nav controller stack */
- (void) showUserDetailsView
{
  // TODO: iPad customization!
  UserDetailsViewController *userDetailsView = [[UserDetailsViewController alloc] init];
  userDetailsView.title = NSLocalizedString(@"Add User",@"UserDetailsViewController.NavBarTitle");
  userDetailsView.mode = kUserViewModeAdd;
  [self.navigationController pushViewController:userDetailsView animated:YES];
	[userDetailsView release];

}

- (void) viewDidUnload
{
  [super viewDidUnload];
  [[NSNotificationCenter defaultCenter] removeObserver:self name:@"userSettingsWereChanged" object:nil];
}

- (void)dealloc
{
  [self setUsersArray:nil];
  [super dealloc];
}

@end
