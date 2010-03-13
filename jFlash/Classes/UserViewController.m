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

@implementation UserViewController
@synthesize usersArray, statusMsgBox, selectedUserInArray;

- (UserViewController*) init {
	if (self = [super initWithStyle:UITableViewStyleGrouped])
  {
    self.title = @"Choose User";
    self.tableView.delegate = self;
    self.usersArray = [User getUsers];
    [usersArray retain];
  }
  return self;
}

- (void)loadView
{
  [super loadView];
  UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addUser:)];
  self.navigationItem.rightBarButtonItem = addButton;
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadTableData) name:@"userSettingsWereChanged" object:nil];
}

- (void)reloadTableData{
  self.usersArray = [User getUsers];
  [[self tableView] reloadData];
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  self.navigationController.navigationBar.tintColor = [CurrentState getThemeTintColor];
  self.navigationController.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:TABLEVIEW_BACKGROUND_IMAGE]];
  [[self tableView] setSeparatorColor:[UIColor lightGrayColor]];
  [[self tableView] setBackgroundColor: [UIColor clearColor]];
  [[self tableView] reloadData];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
  return YES;
}

#pragma mark Table view methods

// return how many sections (1!!)
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return 1;
}

// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)lclTableView numberOfRowsInSection:(NSInteger)section {
  return [usersArray count];
}

- (void)reloadRowsAtIndexPaths:(NSArray *)indexPaths withRowAnimation:(UITableViewRowAnimation)animation{
  for (NSIndexPath *indexPath in indexPaths) {
    [self tableView:[self tableView] cellForRowAtIndexPath:indexPath];
  }
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)lclTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

  NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
  NSString* tmpStr = [[usersArray objectAtIndex:indexPath.row] userNickname];
  
  NSString *CellIdentifier;
  UITableViewCell *cell;

  // Selected cells are highlighted
  if([settings integerForKey:@"user_id"] == [[usersArray objectAtIndex:indexPath.row] userId]){

    CellIdentifier = @"CellHighlighted";
    cell = [lclTableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) 
    {
      cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
    CustomCellBackgroundView *bgView = [[CustomCellBackgroundView alloc] initWithFrame:CGRectZero];
    [bgView setCellIndexPath:indexPath tableLength:(NSInteger)[usersArray count]];
    [bgView setBorderColor:[lclTableView separatorColor]];
    [bgView setFillColor:[CurrentState getThemeTintColor]];
    cell.textLabel.backgroundColor = [ UIColor clearColor ];
    cell.textLabel.textColor = [ UIColor whiteColor ];
    cell.backgroundView = bgView;
    [bgView release];
  }
  // Unselected cells are white
  else 
  {
    CellIdentifier = @"CellWhite";
    cell = [lclTableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
      cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    cell.textLabel.backgroundColor = [ UIColor clearColor ];
    cell.textLabel.textColor = [ UIColor blackColor ];
    cell.backgroundColor = [ UIColor whiteColor ];
  }

  // Set up the avatar image
  UIImageView *tmpView = cell.imageView;
  tmpView.image = [[usersArray objectAtIndex:indexPath.row] getUserThumbnail];
  
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
  if([selectedUserInArray userId] == [settings integerForKey:@"user_id"]){
    return; 
  }
  [lclTableView deselectRowAtIndexPath:indexPath animated:NO];
  selectedUserInArray = [[self usersArray] objectAtIndex:(NSInteger)indexPath.row];
  NSString* message = [NSString stringWithFormat:@"Set the active user to %@?", [selectedUserInArray userNickname]];
  self.statusMsgBox = [[UIAlertView alloc] initWithTitle:@"Activate User" message:message delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK",nil];
  [statusMsgBox show];
}

- (void) alertView: (UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
  // user activation confirmed 
  if (buttonIndex == 1)
    [self doActivateUser];
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

// Delete row from table
- (void)tableView:(UITableView *)lclTableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
  if (editingStyle == UITableViewCellEditingStyleDelete)
  {
    // Cancel deletion if the user is ID=1
    NSInteger selectedUserId = [[usersArray objectAtIndex:indexPath.row] userId];
    if(selectedUserId == DEFAULT_USER_ID){
      NSString* message = [NSString stringWithFormat:@"The default user can be edited but not deleted"];
      self.statusMsgBox = [[UIAlertView alloc] initWithTitle:@"Cannot Delete User" message:message delegate:self cancelButtonTitle:nil otherButtonTitles:@"OK",nil];
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
  [self.navigationController popViewControllerAnimated:YES];
}

- (void)addUser:sender {
  UserDetailsViewController *userDetailsView = [[UserDetailsViewController alloc] init];
  userDetailsView.title = @"Add User";
  userDetailsView.mode = kUserViewModeAdd;
  [self.navigationController pushViewController:userDetailsView animated:YES];
	[userDetailsView release];

/* // I would like to do this, but cannot load an actionSheet from a modal view
  UINavigationController *modalNavController = [[UINavigationController alloc] initWithRootViewController:userDetailsView];
  [[self navigationController] presentModalViewController:modalNavController animated:YES];
  [modalNavController release];
  [userDetailsView release];*/
}

- (void)dealloc {
  [usersArray release];
  [statusMsgBox release];
  [super dealloc];
}

@end
