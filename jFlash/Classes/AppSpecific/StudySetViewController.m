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

@implementation StudySetViewController
@synthesize subgroupArray,tagArray,statusMsgBox,selectedTagId,group,groupId,activityIndicator,searchBar;

/** 
 * Customized initializer - returns UITableView group as self.view
 * Also creates tab bar image and sets nav bar title
 */
- (id) init
{
  if (self = [super initWithStyle:UITableViewStyleGrouped])
  {
    // Set the tab bar controller image png to the targets
    self.tabBarItem.image = [UIImage imageNamed:@"15-tags.png"];
    self.title = NSLocalizedString(@"Study Sets",@"StudySetViewController.NavBarTitle");
    searching = NO;
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
  [self setSearchBar:tmpSearchBar];
  [tmpSearchBar release];
  [[self tableView] setTableHeaderView:[self searchBar]];
  
  // Add add button to nav bar
  _addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addStudySet)];
  self.navigationItem.rightBarButtonItem = _addButton;
  
  // Set this to the master set (main) if no set
  if (self.groupId <= 0) self.groupId = 0;

  // Register observers to reload table data on other events
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadTableData) name:@"setAddedToView" object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadTableData) name:@"settingsWereChanged" object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadTableData) name:@"cardAddedToTag" object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadSubgroupData) name:@"tagDeletedFromGroup" object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changeStudySetFromWordList:) name:@"setWasChangedFromWordsList" object:nil];
  
  // Get this group & subgroup data, and finally tags
  [self setGroup:[GroupPeer retrieveGroupById:self.groupId]];
  [self reloadSubgroupData];
  [self setTagArray:[group getTags]];
  
  // Activity indicator
  UIActivityIndicatorView *tmpIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
  [self setActivityIndicator:tmpIndicator];
  [tmpIndicator release];
}

- (void) viewWillAppear: (BOOL)animated
{
  [super viewWillAppear:animated];
  [self setTitle:[group groupName]];
  self.navigationController.navigationBar.tintColor = [[ThemeManager sharedThemeManager] currentThemeTintColor];
  self.navigationController.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:TABLEVIEW_BACKGROUND_IMAGE]];
  self.searchBar.tintColor = [[ThemeManager sharedThemeManager] currentThemeTintColor];
  self.searchBar.placeholder = NSLocalizedString(@"Search Sets By Name",@"StudySetViewController.SearchPlaceholder");
  if (!searching) [self hideSearchBar];
  [[self tableView] setBackgroundColor: [UIColor clearColor]];
  [self reloadTableData];
}

- (void) reloadSubgroupData
{
  // Get subgroups
  self.subgroupArray = [GroupPeer retrieveGroupsByOwner:group.groupId];
  for (int i = 0; i < [[self subgroupArray] count]; i++)
  {
    [[[self subgroupArray] objectAtIndex:i] getChildGroupCount];
  }
}

- (void) reloadTableData
{
  if([self tableView] == nil)
  {
    return;
  }
	if (searching)
  {
    [self setTagArray: [TagPeer retrieveTagListLike:self.searchBar.text]];
  }
  else
  {
    [self setTagArray: [group getTags]];
  }
  [[self tableView] reloadData];
}

/**
 * Slides the search bar off of the visible space by setting the content offset of the table view
 */
- (void) hideSearchBar
{
  [[self tableView] setContentOffset:CGPointMake(0, self.searchBar.frame.size.height)];
}

/** Convenience method to change set using notification from another place */
- (void) changeStudySetFromWordList:(NSNotification*)dict
{
  [self changeStudySet:[[dict userInfo] objectForKey:@"tag"]];
}

/**
 * Changes the user's active study set
 * \param tag Is a Tag object pointing to the tag to begin studying
 */
- (void) changeStudySet:(Tag*) tag
{
  CurrentState *appSettings = [CurrentState sharedCurrentState];
  [appSettings setActiveTag:tag];
  
  // Post notification to switch active tab
  [[NSNotificationCenter defaultCenter] postNotificationName:@"switchToStudyView" object:self];

  // Tell StudyViewController to reload its data
  [[NSNotificationCenter defaultCenter] postNotificationName:@"setWasChanged" object:self];
  
  // Stop the animator
  [[self activityIndicator] stopAnimating];
  selectedTagId = -1;
  [[self tableView] reloadData];
}

/** Pops up AddStudySetInputViewController modal to create a new set */
- (void)addStudySet
{
  AddStudySetInputViewController* addStudySetInputViewController = [[AddStudySetInputViewController alloc] initWithNibName:@"ModalInputView" bundle:nil];
  addStudySetInputViewController.ownerId = self.groupId;
  addStudySetInputViewController.title = NSLocalizedString(@"Create Study Set",@"AddStudySetInputViewController.NavBarTitle");
  UINavigationController *modalNavController = [[UINavigationController alloc] initWithRootViewController:addStudySetInputViewController];
  [[self navigationController] presentModalViewController:modalNavController animated:YES];
  [modalNavController release];
	[addStudySetInputViewController release];
}



#pragma mark UITableView methods

/** Goes into editing mode **/
- (void)setEditing:(BOOL) editing animated:(BOOL)animated
{
	[super setEditing:editing animated:animated];
	[[self tableView] setEditing:editing animated:YES];
}


/**
 * Allows user to delete the selected tag
 * Note that this does not accept responsibility for IF the tag SHOULD be deleted
 */ 
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
  if (editingStyle == UITableViewCellEditingStyleDelete)
  {
    // Delete the row from the data source
    Tag *tmpTag = [tagArray objectAtIndex:indexPath.row];
    [TagPeer deleteTag:tmpTag.tagId];
    [tagArray removeObjectAtIndex:[indexPath row]];
    [[self tableView] deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:YES];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"tagDeletedFromGroup" object:self];
  }
}


/**
 * If we are searching, there is only one section (returns 1)
 * If we are not searching, there are groups & tags (returns 2)
 */
- (NSInteger)numberOfSectionsInTableView:(UITableView *)lclTableView
{
	if (searching)
		return 1;
  else
    return 2;
}


/**
 * If searching, returns the number of search results.  If no results, returns 1 (no results cell)
 * If not searching, returns number of tags or groups, depending on section
 */
- (NSInteger)tableView:(UITableView *)lclTableView numberOfRowsInSection:(NSInteger)section
{
	if (searching)
  {
    if ([[self tagArray] count] > 0)
      return [[self tagArray] count];
    else
      return 1; // show no results message
  }
  else
  {
    if (section == SECTION_TAG)
      return [[self tagArray] count];
    else
      return [[self subgroupArray] count];
  }
}


/**
 * Generates cells for table view depending on section & whether or not we are searching
 */
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  UITableViewCell *cell = nil;
  // Get theme manager so we can get elements from it
  ThemeManager *tm = [ThemeManager sharedThemeManager];

  // Study Set Cells (ie. a tag)
  if (indexPath.section == SECTION_TAG || searching)
  {
    
    // No search results msg
    if(searching && [tagArray count] == 0)
    {
      cell = [LWEUITableUtils reuseCellForIdentifier:@"result" onTable:[self tableView] usingStyle:UITableViewCellStyleSubtitle];
      cell.accessoryType = UITableViewCellAccessoryNone;
      cell.detailTextLabel.font = [UIFont boldSystemFontOfSize:12];    
      cell.selectionStyle = UITableViewCellSelectionStyleGray;
      cell.textLabel.text = NSLocalizedString(@"No Results Found",@"StudySetViewController.SearchedButNoResults");
      cell.detailTextLabel.lineBreakMode = UILineBreakModeWordWrap;
    }
    // Normal cell display
    else
    {
      cell = [LWEUITableUtils reuseCellForIdentifier:@"normal" onTable:[self tableView] usingStyle:UITableViewCellStyleSubtitle];

      // Set up the image
      UIImageView* tmpView = cell.imageView;
      tmpView.image = [UIImage imageNamed:[tm elementWithCurrentTheme:@"tag-icon.png"]];
      
      Tag* tmpTag = [self.tagArray objectAtIndex:indexPath.row];
      cell.textLabel.text = [tmpTag tagName];
      cell.selectionStyle = UITableViewCellSelectionStyleNone;
      NSString* tmpDetailText = [NSString stringWithFormat:NSLocalizedString(@"%d Words",@"StudySetViewController.WordCount"), [tmpTag cardCount]];
      cell.detailTextLabel.font = [UIFont boldSystemFontOfSize:12];
      cell.detailTextLabel.text = tmpDetailText;
      if(tmpTag.cardCount == 0)
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
        cell.accessoryView = [self activityIndicator];
        cell.detailTextLabel.text = NSLocalizedString(@"Loading cards...",@"StudySetViewController.LoadingCards");
      }
    }
  }
  // Group Cells
  else
  {
    cell = [LWEUITableUtils reuseCellForIdentifier:@"group" onTable:[self tableView] usingStyle:UITableViewCellStyleSubtitle];
    
    // Folders should display the theme color when pressed!
    CustomCellBackgroundView *bgView = [[CustomCellBackgroundView alloc] initWithFrame:CGRectZero];
    [bgView setCellIndexPath:indexPath tableLength:(NSInteger)[subgroupArray count]];
    [bgView setBorderColor:[[self tableView] separatorColor]];
    [bgView setFillColor:[[ThemeManager sharedThemeManager] currentThemeTintColor]];
    cell.selectedBackgroundView = bgView;
    [bgView release];
    
    // This is for groups?
    Group* tmpGroup = [self.subgroupArray objectAtIndex:indexPath.row];
    cell.textLabel.text = tmpGroup.groupName;
    cell.selectionStyle = UITableViewCellSelectionStyleGray;
    NSString* tmpDetailText = [NSString stringWithFormat:@""];
    if ([tmpGroup getChildGroupCount] > 0)
    {
      //Prefix the line below with code if we have groups
      tmpDetailText = [NSString stringWithFormat:NSLocalizedString(@"%d Groups; ",@"StudySetViewController.GroupCount"),[tmpGroup getChildGroupCount]]; 
    }
    tmpDetailText = [NSString stringWithFormat:NSLocalizedString(@"%@%d Sets",@"StudySetViewController.TagCount"),tmpDetailText,tmpGroup.tagCount];

    // Set up the image
    UIImageView* tmpView = (UIImageView*)cell.imageView;
    if(tmpGroup.recommended)
      tmpView.image = [UIImage imageNamed:[tm elementWithCurrentTheme:@"special-folder-icon.png"]];
    else
      tmpView.image = [UIImage imageNamed:[tm elementWithCurrentTheme:@"folder-icon.png"]];
    
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.detailTextLabel.font = [UIFont boldSystemFontOfSize:12];
    cell.detailTextLabel.text = tmpDetailText;
  }
  return cell;
}


/** UI Table View delegate - when a user selects a cell, either start that set, or navigate to the group (if a group) */
- (void)tableView:(UITableView *)lclTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  if (indexPath.section == SECTION_TAG || searching)
  {
    if([tagArray count] > 0)
    {
      int numCards = [[self.tagArray objectAtIndex:indexPath.row] cardCount];
      if(numCards > 0)
      {
        self.selectedTagId = indexPath.row;
        NSString *tag = [[self.tagArray objectAtIndex:indexPath.row] tagName];
        self.statusMsgBox = [[UIAlertView alloc] initWithTitle:tag message:NSLocalizedString(@"Do you want to start this set?  Progress on your last set will be saved.",@"StudySetViewController.StartStudy_AlertViewMessage")
                                                 delegate:self
                                                 cancelButtonTitle:NSLocalizedString(@"Cancel",@"Global.Cancel")
                                                 otherButtonTitles:NSLocalizedString(@"OK",@"Global.OK"),nil];
        [statusMsgBox show];
        [tag release];
      }
      else
      {
        UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"No Words In Set",@"StudySetViewController.NoWords_AlertViewTitle") 
                                                      message:NSLocalizedString(@"To add words to this set, you can use Search.",@"StudySetViewController.NoWords_AlertViewMessage")
                                                      delegate:self
                                                      cancelButtonTitle:NSLocalizedString(@"OK",@"Global.OK") otherButtonTitles:nil];
        [alertView show];
        [alertView release];
      }
    }
    else
    {
      // deselect "no results" msg
      [lclTableView deselectRowAtIndexPath:indexPath animated:NO];    
    }
  }
  else
  {
    // If they selected a group
    StudySetViewController *subgroupController = [[[StudySetViewController alloc] init] autorelease];
    subgroupController.groupId = [[[self subgroupArray] objectAtIndex:indexPath.row] groupId];
    [self.navigationController pushViewController:subgroupController animated:YES];
    [lclTableView deselectRowAtIndexPath:indexPath animated:NO];
  }
}

/** Alert view delegate - initiates the "study set change" if they pressed OK */
- (void) alertView: (UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
  // This is the OK button
  if (buttonIndex == 1)
  {
    [[self tableView] reloadData];
    [[self activityIndicator] startAnimating];
    [self performSelector:@selector(changeStudySet:) withObject:[[self tagArray] objectAtIndex:self.selectedTagId] afterDelay:0];
    return;
  }
  else 
  {
    selectedTagId = -1;
  }
}


/**
 * If tag section OR in searching mode (where it becomes another section)
 * Show the study set words view controller for that tag
 */
- (void)tableView:(UITableView *)lclTableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
  if (indexPath.section == SECTION_TAG || searching)
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
  if (indexPath.section == SECTION_TAG)
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
	[[self tableView] insertSubview:_searchOverlay aboveSubview:self.parentViewController.view];
	
	searching = YES;
  [self setTagArray: [TagPeer retrieveTagListLike:self.searchBar.text]];
  [[self tableView] setScrollEnabled:NO];
	
	//Add the done button.
	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doDoneSearching)] autorelease];
}


/**
 * Run search if the user typed something into the search bar
 */
- (void)searchBar:(UISearchBar *)theSearchBar textDidChange:(NSString *)searchText
{
	// Remove all objects first.
  [tagArray removeAllObjects];
	
	if([searchText length] > 0)
  {
    [_searchOverlay removeFromSuperview];
		searching = YES;
    [[self tableView] setScrollEnabled:YES];
    [self reloadTableData];
	}
	else
  {
		[[self tableView] insertSubview:_searchOverlay aboveSubview:self.parentViewController.view];
		searching = NO;
    [[self tableView] setScrollEnabled:NO];
    [self reloadTableData];
	}
}


// TODO: MMA 6_12_2010 - does this ever get called?
- (void) searchBarSearchButtonClicked:(UISearchBar *)theSearchBar
{
  [self setTagArray:[TagPeer retrieveTagListLike:self.searchBar.text]];
  [searchBar resignFirstResponder];
}

/** 
 * Cleanup after searching finished
 * Hides keyboard, nulls out searchBar text, and re-adds add button to nav bar
 */
- (void) doDoneSearching
{
	self.searchBar.text = @"";
	[searchBar resignFirstResponder];
	searching = NO;
  [[self tableView] setScrollEnabled:YES];
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
	[[NSNotificationCenter defaultCenter] removeObserver:self];
  [_addButton release];
  [statusMsgBox release];
  [tagArray release];
  [subgroupArray release];
  [group release];
//  self.tableView = nil;
  [self setActivityIndicator:nil];
  [self setSearchBar:nil];
  [super dealloc];
}

@end