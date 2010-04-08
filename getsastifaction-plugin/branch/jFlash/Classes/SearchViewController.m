//
//  SearchViewController.m
//  jFlash
//
//  Created by Mark Makdad on 8/2/09.
//  Copyright 2009 LONG WEEKEND INC.. All rights reserved.
//

#import "SearchViewController.h"
#import "CardPeer.h"
#import "AddTagViewController.h"

@implementation SearchViewController
@synthesize searchBar, searchArray, activityIndicator;

- (id) init
{
  if (self = [super initWithStyle:UITableViewStylePlain])
  {
    // Set the tab bar controller image png to the targets
    self.navigationItem.title = @"Word Search";
    self.tabBarItem = [[UITabBarItem alloc] initWithTabBarSystemItem:UITabBarSystemItemSearch tag:0];
    self.title = @"Search";
  }
  return self;
}


- (void) viewDidLoad
{
  [super viewDidLoad];
  self.searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0,0,320,45)];
  self.searchBar.delegate = self;
  [[self tableView] setTableHeaderView:searchBar];
  searchBar.autocorrectionType = UITextAutocorrectionTypeNo;
  searchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;

  activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
}  

- (void) viewWillAppear: (BOOL)animated
{
  [super viewWillAppear:animated];
  _searchRan = NO;
  _deepSearchRan = NO;
  
  self.navigationController.navigationBar.tintColor = [CurrentState getThemeTintColor];
  searchBar.tintColor = [CurrentState getThemeTintColor];
  // Show keyboard if no results TODO
  if (searchArray == nil || [searchArray count] == 0)
  {
    [searchBar becomeFirstResponder];
  }
}

#pragma mark searchBar methods

// only show the cancel button when the keyboard is displayed
- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)lclSearchBar {  
  lclSearchBar.showsCancelButton = YES;
  return YES;
}

- (BOOL)searchBarShouldEndEditing:(UISearchBar *)lclSearchBar {  
  lclSearchBar.showsCancelButton = NO;
  return YES;
}

- (void) searchBarSearchButtonClicked:(UISearchBar *)lclSearchBar
{
  [self runSearch:NO];
  _deepSearchRan = NO;
  [lclSearchBar resignFirstResponder];
}

- (void) searchBarCancelButtonClicked:(UISearchBar*)lclSearchBar
{
  [lclSearchBar resignFirstResponder];
}

// convenience method for performSelecterInBackground
- (void) runSlowSearch
{
  _deepSearchRan = YES;
  [self runSearch:YES];
}

- (void) runSearch:(BOOL) runSlowSearch
{
  _searchRan = YES;
  self.searchArray = [CardPeer searchCardsForKeyword:searchBar.text doSlowSearch:runSlowSearch];
  [activityIndicator stopAnimating];
  [[self tableView] reloadData];
  // reset the user to the top of the tableview for new searches
  [[self tableView] setContentOffset:CGPointMake(0, 0) animated:NO];
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  if([searchArray count] == 0 && _searchRan)
  {
    return 1;  // one row to say there are no results
  }
  else
  {
    return [searchArray count];
  }
}

- (UITableViewCell *)tableView:(UITableView *)lclTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  NSString *CellIdentifier = @"Cell";
  if([searchArray count] == 0 && _searchRan && _deepSearchRan){
    CellIdentifier = @"deepSearchNoResultCell";
  }
  else if([searchArray count] == 0 && _searchRan){
    CellIdentifier = @"noResultCell";
  }
  
  UITableViewCell *cell = [lclTableView dequeueReusableCellWithIdentifier:CellIdentifier];
  if (cell == nil) {
    if([searchArray count] == 0 && _searchRan && _deepSearchRan)
    {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    else
    {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
    }
  }
  
  cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
  cell.detailTextLabel.font = [UIFont boldSystemFontOfSize:12];    
  cell.selectionStyle = UITableViewCellSelectionStyleGray;
  
  if([searchArray count] == 0 && _searchRan && _deepSearchRan)
  {
    cell.textLabel.text = @"No Results Found";
    cell.detailTextLabel.lineBreakMode = UILineBreakModeWordWrap;
    cell.detailTextLabel.text = @"";
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
  }
  else if([searchArray count] == 0 && _searchRan)
  {
    cell.textLabel.text = @"No Results Found";
    cell.detailTextLabel.lineBreakMode = UILineBreakModeWordWrap;
    cell.detailTextLabel.text = @"Tap here to do a DEEP search.";
    cell.accessoryView = activityIndicator;
  }
  else
  {     
    cell.textLabel.text = [[searchArray objectAtIndex:(NSInteger)indexPath.row] headword];
    cell.detailTextLabel.lineBreakMode = UILineBreakModeTailTruncation;
    NSString *meaningStr = [[searchArray objectAtIndex:(NSInteger)indexPath.row] meaningWithoutMarkup];

    NSString *readingStr;
    NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
    if([[settings objectForKey:APP_READING] isEqualToString:SET_READING_KANA])
    {
      // KANA READING
      readingStr = [[searchArray objectAtIndex:(NSInteger)indexPath.row] reading];
    } 
    else if([[settings objectForKey:APP_READING] isEqualToString: SET_READING_ROMAJI])
    {
      // ROMAJI READING
      readingStr = [[searchArray objectAtIndex:(NSInteger)indexPath.row] romaji];
    }
    else
    {
      // BOTH READINGS
      readingStr = [NSString stringWithFormat:@"%@ / %@", [[searchArray objectAtIndex:(NSInteger)indexPath.row] reading], [[searchArray objectAtIndex:(NSInteger)indexPath.row] romaji] ];
    }
    
    if (readingStr.length > 0)
      cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ [%@]", meaningStr, readingStr];
    else
      cell.detailTextLabel.text = meaningStr;
  }
  
  return cell;
}


- (void)tableView:(UITableView *)lclTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  // if we already did a deep search we can't help them
  if([searchArray count] == 0 && _deepSearchRan)
  {
    return;
  }
  else if([searchArray count] == 0)
  {
    [activityIndicator startAnimating];
    // bizaar have to do to make the activityIndicator show.  Apparently without this 0 delay the ui won't be updated until the program loop finishes
    [self performSelector:@selector(runSlowSearch) withObject:nil afterDelay:0];
    return;
  }
	AddTagViewController *tagController = [[AddTagViewController alloc] initWithNibName:@"AddTagView" bundle:nil];
	tagController.cardId = [[searchArray objectAtIndex:(NSInteger)indexPath.row] cardId];
	tagController.title = @"Add Word To Set";
  tagController.currentCard = [searchArray objectAtIndex:(NSInteger)indexPath.row];
	[self.navigationController pushViewController:tagController animated:YES];
	[tagController release];
  [lclTableView deselectRowAtIndexPath:indexPath animated:NO];
}

- (void)dealloc
{
  [searchBar release];
  [searchArray release];
  [activityIndicator release];
  [super dealloc];
}


@end
