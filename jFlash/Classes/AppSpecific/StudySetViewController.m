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

- (id) init
{
  if (self = [super initWithStyle:UITableViewStyleGrouped])
  {
    // Set the tab bar controller image png to the targets
    self.tabBarItem.image = [UIImage imageNamed:@"15-tags.png"];
    self.title = @"Study Sets";
    self.navigationItem.title = @"Study Sets";
  }
  return self;
}

- (void) loadView
{
  [super loadView];
  // Add the search bar
  self.searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0,0,320,45)];
  self.searchBar.delegate = self;
  [[self tableView] setTableHeaderView:searchBar];
  searchBar.autocorrectionType = UITextAutocorrectionTypeNo;
  searchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
	searching = NO;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  selectedTagId = -1;
  
  // Set this to the master set (main) if no set
  if (self.groupId <= 0) self.groupId = 0;

  // Register listener to reload data if modal added a set
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadTableData) name:@"setAddedToView" object:nil];

  // Register listener to reload data if settings were changed
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadTableData) name:@"settingsWereChanged" object:nil];

  // Register listener to reload data if a user adds a word to a set from AddTag
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadTableData) name:@"cardAddedToTag" object:nil];

  // Register listener to reload data if a user deletes a tag from a group
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadSubgroupData) name:@"tagDeletedFromGroup" object:nil];
  
  // Register listener in case user starts set from word list
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changeStudySetFromWordList:) name:@"setWasChangedFromWordsList" object:nil];
  
  // Register listener in case theme was changed (to ensure back button changes color)
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(popToRoot) name:@"themeWasChanged" object:nil];

  addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addStudySet:)];
  self.navigationItem.rightBarButtonItem = addButton;

  // Get this group
  group = [GroupPeer retrieveGroupById:self.groupId];
  [group retain];

  // Get subgroups
  [self reloadSubgroupData];

  // Get tags
  self.tagArray = [group getTags];
  [addButton release];

  // Activity indicator
  activityIndicator = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
}

- (void) viewWillAppear: (BOOL)animated
{
  [super viewWillAppear:animated];
  [self setTitle: [group groupName]];
  self.navigationController.navigationBar.tintColor = [[ThemeManager sharedThemeManager] currentThemeTintColor];
  self.navigationController.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:TABLEVIEW_BACKGROUND_IMAGE]];
  searchBar.tintColor = [[ThemeManager sharedThemeManager] currentThemeTintColor];
  searchBar.placeholder = @"Search Sets By Name";
  [self hideSearchBar];
  [[self tableView] setBackgroundColor: [UIColor clearColor]];
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
	if (searching)
  {
    [self setTagArray: [TagPeer retrieveTagListLike:searchBar.text]];
  }
  else{
    [self setTagArray: [group getTags]];
  }
  [[self tableView] reloadData];
}

- (void) hideSearchBar
{
  [[self tableView] setContentOffset:CGPointMake(0, searchBar.frame.size.height)];
}

- (void) popToRoot
{
  [self.navigationController popToRootViewControllerAnimated:NO];
}

- (void) changeStudySetFromWordList:(NSNotification*)dict
{
  [self changeStudySet:[[dict userInfo] objectForKey:@"tag"]];
}

- (void) changeStudySet:(Tag*) tag
{
  CurrentState *appSettings = [CurrentState sharedCurrentState];
  [appSettings setActiveTag:tag];
  
  // Post notification to switch active tab
  [[NSNotificationCenter defaultCenter] postNotificationName:@"switchToStudyView" object:self];

  // Tell StudyViewController to reload its data
  [[NSNotificationCenter defaultCenter] postNotificationName:@"setWasChanged" object:self];
  
  // Stop the animator
  [activityIndicator stopAnimating];
  selectedTagId = -1;
  [[self tableView] reloadData];
}


- (void)addStudySet:sender
{
  AddStudySetInputViewController* addStudySetInputViewController = [[AddStudySetInputViewController alloc] initWithNibName:@"ModalInputView" bundle:nil];
  addStudySetInputViewController.ownerId = self.groupId;
  addStudySetInputViewController.title = @"Create Study Set";
  UINavigationController *modalNavController = [[UINavigationController alloc] initWithRootViewController:addStudySetInputViewController];
  [[self navigationController] presentModalViewController:modalNavController animated:YES];
  [modalNavController release];
	[addStudySetInputViewController release];
}


- (void)setEditing:(BOOL) editing animated:(BOOL)animated
{
	[super setEditing:editing animated:animated];
	[[self tableView] setEditing:editing animated:YES];
}

#pragma mark UITableView methods

// Override to support editing the table view.
- (void)tableView:(UITableView *)lclTableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
  if (editingStyle == UITableViewCellEditingStyleDelete)
  {
    // Delete the row from the data source
    Tag *tmpTag = [tagArray objectAtIndex:indexPath.row];
    [TagPeer deleteTag:tmpTag.tagId];
    [tagArray removeObjectAtIndex:[indexPath row]];
    [lclTableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:YES];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"tagDeletedFromGroup" object:self];
  }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)lclTableView
{
	if (searching)
		return 1;
  else
    return 2;
}


- (NSInteger)tableView:(UITableView *)lclTableView numberOfRowsInSection:(NSInteger)section
{
	if (searching)
  {
    if([[self tagArray] count] > 0)
      return [[self tagArray] count];
    else
      return 1; // show no results message
  }
  else{
    if (section == 1)
      return [[self tagArray] count];
    else
      return [[self subgroupArray] count];
  }
}

- (UITableViewCell *)tableView:(UITableView *)lclTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  UITableViewCell *cell = nil;
  // Get theme manager so we can get elements from it
  ThemeManager *tm = [ThemeManager sharedThemeManager];

  // Study Set Cells (ie. a tag)
  if (indexPath.section == 1 || searching)
  {
    
    // No search results msg
    if(searching && [tagArray count] == 0)
    {
      cell = [LWEUITableUtils reuseCellForIdentifier:@"result" onTable:lclTableView usingStyle:UITableViewCellStyleSubtitle];
      cell.accessoryType = UITableViewCellAccessoryNone;
      cell.detailTextLabel.font = [UIFont boldSystemFontOfSize:12];    
      cell.selectionStyle = UITableViewCellSelectionStyleGray;
      cell.textLabel.text = @"No Results Found";
      cell.detailTextLabel.lineBreakMode = UILineBreakModeWordWrap;
    }
    // Normal cell display
    else
    {
      cell = [LWEUITableUtils reuseCellForIdentifier:@"normal" onTable:lclTableView usingStyle:UITableViewCellStyleSubtitle];

      // Set up the image
      UIImageView* tmpView = cell.imageView;
      tmpView.image = [UIImage imageNamed:[tm elementWithCurrentTheme:@"tag-icon.png"]];
      
      Tag* tmpTag = [self.tagArray objectAtIndex:indexPath.row];
      cell.textLabel.text = [tmpTag tagName];
      cell.selectionStyle = UITableViewCellSelectionStyleNone;
      NSString* tmpDetailText = [NSString stringWithFormat:@"%d Words", [tmpTag cardCount]];
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
        cell.accessoryView = activityIndicator;
        cell.detailTextLabel.text = @"Loading cards...";
      }
    }
  }
  // Group Cells
  else
  {
    cell = [LWEUITableUtils reuseCellForIdentifier:@"group" onTable:lclTableView usingStyle:UITableViewCellStyleSubtitle];
    
    // Folders should display the theme color when pressed!
    CustomCellBackgroundView *bgView = [[CustomCellBackgroundView alloc] initWithFrame:CGRectZero];
    [bgView setCellIndexPath:indexPath tableLength:(NSInteger)[subgroupArray count]];
    [bgView setBorderColor:[lclTableView separatorColor]];
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
      tmpDetailText = [NSString stringWithFormat:@"%d Groups; ",[tmpGroup getChildGroupCount]]; 
    }
    tmpDetailText = [NSString stringWithFormat:@"%@%d Sets",tmpDetailText,tmpGroup.tagCount];

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


//! UI Table View delegate - when a user selects a cell, either start that set, or navigate to the group (if a group)
- (void)tableView:(UITableView *)lclTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  if (indexPath.section == 1 || searching)
  {
    if([tagArray count] > 0)
    {
      int numCards = [[self.tagArray objectAtIndex:indexPath.row] cardCount];
      if(numCards > 0)
      {
        self.selectedTagId = indexPath.row;
        NSString *tag = [[self.tagArray objectAtIndex:indexPath.row] tagName];
        self.statusMsgBox = [[UIAlertView alloc] initWithTitle:tag message:@"Do you want to start this set?  Progress on your last set will be saved." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK",nil];
        [statusMsgBox show];
        [tag release];
      }
      else
      {
        UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:@"No Words In Set" message:@"To add words to this set, you can use Search." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
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

//! Alert view delegate - initiates the "study set change" if they pressed OK
- (void) alertView: (UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
  // This is the OK button
  if (buttonIndex == 1)
  {
    [[self tableView] reloadData];
    [activityIndicator startAnimating];
    [self performSelector:@selector(changeStudySet:) withObject:[[self tagArray] objectAtIndex:self.selectedTagId] afterDelay:0];
    return;
  }
  else 
  {
    selectedTagId = -1;
  }
}

- (void)tableView:(UITableView *)lclTableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
  if (indexPath.section == 1 || searching)
  {
    [lclTableView deselectRowAtIndexPath:indexPath animated:NO];
    Tag* tmpTag = [[self tagArray] objectAtIndex:indexPath.row];
    StudySetWordsViewController *wordsController = [[StudySetWordsViewController alloc] initWithTag:tmpTag]; 
    [self.navigationController pushViewController:wordsController animated:YES];
    [wordsController release];
  }
}

- (BOOL)tableView:(UITableView *)lclTableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
  // Only can edit tags, and user tags at that
  if (indexPath.section == 1)
  {
    Tag* tmpTag = [tagArray objectAtIndex:indexPath.row];
    if (tmpTag.tagEditable == 1) return YES;
    else return NO;
  }
  else return NO;
}

#pragma mark Search Bar

- (void) searchBarTextDidBeginEditing:(UISearchBar *)theSearchBar {
	
	//When the user clicks back from teh detail view
	if (searching) return;
	
  //Add the overlay view.
  if (searchOverlay == nil)
  {
    searchOverlay = [[UIView alloc] init];
    searchOverlayBtn = [[UIButton alloc] init];
    [searchOverlay insertSubview:searchOverlayBtn atIndex:0];
    [searchOverlayBtn addTarget:self action:@selector(doDoneSearching:) forControlEvents:UIControlEventTouchDown];
  }

  searchOverlay.userInteractionEnabled = YES;
	CGFloat yaxis = self.navigationController.navigationBar.frame.size.height;
	CGFloat width = self.view.frame.size.width;
	CGFloat height = self.view.frame.size.height;
  CGRect frame = CGRectMake(0, yaxis, width, height);
	searchOverlay.frame = frame;	
  searchOverlayBtn.frame = frame;
	searchOverlay.backgroundColor = [UIColor grayColor];
	searchOverlay.alpha = 0.5;
	[[self tableView] insertSubview:searchOverlay aboveSubview:self.parentViewController.view];
	
	searching = YES;
  [self setTagArray: [TagPeer retrieveTagListLike:searchBar.text]];
  [[self tableView] setScrollEnabled:NO];
	
	//Add the done button.
	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doDoneSearching:)] autorelease];
}


- (void)searchBar:(UISearchBar *)theSearchBar textDidChange:(NSString *)searchText
{
  
	// Remove all objects first.
  [tagArray removeAllObjects];
	
	if([searchText length] > 0) {
    [searchOverlay removeFromSuperview];
		searching = YES;
    [[self tableView] setScrollEnabled:YES];
    [self reloadTableData];
	}
	else {
		[[self tableView] insertSubview:searchOverlay aboveSubview:self.parentViewController.view];
		searching = NO;
    [[self tableView] setScrollEnabled:NO];
    [self reloadTableData];
	}
}


- (void) searchBarSearchButtonClicked:(UISearchBar *)theSearchBar
{
  [self setTagArray: [TagPeer retrieveTagListLike:searchBar.text]];
  [searchBar resignFirstResponder];
}


- (void) doDoneSearching:(id)sender
{
	searchBar.text = @"";
	[searchBar resignFirstResponder];
	searching = NO;
  [[self tableView] setScrollEnabled:YES];
	self.navigationItem.rightBarButtonItem = nil;
  [self hideSearchBar];
  [self reloadTableData];
  
  // Kill search overlay
  [searchOverlay removeFromSuperview];
	[searchOverlay release];
	searchOverlay = nil;
}


- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
  [activityIndicator release];
  [statusMsgBox release];
  [tagArray release];
  [subgroupArray release];
  [group release];
  [searchBar release];
  [super dealloc];
}

@end