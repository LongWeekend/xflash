//
//  StudySetViewController.m
//  jFlash
//
//  Created by Paul Chapman on 6/26/09.
//  Copyright 2009 LONG WEEKEND INC. All rights reserved.
//

#import "StudySetViewController.h"
#import "StudySetWordsViewController.h"
#import "AddStudySetInputViewController.h"
#import "CustomCellBackgroundView.h"
#import "LWEJanrainLoginManager.h"

#import "SettingsViewController.h"

NSInteger const kBackupConfirmationAlertTag = 10;
NSInteger const kRestoreConfirmationAlertTag = 11;

NSString * const LWEActiveTagDidChange = @"LWEActiveTagDidChange";

@implementation StudySetViewController
@synthesize subgroupArray,tagArray,selectedTagId,group,groupId,activityIndicator,searchBar,backupManager;

enum Sections {
  kGroupsSection = 0,
  kSetsSection = 1,
  kBackupSection = 2
};


/** 
 * Customized initializer - returns UITableView group as self.view
 * Also creates tab bar image and sets nav bar title
 */
- (id) init
{
  self = [super initWithStyle:UITableViewStyleGrouped];
  if (self)
  {
    // Set the tab bar controller image png to the targets
    self.tabBarItem.image = [UIImage imageNamed:@"15-tags.png"];
    self.title = NSLocalizedString(@"Study Sets",@"StudySetViewController.NavBarTitle");
    searching = NO;
    BackupManager *bm = [[BackupManager alloc] initWithDelegate:self];
    self.backupManager = bm;
    [bm release];
    selectedTagId = -1;
  }
  return self;
}

/**
 * Loads view
 * Programmatically adds search bar into table header view
 * Registers observers to reload data in case of external changes
 * Sets up group & tag information
 * Programmatically creates activity indicator
 */
- (void) loadView
{
  [super loadView];
  
  // Add the search bar
  UISearchBar *tmpSearchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0,0,320,45)];
  tmpSearchBar.delegate = self;
  tmpSearchBar.autocorrectionType = UITextAutocorrectionTypeNo;
  tmpSearchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
  self.searchBar = tmpSearchBar;
  self.tableView.tableHeaderView = tmpSearchBar;
  [tmpSearchBar release];
  
  // Add add button to nav bar
  _addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addStudySet)];
  self.navigationItem.rightBarButtonItem = _addButton;
  
  // Register observers to reload table data on other events
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadTableData) name:@"setAddedToView" object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadTableData) name:LWECardSettingsChanged object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadTableData) name:LWETagContentDidChange object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changeStudySetFromWordList:) name:@"setWasChangedFromWordsList" object:nil];
  
  // Get this group & subgroup data, and finally tags
  self.group = [GroupPeer retrieveGroupById:self.groupId];
  [self reloadSubgroupData];
  
  self.tagArray = [[[self.group childTags] mutableCopy] autorelease];
  
  // Activity indicator
  UIActivityIndicatorView *tmpIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
  [self setActivityIndicator:tmpIndicator];
  [tmpIndicator release];
}

- (void) viewWillAppear: (BOOL)animated
{
  [super viewWillAppear:animated];
  self.title = NSLocalizedString(@"Study Sets",@"StudySetViewController.NavBarTitle");
  self.navigationController.navigationBar.tintColor = [[ThemeManager sharedThemeManager] currentThemeTintColor];
  // TODO: iPad customization?
  self.navigationController.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:TABLEVIEW_BACKGROUND_IMAGE]];
  self.searchBar.tintColor = [[ThemeManager sharedThemeManager] currentThemeTintColor];
  self.searchBar.placeholder = NSLocalizedString(@"Search Sets By Name",@"StudySetViewController.SearchPlaceholder");
  if (!searching)
  {
    [self hideSearchBar];
  }
  [self.tableView setBackgroundColor:[UIColor clearColor]];
  [self reloadTableData];
}

- (void) reloadSubgroupData
{
  // Get subgroups
  self.subgroupArray = [GroupPeer retrieveGroupsByOwner:group.groupId];
  for (int i = 0; i < [self.subgroupArray count]; i++)
  {
    [[self.subgroupArray objectAtIndex:i] childGroupCount];
  }
}

- (void) reloadTableData
{
	if (searching)
  {
    self.tagArray = [[[TagPeer retrieveTagListLike:self.searchBar.text] mutableCopy] autorelease];
  }
  else
  {
    self.tagArray = [[[self.group childTags] mutableCopy] autorelease];
    
    // Do something special for starred words - re-sort so starred shows up on top.
    if (self.group.groupId == 0)
    {
      NSMutableArray *tmpTagArray = [NSMutableArray array];
      for (Tag *tmpTag in self.tagArray)
      {
        if (tmpTag.tagId == FAVORITES_TAG_ID)
        {
          // Put it at the beginning
          [tmpTagArray insertObject:tmpTag atIndex:0];
        }
        else
        {
          [tmpTagArray addObject:tmpTag];
        }
      }
      self.tagArray = tmpTagArray;
    }
  }
  [self.tableView reloadData];
}

/**
 * Slides the search bar off of the visible space by setting the content offset of the table view
 */
- (void) hideSearchBar
{
  self.tableView.contentOffset = CGPointMake(0, self.searchBar.frame.size.height);
}

/** Convenience method to change set using notification from another place */
- (void) changeStudySetFromWordList:(NSNotification*)notification
{
  [self changeStudySet:[notification.userInfo objectForKey:@"tag"]];
}

/**
 * Changes the user's active study set
 * \param tag Is a Tag object pointing to the tag to begin studying
 */
- (void) changeStudySet:(Tag*) tag
{
  CurrentState *appSettings = [CurrentState sharedCurrentState];
  [appSettings setActiveTag:tag];
  
  // Tell StudyViewController to reload its data
  [[NSNotificationCenter defaultCenter] postNotificationName:LWEActiveTagDidChange object:self];

  // Post notification to switch active tab
  [[NSNotificationCenter defaultCenter] postNotificationName:@"switchToStudyView" object:self];
  
  // Stop the animator
  selectedTagId = -1;
  [self.activityIndicator stopAnimating];
  [self.tableView reloadData];
}

/** Pops up AddStudySetInputViewController modal to create a new set */
- (void) addStudySet
{
  // TODO: iPad customization?
  AddStudySetInputViewController *tmpVC = [[AddStudySetInputViewController alloc] initWithNibName:@"ModalInputView" bundle:nil];
  tmpVC.ownerId = self.groupId;
  tmpVC.title = NSLocalizedString(@"Create Study Set",@"AddStudySetInputViewController.NavBarTitle");
  UINavigationController *modalNavController = [[UINavigationController alloc] initWithRootViewController:tmpVC];
  [self.navigationController presentModalViewController:modalNavController animated:YES];
  [modalNavController release];
	[tmpVC release];
}

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
  [self dismissModalViewControllerAnimated:YES];
}

#pragma mark - UITableView methods

/**
 * Allows user to delete the selected tag
 * Note that this does not accept responsibility for IF the tag SHOULD be deleted
 */ 
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
  if (editingStyle == UITableViewCellEditingStyleDelete)
  {
    // Delete the row from the data source
    Tag *tmpTag = [self.tagArray objectAtIndex:indexPath.row];
    [TagPeer deleteTag:tmpTag];
    [self.tagArray removeObjectAtIndex:indexPath.row];
    [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:YES];
    [self reloadSubgroupData];
  }
}

/**
 * If we are searching, there is only one section (returns 1)
 * If we are not searching, there are groups & tags (returns 2)
 */
- (NSInteger)numberOfSectionsInTableView:(UITableView *)lclTableView
{
	if (searching)
  {
		return 1;
  }
  else
  {
    if (self.groupId == 0)
    {
      return 3; // only show the 3rd section if we are at the top of the stack
    }
    return 2;
  }
}


-(NSString*) tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section
{
  if (section == kBackupSection)
  {
    return NSLocalizedString(@"Backup Custom Sets",@"StudySetVC.BackupCustomSetsTitle");
  }
  else
  {
    return nil;
  }
}


/**
 * If searching, returns the number of search results.  If no results, returns 1 (no results cell)
 * If not searching, returns number of tags or groups, depending on section
 */
- (NSInteger)tableView:(UITableView *)lclTableView numberOfRowsInSection:(NSInteger)section
{
	if (searching)
  {
    if ([self.tagArray count] > 0)
    {
      return [self.tagArray count];
    }
    else
    {
      return 1; // show no results message
    }
  }
  else
  {
    if (section == kSetsSection)
    {
      return [self.tagArray count];
    }
    else if(section == kBackupSection)
    {
      if ([[LWEJanrainLoginManager sharedLWEJanrainLoginManager] isAuthenticated])
      {
        return 3;
      }
      return 2;
    }
    else
    {
      return [self.subgroupArray count];
    }
  }
}


/**
 * Generates cells for table view depending on section & whether or not we are searching
 */
- (UITableViewCell *)tableView:(UITableView *)lclTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  UITableViewCell *cell = nil;
  // Get theme manager so we can get elements from it
  ThemeManager *tm = [ThemeManager sharedThemeManager];

  // Study Set Cells (ie. a tag)
  if (indexPath.section == kSetsSection || searching)
  {
    
    // No search results msg
    if (searching && [self.tagArray count] == 0)
    {
      cell = [LWEUITableUtils reuseCellForIdentifier:@"result" onTable:lclTableView usingStyle:UITableViewCellStyleSubtitle];
      cell.accessoryType = UITableViewCellAccessoryNone;
      cell.detailTextLabel.font = [UIFont boldSystemFontOfSize:12];    
      cell.selectionStyle = UITableViewCellSelectionStyleGray;
      cell.textLabel.text = NSLocalizedString(@"No Results Found",@"StudySetViewController.SearchedButNoResults");
      cell.detailTextLabel.lineBreakMode = UILineBreakModeWordWrap;
    }
    // Normal cell display
    else
    {
      cell = [LWEUITableUtils reuseCellForIdentifier:@"normal" onTable:lclTableView usingStyle:UITableViewCellStyleSubtitle];

      Tag* tmpTag = [self.tagArray objectAtIndex:indexPath.row];

      // Set up the image
      // TODO: iPad customization?
      UIImageView* tmpView = cell.imageView;
      if (tmpTag.tagId == FAVORITES_TAG_ID)
      {
        tmpView.image = [UIImage imageNamed:[tm elementWithCurrentTheme:@"tag-starred-icon.png"]];
      }
      else
      {
        tmpView.image = [UIImage imageNamed:[tm elementWithCurrentTheme:@"tag-icon.png"]];
      }
      
      cell.textLabel.text = tmpTag.tagName;
      cell.selectionStyle = UITableViewCellSelectionStyleNone;
      NSString* tmpDetailText = [NSString stringWithFormat:NSLocalizedString(@"%d Words",@"StudySetViewController.WordCount"), [tmpTag cardCount]];
      cell.detailTextLabel.font = [UIFont boldSystemFontOfSize:12];
      cell.detailTextLabel.text = tmpDetailText;
      if (tmpTag.cardCount == 0)
      {
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.accessoryView = nil;
      }
      else
      {
        cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
        cell.accessoryView = nil;
      }
      if (selectedTagId == indexPath.row)
      {
        cell.accessoryView = self.activityIndicator;
        cell.detailTextLabel.text = NSLocalizedString(@"Loading cards...",@"StudySetViewController.LoadingCards");
      }
    }
  }
  else if (indexPath.section == kBackupSection)
  {
    cell = [LWEUITableUtils reuseCellForIdentifier:@"backup" onTable:lclTableView usingStyle:UITableViewCellStyleDefault];
    if (indexPath.row == 0)
    {
      cell.textLabel.text = NSLocalizedString(@"Backup Now", @"StudyViewController.backupUserSets");
    }
    else if (indexPath.row == 1)
    {
      cell.textLabel.text = NSLocalizedString(@"Restore Now", @"StudyViewController.backupUserSets");
    }
    else
    {
      if ([[LWEJanrainLoginManager sharedLWEJanrainLoginManager] isAuthenticated])
      {
        cell.textLabel.text = NSLocalizedString(@"Logout", @"StudyViewController.backupUserSets");
      }
    }
  }
  // Group Cells
  else
  {
    cell = [LWEUITableUtils reuseCellForIdentifier:@"group" onTable:lclTableView usingStyle:UITableViewCellStyleSubtitle];
    
    // Folders should display the theme color when pressed!
    CustomCellBackgroundView *bgView = [[CustomCellBackgroundView alloc] initWithFrame:CGRectZero];
    [bgView setCellIndexPath:indexPath tableLength:[self.subgroupArray count]];
    [bgView setBorderColor:[self.tableView separatorColor]];
    [bgView setFillColor:[[ThemeManager sharedThemeManager] currentThemeTintColor]];
    cell.selectedBackgroundView = bgView;
    [bgView release];
    
    // This is for groups?
    Group* tmpGroup = [self.subgroupArray objectAtIndex:indexPath.row];
    cell.textLabel.text = tmpGroup.groupName;
    cell.selectionStyle = UITableViewCellSelectionStyleGray;
    NSString* tmpDetailText = [NSString stringWithFormat:@""];
    if ([tmpGroup childGroupCount] > 0)
    {
      //Prefix the line below with code if we have groups
      tmpDetailText = [NSString stringWithFormat:NSLocalizedString(@"%d Groups; ",@"StudySetViewController.GroupCount"),[tmpGroup childGroupCount]]; 
    }
    tmpDetailText = [NSString stringWithFormat:NSLocalizedString(@"%@%d Sets",@"StudySetViewController.TagCount"),tmpDetailText,tmpGroup.tagCount];

    // Set up the image
    UIImageView* tmpView = (UIImageView*)cell.imageView;
    // TODO: iPad customization?
    if(tmpGroup.recommended)
    {
      tmpView.image = [UIImage imageNamed:[tm elementWithCurrentTheme:@"special-folder-icon.png"]];
    }
    else
    {
      tmpView.image = [UIImage imageNamed:[tm elementWithCurrentTheme:@"folder-icon.png"]];
    }
    
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.detailTextLabel.font = [UIFont boldSystemFontOfSize:12];
    cell.detailTextLabel.text = tmpDetailText;
  }
  return cell;
}


/** UI Table View delegate - when a user selects a cell, either start that set, or navigate to the group (if a group) */
- (void)tableView:(UITableView *)lclTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  if (indexPath.section == kSetsSection || searching)
  {
    if([tagArray count] > 0)
    {
      int numCards = [[self.tagArray objectAtIndex:indexPath.row] cardCount];
      if(numCards > 0)
      {
        self.selectedTagId = indexPath.row;
        NSString *tagName = [[self.tagArray objectAtIndex:indexPath.row] tagName];
        [LWEUIAlertView confirmationAlertWithTitle:tagName
                                           message:NSLocalizedString(@"Do you want to start this set?  Progress on your last set will be saved.",@"StudySetViewController.StartStudy_AlertViewMessage")
                                          delegate:self];
      }
      else
      {
        [LWEUIAlertView notificationAlertWithTitle:NSLocalizedString(@"No Words In Set",@"StudySetViewController.NoWords_AlertViewTitle")
                                           message:NSLocalizedString(@"To add words to this set, you can use Search.",@"StudySetViewController.NoWords_AlertViewMessage")];
      }
    }
    else
    {
      // deselect "no results" msg
      [lclTableView deselectRowAtIndexPath:indexPath animated:NO];    
    }
  }
  else if (indexPath.section == kBackupSection)
  {
    if (indexPath.row == 0)
    {
      [LWEUIAlertView confirmationAlertWithTitle:NSLocalizedString(@"Backup Custom Sets", @"StudySetViewController")
                                         message:NSLocalizedString(@"We will now backup your custom sets. This will overwrite any backup that may already be stored.", @"StudySetViewController")
                                              ok:NSLocalizedString(@"Backup!", @"StudySetViewController") 
                                          cancel:NSLocalizedString(@"No Thanks.", @"StudySetViewController") 
                                        delegate:self 
                                             tag:kBackupConfirmationAlertTag];
    }
    else if (indexPath.row == 1)
    {
      [LWEUIAlertView confirmationAlertWithTitle:NSLocalizedString(@"Restore Custom Sets", @"StudySetViewController")
                                         message:NSLocalizedString(@"We will now restore your custom sets from our server. This will add words and sets not already found, but will NOT remove any words or sets on this device.", @"StudySetViewController")
                                              ok:NSLocalizedString(@"Restore!" , @"StudySetViewController")
                                          cancel:NSLocalizedString(@"Maybe later." , @"StudySetViewController")
                                        delegate:self 
                                             tag:kRestoreConfirmationAlertTag];
    }
    else if (indexPath.row == 2)
    {
      [[LWEJanrainLoginManager sharedLWEJanrainLoginManager] logout];
    }
    
    [lclTableView deselectRowAtIndexPath:indexPath animated:NO];
    [self reloadTableData];
  }
  else
  {
    [lclTableView deselectRowAtIndexPath:indexPath animated:NO];

    // If they selected a group
    StudySetViewController *subgroupController = [[StudySetViewController alloc] init];
    subgroupController.groupId = [[self.subgroupArray objectAtIndex:indexPath.row] groupId];
    [self.navigationController pushViewController:subgroupController animated:YES];
    [subgroupController release];
  }
}


/**
 * If tag section OR in searching mode (where it becomes another section)
 * Show the study set words view controller for that tag
 */
- (void)tableView:(UITableView *)lclTableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
  if (indexPath.section == kSetsSection || searching)
  {
    [lclTableView deselectRowAtIndexPath:indexPath animated:NO];
    Tag* tmpTag = [[self tagArray] objectAtIndex:indexPath.row];
    StudySetWordsViewController *wordsController = [[StudySetWordsViewController alloc] initWithTag:tmpTag]; 
    [self.navigationController pushViewController:wordsController animated:YES];
    [wordsController release];
  }
}


/**
 * If the tag's "tagEditable" flag is set to 1, return YES
 * Returns NO in any case if the tag is the active tag
 * Always returns NO for groups
 */
- (BOOL)tableView:(UITableView *)lclTableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
  // Only can edit tags, and user tags at that
  if (indexPath.section == kSetsSection)
  {
    CurrentState *state = [CurrentState sharedCurrentState];
    Tag* tmpTag = [tagArray objectAtIndex:indexPath.row];
    if ([tmpTag tagEditable] && ([[state activeTag] tagId] != [tmpTag tagId]))
    {
      return YES;
    }
  }
  return NO;
}

#pragma mark -
#pragma mark Alert View Delegate

/** Alert view delegate - initiates the "study set change" if they pressed OK */
- (void) alertView: (UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
  // This is the OK button
  if (buttonIndex == LWE_ALERT_OK_BTN)
  {
    if (alertView.tag == kBackupConfirmationAlertTag)
    {
      [[self activityIndicator] startAnimating];
      [self.backupManager performSelector:@selector(backupUserData) withObject:nil afterDelay:.3]; // need to give this method a chance to finish or the modal doesn't work
    }
    else if (alertView.tag == kRestoreConfirmationAlertTag)
    {
      [[self activityIndicator] startAnimating];
      [self.backupManager performSelector:@selector(restoreUserData) withObject:nil afterDelay:.3];
    }
    else 
    {
      [[self tableView] reloadData];
      [[self activityIndicator] startAnimating];
      [self performSelector:@selector(changeStudySet:) withObject:[[self tagArray] objectAtIndex:self.selectedTagId] afterDelay:0];
    }
    return;
  }
  else 
  {
    selectedTagId = -1;
  }
}

#pragma mark - BackupManager Delegate

- (void)didBackupUserData
{
  [LWEUIAlertView notificationAlertWithTitle:NSLocalizedString(@"Backup Complete", @"BackupComplete") 
                                     message:NSLocalizedString(@"Your custom sets have been backed up successfully. Enjoy Japanese Flash!", @"BackupManager_DataRestoredBody")]; 
  
  [[self activityIndicator] stopAnimating];
}

- (void)didFailToBackupUserDataWithError:(NSError *)error
{
  NSString* errorMessage = [NSString stringWithFormat:@"Sorry about this! We couldn't back up because: %@", [error localizedDescription]];
  
  // overwrite the default error message if it's from the server
  if ([error domain] == NetworkRequestErrorDomain)
  {
    switch ([error code]) // these should be http codes
    {
      case 503:
        errorMessage = @"The service is temporaily unavailable. Please try again later. Sorry!";
        break;
      case 500:
        errorMessage = @"Something went wrong on the server. We will try to fix it in a jiffy!";
      default:
        break;
    }
  }
  [LWEUIAlertView notificationAlertWithTitle:NSLocalizedString(@"Backup Failed", @"BackupFailed") message:errorMessage];
  [[self activityIndicator] stopAnimating];
}

- (void)didRestoreUserData
{
  [LWEUIAlertView notificationAlertWithTitle:NSLocalizedString(@"Data Restored", @"DataRestored") 
                                     message:NSLocalizedString(@"Your data has been restored successfully. Enjoy Japanese Flash!", @"BackupManager_DataRestoredBody")]; 
  [[self activityIndicator] stopAnimating];
  [self reloadTableData];
}

- (void)didFailToRestoreUserDateWithError:(NSError *)error
{
  if ([error code] == kDataNotFound && [error domain] == LWEBackupManagerErrorDomain)
  {
    [LWEUIAlertView notificationAlertWithTitle:NSLocalizedString(@"No Backup Found", @"DataNotFound") 
                                       message:NSLocalizedString(@"We couldn't find a backup for you! Please login with another account or create a backup first.", @"BackupManager_DataNotFoundBody")];
  }
  else // show the other error (we don't know what this will be)
  {
    [LWEUIAlertView notificationAlertWithTitle:NSLocalizedString(@"Could Not Restore", @"RestoreFailed") 
                                       message:[NSString stringWithFormat:@"Sorry about this! We couldn't restore because: %@", [error localizedDescription]]];
  }
  [[self activityIndicator] stopAnimating];
}

#pragma mark -
#pragma mark Search Bar delegate methods

/**
 * Sets up the controller for searching mode
 * Creates an 50% alpha overlay to hide the study sets when nothing is entered in the 
 * search box
 */
- (void) searchBarTextDidBeginEditing:(UISearchBar *)theSearchBar
{	
	//When the user clicks back from teh detail view
	if (searching) return;
	
  //Add the overlay view.
  if (_searchOverlay == nil)
  {
    _searchOverlay = [[UIView alloc] init];
    searchOverlayBtn = [[UIButton alloc] init];
    [_searchOverlay insertSubview:searchOverlayBtn atIndex:0];
    [searchOverlayBtn addTarget:self action:@selector(doDoneSearching) forControlEvents:UIControlEventTouchDown];
  }

  _searchOverlay.userInteractionEnabled = YES;
	CGFloat yaxis = self.navigationController.navigationBar.frame.size.height;
	CGFloat width = self.view.frame.size.width;
	CGFloat height = self.view.frame.size.height;
  CGRect frame = CGRectMake(0, yaxis, width, height);
	_searchOverlay.frame = frame;	
  searchOverlayBtn.frame = frame;
	_searchOverlay.backgroundColor = [UIColor grayColor];
	_searchOverlay.alpha = 0.5;
	[self.tableView insertSubview:_searchOverlay aboveSubview:self.parentViewController.view];
	
	searching = YES;
  self.tagArray = [[[TagPeer retrieveTagListLike:self.searchBar.text] mutableCopy] autorelease];
  self.tableView.scrollEnabled = NO;
	
	//Add the done button.
	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doDoneSearching)] autorelease];
}


/**
 * Run search if the user typed something into the search bar
 */
- (void)searchBar:(UISearchBar *)theSearchBar textDidChange:(NSString *)searchText
{
	// Remove all objects first.
  [self.tagArray removeAllObjects];
	
	if([searchText length] > 0)
  {
    [_searchOverlay removeFromSuperview];
		searching = YES;
    self.tableView.scrollEnabled = YES;
	}
	else
  {
		[self.tableView insertSubview:_searchOverlay aboveSubview:self.parentViewController.view];
		searching = NO;
    self.tableView.scrollEnabled = NO;
	}
  [self reloadTableData];
}

// Called when the user finally presses "Search" on the keyboard
- (void) searchBarSearchButtonClicked:(UISearchBar *)theSearchBar
{
  self.tagArray = [[[TagPeer retrieveTagListLike:self.searchBar.text] mutableCopy] autorelease];
  [self.searchBar resignFirstResponder];
}

/** 
 * Cleanup after searching finished
 * Hides keyboard, nulls out searchBar text, and re-adds add button to nav bar
 */
- (void) doDoneSearching
{
	self.searchBar.text = @"";
	[self.searchBar resignFirstResponder];
	searching = NO;
  
  self.tableView.scrollEnabled = YES;

  // Replace the done button w/ the add button again
	self.navigationItem.rightBarButtonItem = _addButton;
  [self hideSearchBar];
  [self reloadTableData];
  
  // Kill search overlay
  [_searchOverlay removeFromSuperview];
	[_searchOverlay release];
	_searchOverlay = nil;
}

- (void)viewDidUnload
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];  
  [super viewDidUnload];
}

//! Standard dealloc, removes observers
- (void)dealloc
{
  [_addButton release];
  [tagArray release];
  [subgroupArray release];
  [group release];
  [activityIndicator release];
  [searchBar release];
  [backupManager release];
  [super dealloc];
}

@end