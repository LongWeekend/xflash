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
    self.tabBarItem = [[UITabBarItem alloc] initWithTabBarSystemItem:UITabBarSystemItemSearch tag:0];
    self.title = NSLocalizedString(@"Search",@"SearchViewController.NavBarTitle");
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
  
  self.navigationController.navigationBar.tintColor = [[ThemeManager sharedThemeManager] currentThemeTintColor];
  searchBar.tintColor = [[ThemeManager sharedThemeManager] currentThemeTintColor];
  // Show keyboard if no results TODO
  if (searchArray == nil || [searchArray count] == 0)
  {
    [searchBar becomeFirstResponder];
  }
}


#pragma mark searchBar methods

/** Only show the cancel button when the keyboard is displayed */
- (void) searchBarDidBeginEditing:(UISearchBar*) lclSearchBar
{
  lclSearchBar.showsCancelButton = YES;
}

/** Hide the cancel button when user finishes */
- (void) searchBarDidEndEditing:(UISearchBar *)lclSearchBar
{  
  lclSearchBar.showsCancelButton = NO;
}

/** Run the search and resign the keyboard */
- (void) searchBarSearchButtonClicked:(UISearchBar *)lclSearchBar
{
  _deepSearchRan = NO;
  [self runSearchForString:searchBar.text isSlowSearch:NO];
  [lclSearchBar resignFirstResponder];
}

/** Cancel the keyboard only */
- (void) searchBarCancelButtonClicked:(UISearchBar*)lclSearchBar
{
  [lclSearchBar resignFirstResponder];
}

/** convenience method for performSelectorInBackground */
- (void) runSlowSearch
{
  _deepSearchRan = YES;
  [self runSearchForString:searchBar.text isSlowSearch:YES];
}

/** Execute actual search with \param text. Designed to be called in background thread */
- (void) runSearchForString:(NSString*)text isSlowSearch:(BOOL)runSlowSearch
{
  _searchRan = YES;
  self.searchArray = [CardPeer searchCardsForKeyword:text doSlowSearch:runSlowSearch];
  [activityIndicator stopAnimating];
  [[self tableView] reloadData];
  // reset the user to the top of the tableview for new searches
  [[self tableView] setContentOffset:CGPointMake(0, 0) animated:NO];
}

#pragma mark Table view methods

/** Hardcoded to 1 **/
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
  return 1;
}

/** Returns 1 row ("no results") if there are no search results, otherwise returns number of results **/
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

/** Delegate for table, returns cells */
- (UITableViewCell *)tableView:(UITableView *)lclTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  UITableViewCell *cell;
  if([searchArray count] == 0 && _searchRan && _deepSearchRan)
  {
    cell = [LWEUITableUtils reuseCellForIdentifier:@"NoResults" onTable:lclTableView usingStyle:UITableViewCellStyleDefault];
  }
  else
  {
    cell = [LWEUITableUtils reuseCellForIdentifier:@"SearchRecord" onTable:lclTableView usingStyle:UITableViewCellStyleSubtitle];
  }
  
  // Determine what kind of cell it is to set the properties
  if([searchArray count] == 0 && _searchRan)
  {
    cell.textLabel.text = NSLocalizedString(@"No Results Found",@"SearchViewController.NoResults");

    // Depending on what kind of search, do things slightly differently
    if (_deepSearchRan)
    {
      cell.selectionStyle = UITableViewCellSelectionStyleNone;
      cell.accessoryType = UITableViewCellAccessoryNone;
    }
    else
    {
      cell.detailTextLabel.text = NSLocalizedString(@"Tap here to do a DEEP search.",@"SearchViewController.DoDeepSearch");
      cell.detailTextLabel.font = [UIFont boldSystemFontOfSize:12];
      cell.detailTextLabel.lineBreakMode = UILineBreakModeWordWrap;
      cell.selectionStyle = UITableViewCellSelectionStyleGray;
      cell.accessoryView = activityIndicator;
    }
  }
  else
  {     
    // Is a search result record
    Card* searchResult = [searchArray objectAtIndex:indexPath.row];
    cell.textLabel.text = [searchResult headword];
    cell.detailTextLabel.font = [UIFont boldSystemFontOfSize:12];
    cell.detailTextLabel.lineBreakMode = UILineBreakModeTailTruncation;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.selectionStyle = UITableViewCellSelectionStyleGray;

    NSString *meaningStr = [searchResult meaningWithoutMarkup];

    NSString *readingStr;
    NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
    if([[settings objectForKey:APP_READING] isEqualToString:SET_READING_KANA])
    {
      // KANA READING
      readingStr = [searchResult reading];
    } 
    else if ([[settings objectForKey:APP_READING] isEqualToString:SET_READING_ROMAJI])
    {
      // ROMAJI READING
      readingStr = [searchResult romaji];
    }
    else
    {
      // BOTH READINGS
      readingStr = [NSString stringWithFormat:@"%@ / %@", [searchResult reading], [searchResult romaji]];
    }
    
    if (readingStr.length > 0)
      cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ [%@]", meaningStr, readingStr];
    else
      cell.detailTextLabel.text = meaningStr;
  }
  
  return cell;
}

/** Take action when the user selects a cell */
- (void)tableView:(UITableView *)lclTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  // if we already did a deep search we can't help them
  if ([searchArray count] == 0 && _deepSearchRan)
  {
    return;
  }
  else if ([searchArray count] == 0)
  {
    [activityIndicator startAnimating];
    // Run selector after delay to allow UIVIew to update on run loop
    [self performSelector:@selector(runSlowSearch) withObject:nil afterDelay:0];
    return;
  }
  else
  {
    AddTagViewController *tagController = [[AddTagViewController alloc] initWithNibName:@"AddTagView" bundle:nil];
    tagController.cardId = [[searchArray objectAtIndex:indexPath.row] cardId];
    tagController.title = NSLocalizedString(@"Add Word To Set",@"AddTagViewController.NavBarTitle");
    tagController.currentCard = [searchArray objectAtIndex:indexPath.row];
    [self.navigationController pushViewController:tagController animated:YES];
    [tagController release];
  }
  
  // Make sure to deselect
  [lclTableView deselectRowAtIndexPath:indexPath animated:NO];
}


// TODO: what function does this function function with?  MMA 6/8/2010
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
  if (buttonIndex == 1) {     // they clicked OK.
    
  }
}

- (void)dealloc
{
  [searchBar release];
  [searchArray release];
  [activityIndicator release];
  [super dealloc];
}


@end
