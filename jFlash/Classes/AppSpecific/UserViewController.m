//
//  UserViewController.m
//  jFlash
//
//  Created by paul on 30/1/10.
//  Copyright 2010 LONG WEEKEND INC. All rights reserved.
//

#import "UserViewController.h"
#import "LoadingView.h"
#import "UserDetailsViewController.h"
#import "CustomCellBackgroundView.h"

/**
 * Grouped Table View where the user can select which user they will study as
 */
@implementation UserViewController
@synthesize usersArray, statusMsgBox, selectedUserInArray, loadingView;

- (id) init
{
	if (self = [super initWithStyle:UITableViewStyleGrouped])
  {
    self.title = NSLocalizedString(@"Choose User",@"UserViewController.NavBarTitle");
    self.tableView.delegate = self;
    [self setUsersArray:[User getUsers]];
  }
  return self;
}


/** UIView delegate - sets up add user button and reload observer */
- (void) loadView
{
  [super loadView];
  self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addUser:)];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadTableData) name:@"userSettingsWereChanged" object:nil];
}


- (void)reloadTableData
{
  [self setUsersArray:[User getUsers]];
  [[self tableView] reloadData];
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  self.navigationController.navigationBar.tintColor = [[ThemeManager sharedThemeManager] currentThemeTintColor];
  self.navigationController.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:TABLEVIEW_BACKGROUND_IMAGE]];
  [[self tableView] setSeparatorColor:[UIColor lightGrayColor]];
  [[self tableView] setBackgroundColor: [UIColor clearColor]];
  [[self tableView] reloadData];
}

#pragma mark Table view methods

// return how many sections (1!!)
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
  return 1;
}

// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)lclTableView numberOfRowsInSection:(NSInteger)section
{
  return [[self usersArray] count];
}

- (void)reloadRowsAtIndexPaths:(NSArray *)indexPaths withRowAnimation:(UITableViewRowAnimation)animation
{
  for (NSIndexPath *indexPath in indexPaths)
  {
    [self tableView:[self tableView] cellForRowAtIndexPath:indexPath];
  }
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)lclTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{

  NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
  NSString* tmpStr = [[usersArray objectAtIndex:indexPath.row] userNickname];
  UITableViewCell *cell;

  // Selected cells are highlighted
  if([settings integerForKey:@"user_id"] == [[usersArray objectAtIndex:indexPath.row] userId])
  {
    cell = [LWEUITableUtils reuseCellForIdentifier:@"CellHighlighted" onTable:lclTableView usingStyle:UITableViewCellStyleDefault];
    
    CustomCellBackgroundView *bgView = [[CustomCellBackgroundView alloc] initWithFrame:CGRectZero];
    [bgView setCellIndexPath:indexPath tableLength:(NSInteger)[usersArray count]];
    [bgView setBorderColor:[lclTableView separatorColor]];
    [bgView setFillColor:[[ThemeManager sharedThemeManager] currentThemeTintColor]];
    cell.textLabel.backgroundColor = [ UIColor clearColor ];
    cell.textLabel.textColor = [ UIColor whiteColor ];
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

  // Set up the avatar image
//  UIImageView *tmpView = cell.imageView;
//  tmpView.image = [[usersArray objectAtIndex:indexPath.row] getUserThumbnail];
  
  cell.textLabel.text = tmpStr;
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
  self.statusMsgBox = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Activate User",@"UserViewController.ChangeUser_AlertViewTitle")
                                           message:message
                                           delegate:self
                                           cancelButtonTitle:NSLocalizedString(@"Cancel",@"Global.Cancel")
                                           otherButtonTitles:NSLocalizedString(@"OK",@"Global.OK"),nil];
  [statusMsgBox show];
}


- (void) alertView: (UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
  // user activation confirmed 
  if (buttonIndex == 1)
  {
    // Load modal spinner
    loadingView = [LoadingView loadingViewInView:[self view] withText:NSLocalizedString(@"Switching User...",@"UserViewController.SwitchingUserDialog")];
    [self performSelector:@selector(doActivateUser) withObject:nil afterDelay:0.1];
  }
}


- (void)tableView:(UITableView *)lclTableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
  [lclTableView deselectRowAtIndexPath:indexPath animated:NO];
  UserDetailsViewController *userDetailsView = [[UserDetailsViewController alloc] init];
  User* currUser = [[self usersArray] objectAtIndex:(NSInteger)indexPath.row];
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
      NSString* message = [NSString stringWithFormat:NSLocalizedString(@"The default user can be edited but not deleted",@"UserViewController.CannotDelete_AlertViewMessage")];
      self.statusMsgBox = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Cannot Delete User",@"UserViewController.CannotDelete_AlertViewTitle")
                                               message:message
                                               delegate:self
                                               cancelButtonTitle:nil
                                               otherButtonTitles:NSLocalizedString(@"OK",@"Global.OK"),nil];
      [statusMsgBox show];
      return;
    }

    // Delete the row from the data source
    User *tmpUser = [usersArray objectAtIndex:indexPath.row];
    [tmpUser deleteUser];

    // Remove from usersArray
    [usersArray removeObjectAtIndex:indexPath.row];

    // If we just deleted the active user, change to iPhone Owner
    NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
    if(selectedUserId == [settings integerForKey:@"user_id"])
      [[User getUser:DEFAULT_USER_ID] activateUser];

    // Delete from table
    [lclTableView deleteRowsAtIndexPaths:[NSArray arrayWithObjects:indexPath,nil] withRowAnimation:UITableViewRowAnimationRight];

    // Redraw table if needed
    [[self tableView] reloadData];
  }
}

# pragma mark UI Responders

- (void) doActivateUser
{
  // Activate, post notification and dismiss view
  [[self selectedUserInArray] activateUser];
  [[NSNotificationCenter defaultCenter] postNotificationName:@"userWasChanged" object:self];
  [self.loadingView removeView];
  [self.navigationController popViewControllerAnimated:YES];
}

- (void)addUser:sender {
  UserDetailsViewController *userDetailsView = [[UserDetailsViewController alloc] init];
  userDetailsView.title = NSLocalizedString(@"Add User",@"UserDetailsViewController.NavBarTitle");
  userDetailsView.mode = kUserViewModeAdd;
  [self.navigationController pushViewController:userDetailsView animated:YES];
	[userDetailsView release];

/* // I would like to do this, but cannot load an actionSheet from a modal view
  UINavigationController *modalNavController = [[UINavigationController alloc] initWithRootViewController:userDetailsView];
  [[self navigationController] presentModalViewController:modalNavController animated:YES];
  [modalNavController release];
  [userDetailsView release];*/
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self name:@"userSettingsWereChanged" object:nil];
  
  [usersArray release];
  [statusMsgBox release];
  [super dealloc];
}

@end
