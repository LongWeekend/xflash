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
#import "Constants.h"

NSInteger const kBackupConfirmationAlertTag = 10;
NSInteger const kRestoreConfirmationAlertTag = 11;
NSInteger const kLWEGroupsSection = 0;
NSInteger const kLWETagsSection = 1;
NSInteger const kLWEBackupSection = 2;

@implementation StudySetViewController
@synthesize subgroupArray,tagArray,selectedTagId,group,activityIndicator,searchBar,backupManager,activityView;
/** 
 * Customized initializer - returns UITableView group as self.view
 * Also creates tab bar image and sets nav bar title
 */

- (id) initWithCoder:(NSCoder *)aDecoder
{
  self = [super initWithCoder:aDecoder];
  if (self)
  {
    self.selectedTagId = kLWEUninitializedTagId;
    // This cast is necessary to prevent a stupid compiler warning about not knowing which -initWithDelegate to call
    self.backupManager = [[(BackupManager*)[BackupManager alloc] initWithDelegate:self] autorelease];
  }
  return self;
}

- (id) initWithGroup:(Group*)aGroup
{
  self = [self initWithNibName:@"StudySetView" bundle:nil];
  if (self)
  {
    self.selectedTagId = kLWEUninitializedTagId;
    self.group = aGroup;
    self.title = aGroup.groupName;
  }
  return self;
}

- (void) viewDidLoad
{
  [super viewDidLoad];
  if (self.group == nil)
  {
    self.group = [GroupPeer topLevelGroup];
  }
  
  [self reloadSubgroupData];
  
  // Add add button to nav bar
  _addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addStudySet:)];
  self.navigationItem.rightBarButtonItem = _addButton;
  
  // Register observers to reload table data on other events
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadTableData) name:kSetWasAddedOrUpdated object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadTableData) name:LWETagContentDidChange object:nil];
  [[NSNotificationCenter defaultCenter] addObserverForName:LWEJanrainLoginManagerUserDidNotAuthenticate object:nil queue:nil usingBlock:^(NSNotification *notif) { [DSBezelActivityView removeView]; }];

  NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
  [settings addObserver:self forKeyPath:APP_HEADWORD_TYPE options:NSKeyValueObservingOptionNew context:NULL];
  
  self.tagArray = [[self.group.childTags mutableCopy] autorelease];
  self.activityIndicator = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray] autorelease];
}

- (void) viewWillAppear: (BOOL)animated
{
  [super viewWillAppear:animated];
  self.navigationController.navigationBar.tintColor = [[ThemeManager sharedThemeManager] currentThemeTintColor];
  // TODO: iPad customization?
  self.tableView.backgroundView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:LWETableBackgroundImage]] autorelease];
  
  //  self.navigationController.view.backgroundColor = [UIColor colorWithPatternImage:];
  self.searchBar.tintColor = [[ThemeManager sharedThemeManager] currentThemeTintColor];
  self.searchBar.placeholder = NSLocalizedString(@"Search Sets By Name",@"StudySetViewController.SearchPlaceholder");
  if (searching == NO)
  {
    [self hideSearchBar];
  }
  [self reloadTableData];
}

#pragma mark - KVO

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
  if ([keyPath isEqualToString:APP_HEADWORD_TYPE])
  {
    [self reloadTableData];
  }
  else
  {
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
  }
}

#pragma mark -

- (void) reloadSubgroupData
{
  // Get subgroups
  self.subgroupArray = [GroupPeer retrieveGroupsByOwner:self.group.groupId];
  for (Group *subGroup in self.subgroupArray)
  {
    [subGroup childGroupCount];
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
    if ([self.group isTopLevelGroup])
    {
      NSMutableArray *tmpTagArray = [NSMutableArray array];
      Tag *starredTag = [Tag starredWordsTag];
      for (Tag *tmpTag in self.tagArray)
      {
        if ([tmpTag isEqual:starredTag])
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

/**
 * Changes the user's active study set
 * \param tag Is a Tag object pointing to the tag to begin studying
 */
- (void) activateTag:(Tag*) tag
{
  CurrentState *appSettings = [CurrentState sharedCurrentState];
  [appSettings setActiveTag:tag];
  
  // Tell the tab bar to switch to the SVC
  NSNumber *index = [NSNumber numberWithInt:STUDY_VIEW_CONTROLLER_TAB_INDEX];
  NSDictionary *userInfo = [NSDictionary dictionaryWithObject:index forKey:@"index"];
  [[NSNotificationCenter defaultCenter] postNotificationName:LWEShouldSwitchTab object:nil userInfo:userInfo];
  
  // Stop the animator
  self.selectedTagId = kLWEUninitializedTagId;
  [self.activityIndicator stopAnimating];
  [self.tableView reloadData];
}

/** Pops up AddStudySetInputViewController modal to create a new set */
- (IBAction)addStudySet:(id)sender
{
  // TODO: iPad customization?
  AddStudySetInputViewController *tmpVC = [[AddStudySetInputViewController alloc] initWithDefaultCard:nil inGroup:self.group];
  UINavigationController *modalNavController = [[UINavigationController alloc] initWithRootViewController:tmpVC];
  [self.navigationController presentModalViewController:modalNavController animated:YES];
  [modalNavController release];
	[tmpVC release];
}


#pragma mark - UITableViewDataSource Methods

/**
 * If we are searching, there is only one section (returns 1)
 * If we are not searching, there are groups & tags (returns 2)
 * In either case, if we are at the "top of the stack", show 3 (including backup/restore)
 */
- (NSInteger)numberOfSectionsInTableView:(UITableView *)lclTableView
{
	if (searching)
  {
    // Tags only
		return 1;
  }
  else if ([self.group isTopLevelGroup])
  {
    // Groups + Tags + Backup
    return 3;
  }
  else
  {
    // Groups + Tags
    return 2;
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
    if (section == kLWETagsSection)
    {
      return [self.tagArray count];
    }
    else if (section == kLWEBackupSection)
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
  if (indexPath.section == kLWETagsSection || searching)
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
      
      Tag *tmpTag = [self.tagArray objectAtIndex:indexPath.row];
      
      // Set up the image
      // TODO: iPad customization?
      UIImageView *tmpView = cell.imageView;
      if (tmpTag.tagId == STARRED_TAG_ID)
      {
        tmpView.image = [UIImage imageNamed:[tm elementWithCurrentTheme:@"tag-starred-icon.png"]];
      }
      else
      {
        tmpView.image = [UIImage imageNamed:[tm elementWithCurrentTheme:@"tag-icon.png"]];
      }
      
      cell.textLabel.text = tmpTag.tagName;
      cell.selectionStyle = UITableViewCellSelectionStyleNone;
      NSString *tmpDetailText = [NSString stringWithFormat:NSLocalizedString(@"%d Words",@"StudySetViewController.WordCount"), [tmpTag cardCount]];
      cell.detailTextLabel.font = [UIFont boldSystemFontOfSize:12];
      cell.detailTextLabel.text = tmpDetailText;
      cell.accessoryView = nil;
      if (tmpTag.cardCount == 0)
      {
        cell.accessoryType = UITableViewCellAccessoryNone;
      }
      else
      {
        cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
      }
      
      // Special behavior if we are loading the set
      if (self.selectedTagId == indexPath.row)
      {
        cell.accessoryView = self.activityIndicator;
        cell.detailTextLabel.text = NSLocalizedString(@"Loading cards...",@"StudySetViewController.LoadingCards");
      }
    }
  }
  else if (indexPath.section == kLWEBackupSection)
  {
    cell = [LWEUITableUtils reuseCellForIdentifier:@"backup" onTable:lclTableView usingStyle:UITableViewCellStyleDefault];
    if (indexPath.row == 0)
    {
      cell.textLabel.text = NSLocalizedString(@"Backup Now", @"StudyViewController.backupUserSets");
    }
    else if (indexPath.row == 1)
    {
      cell.textLabel.text = NSLocalizedString(@"Restore Now", @"StudyViewController.restoreUserSets");
    }
    else
    {
      if ([[LWEJanrainLoginManager sharedLWEJanrainLoginManager] isAuthenticated])
      {
        cell.textLabel.text = NSLocalizedString(@"Logout", @"StudyViewController.backupLogot");
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
    Group *tmpGroup = [self.subgroupArray objectAtIndex:indexPath.row];
    cell.textLabel.text = tmpGroup.groupName;
    cell.selectionStyle = UITableViewCellSelectionStyleGray;

    NSMutableArray *descItems = [NSMutableArray arrayWithCapacity:2];
    if (tmpGroup.childGroupCount > 0)
    {
      [descItems addObject:[NSString stringWithFormat:NSLocalizedString(@"%d Groups",@"StudySetViewController.GroupCount"),tmpGroup.childGroupCount]]; 
    }
    if (tmpGroup.tagCount > 0)  // note that this is *not* else if, these are additive
    {
      [descItems addObject:[NSString stringWithFormat:NSLocalizedString(@"%d Sets",@"StudySetViewController.TagCount"),tmpGroup.tagCount]];
    }
    NSString *tmpDetailText = [descItems componentsJoinedByString:@"; "];
    
    // Set up the image
    UIImageView *tmpView = (UIImageView*)cell.imageView;
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

#pragma mark - UITableViewDelegate Methods

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

-(NSString*) tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section
{
  if (section == kLWEBackupSection && [self.group isTopLevelGroup])
  {
    return NSLocalizedString(@"Backup Custom Sets",@"StudySetVC.BackupCustomSetsTitle");
  }
  else
  {
    return nil;
  }
}

/*- (UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
  // No group description if we are at the top level or searching
  if ([self.group isTopLevelGroup] || searching || section != kLWEGroupsSection)
  {
    return nil;
  }
  
  CGFloat topPadding = 5.0f;
  CGRect rect = CGRectMake(8, topPadding, 304, 50);
  UILabel *groupDescription = [[[UILabel alloc] initWithFrame:rect] autorelease];
  groupDescription.text = self.group.groupDescription;
  groupDescription.font = [UIFont systemFontOfSize:14.0f];
  groupDescription.backgroundColor = [UIColor colorWithRed:0.95f green:0.95f blue:0.95f alpha:1.0f];
  groupDescription.numberOfLines = 0;
  groupDescription.lineBreakMode = UILineBreakModeWordWrap;
  groupDescription.layer.borderWidth = 1.0f;
  groupDescription.layer.cornerRadius = 7.0f;
  groupDescription.layer.borderColor = [[UIColor lightGrayColor] CGColor];
  
  CGRect labelRect = [LWEUILabelUtils makeFrameForText:self.group.groupDescription fontSize:12 cellWidth:320 cellMargin:10];
  CGRect viewRect = CGRectMake(0, 0, 320, labelRect.size.height + (topPadding * 2));
  UIView *holdingView = [[UIView alloc] initWithFrame:viewRect];
  [holdingView addSubview:groupDescription];
  return [holdingView autorelease];
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
  if ([self.group isTopLevelGroup] == NO && section == kLWEGroupsSection)
  {
    CGRect labelRect = [LWEUILabelUtils makeFrameForText:self.group.groupDescription fontSize:12 cellWidth:320 cellMargin:10];
    return labelRect.size.height + 10;
  }
  else
  {
    return 44.0f;
  }
}*/

/** UI Table View delegate - when a user selects a cell, either start that set, or navigate to the group (if a group) */
- (void)tableView:(UITableView *)lclTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  if (indexPath.section == kLWETagsSection || searching)
  {
    if ([self.tagArray count] > 0)
    {
      NSInteger numCards = [[self.tagArray objectAtIndex:indexPath.row] cardCount];
      if (numCards > 0)
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
  else if (indexPath.section == kLWEBackupSection)
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
    Group *childGroup = [self.subgroupArray objectAtIndex:indexPath.row];
    StudySetViewController *subgroupController = [[StudySetViewController alloc] initWithGroup:childGroup];
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
  [lclTableView deselectRowAtIndexPath:indexPath animated:NO];
  if (indexPath.section == kLWETagsSection || searching)
  {
    Tag *tmpTag = [self.tagArray objectAtIndex:indexPath.row];
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
  if (indexPath.section == kLWETagsSection)
  {
    Tag *activeTag = [[CurrentState sharedCurrentState] activeTag];
    Tag *tmpTag = [self.tagArray objectAtIndex:indexPath.row];
    if (tmpTag.isEditable && ([tmpTag isEqual:activeTag] == NO))
    {
      return YES;
    }
  }
  return NO;
}

#pragma mark - UIAlertViewDelegate Methods

/** Alert view delegate - initiates the "study set change" if they pressed OK */
- (void) alertView: (UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
  // This is the OK button
  if (buttonIndex == LWE_ALERT_OK_BTN)
  {
    [self.activityIndicator startAnimating];
    if (alertView.tag == kBackupConfirmationAlertTag)
    {
      [DSBezelActivityView newActivityViewForView:self.parentViewController.view withLabel:NSLocalizedString(@"Backing Up...", @"StudySetViewController.BackingUp")];
      // need to give this method a chance to finish or the modal doesn't work - Janrain code is ghetto?
      dispatch_async(dispatch_get_main_queue(), ^{ [self.backupManager backupUserData]; });
    }
    else if (alertView.tag == kRestoreConfirmationAlertTag)
    {
      [DSBezelActivityView newActivityViewForView:self.parentViewController.view withLabel:NSLocalizedString(@"Restoring...", @"StudySetViewController.Restoring")];
      // need to give this method a chance to finish or the modal doesn't work - Janrain code is ghetto?
      dispatch_async(dispatch_get_main_queue(), ^{ [self.backupManager restoreUserData]; });
    }
    else 
    {
      // Cache this value and re-set it, the animation messes it up by resetting it to zero
      CGPoint offset = self.tableView.contentOffset;
      
      // We want to reload the selected row because it will now say "loading cards"
      NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.selectedTagId inSection:kLWETagsSection];
      [self.tableView beginUpdates];
      [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
      [self.tableView endUpdates];
      
      // For some unknown reason, the above calls (but not -reloadData) reset the table offset.  We don't want that.
      self.tableView.contentOffset = offset;

      [self performSelector:@selector(activateTag:) withObject:[self.tagArray objectAtIndex:self.selectedTagId] afterDelay:0.1];
      //dispatch_async(dispatch_get_main_queue(), ^{ [self activateTag:[self.tagArray objectAtIndex:self.selectedTagId]]; });
    }
    return;
  }
  else 
  {
    self.selectedTagId = kLWEUninitializedTagId;
  }
}

#pragma mark - BackupManager Delegate

- (void)didBackupUserData
{
  [DSBezelActivityView removeView];  
  NSString *alertMessage = [NSString stringWithFormat:@"%@%@!", NSLocalizedString(@"Your custom sets have been backed up successfully. Enjoy ",@"BackupManager_DataRestoredBody"),BUNDLE_APP_NAME];
  [LWEUIAlertView notificationAlertWithTitle:NSLocalizedString(@"Backup Complete", @"BackupComplete") message:alertMessage];
  [self.activityIndicator stopAnimating];
}

- (void)didFailToBackupUserDataWithError:(NSError *)error
{
  [DSBezelActivityView removeView];
  NSString *errorMessage = [NSString stringWithFormat:@"Sorry about this! We couldn't back up because: %@", [error localizedDescription]];
  
  // overwrite the default error message if it's from the server
  if ([error.domain isEqualToString:NetworkRequestErrorDomain])
  {
    switch (error.code) // these should be http codes
    {
      case 503:
        errorMessage = NSLocalizedString(@"The service is temporaily unavailable. Please try again later. Sorry!", @"StudySetViewController.503error");
        break;
      case 500:
        errorMessage = NSLocalizedString(@"Something went wrong on the server. We will try to fix it in a jiffy!", @"StudySetViewController.500error");
      default:
        break;
    }
  }
  [LWEUIAlertView notificationAlertWithTitle:NSLocalizedString(@"Backup Failed", @"BackupFailed") message:errorMessage];
  [self.activityIndicator stopAnimating];  
}

- (void)didRestoreUserData
{
  [DSBezelActivityView removeView];
  NSString *alertMessage = [NSString stringWithFormat:@"%@%@!", NSLocalizedString(@"Your data has been restored successfully. Enjoy ",@"BackupManager_DataRestoredBody"),BUNDLE_APP_NAME];
  [LWEUIAlertView notificationAlertWithTitle:NSLocalizedString(@"Data Restored", @"DataRestored") message:alertMessage]; 
  [self.activityIndicator stopAnimating];
  [self reloadTableData];
}

- (void)didFailToRestoreUserDateWithError:(NSError *)error
{
  [DSBezelActivityView removeView];
  if (error.code == kDataNotFound && [error.domain isEqualToString:LWEBackupManagerErrorDomain])
  {
    [LWEUIAlertView notificationAlertWithTitle:NSLocalizedString(@"No Backup Found", @"DataNotFound") 
                                       message:NSLocalizedString(@"We couldn't find a backup for you! Please login with another account or create a backup first.", @"BackupManager_DataNotFoundBody")];
  }
  else // show the other error (we don't know what this will be)
  {
    [LWEUIAlertView notificationAlertWithTitle:NSLocalizedString(@"Could Not Restore", @"RestoreFailed") 
                                       message:[NSString stringWithFormat:@"Sorry about this! We couldn't restore because: %@", [error localizedDescription]]];
  }
  [self.activityIndicator stopAnimating];
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
  NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
  [settings removeObserver:self forKeyPath:APP_HEADWORD_TYPE];
  
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
  [activityView release];
  [super dealloc];
}

@end