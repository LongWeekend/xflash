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
@synthesize _searchBar, _targetChooser, _searchArray, _activityIndicator;


/** Initializer to set up a table view, sets title & tab bar controller icon to "search" */
- (id) init
{
  if (self = [super initWithStyle:UITableViewStylePlain])
  {
    // Set the tab bar controller image png to the targets
    self.tabBarItem = [[UITabBarItem alloc] initWithTabBarSystemItem:UITabBarSystemItemSearch tag:0];
    self.title = NSLocalizedString(@"Search",@"SearchViewController.NavBarTitle");
    self._searchArray = nil;
    
    // Is the plugin loaded for example sentences?
    _showSearchTargetControl = [[[CurrentState sharedCurrentState] pluginMgr] pluginIsLoaded:EXAMPLE_DB_KEY];
    _searchTarget = SEARCH_TARGET_WORDS;
    
    // Register an observer for the example sentences
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pluginDidInstall:) name:@"pluginDidInstall" object:nil];
  }
  return self;
}


/** Programmatically create a UISearchBar & UISegmentedControl for search */
- (void) viewDidLoad
{
  [super viewDidLoad];

  // Programmatically make UISearchBar
  UISearchBar *tmpSearchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0,0,320,45)];
  tmpSearchBar.delegate = self;
  tmpSearchBar.autocorrectionType = UITextAutocorrectionTypeNo;
  tmpSearchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
  [self set_searchBar:tmpSearchBar];
  [tmpSearchBar release];
  // Set the Nav Bar title view to be the search bar itself
  self.navigationItem.titleView = [self _searchBar];

  // Programmatically create "pill" chooser - searches between words & example sentences - default is words
  // Do not add it to the view in this method - we split that out so it can be called separately when the 
  // user installs example sentences
  UISegmentedControl *tmpChooser;
  tmpChooser = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:NSLocalizedString(@"Words",@"SearchViewController.Search_Words"),
                                                                                   NSLocalizedString(@"Example Sentences",@"SearchViewController.Search_Sentences"),nil]];
  tmpChooser.segmentedControlStyle = UISegmentedControlStyleBar;
  tmpChooser.selectedSegmentIndex = _searchTarget;
  tmpChooser.frame = CGRectMake(10,5,300,25);
  tmpChooser.tintColor = [UIColor lightGrayColor];
  [tmpChooser addTarget:self action:@selector(changeSearchTarget:) forControlEvents:UIControlEventValueChanged];
  [self set_targetChooser:tmpChooser];
  [tmpChooser release];
  
  // If we have the Example sentence database...
  if (_showSearchTargetControl) [self _addSearchControlToHeader];

  // Make the spinner
  [self set_activityIndicator:[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray]];
}

/** 
 * This should be called by something else - maybe a notification-
 * after example sentences have been installed
 */
- (void) pluginDidInstall:(NSNotification*)aNotification
{
  NSDictionary *dict = [aNotification userInfo];
  if ([[dict objectForKey:@"plugin_key"] isEqualToString:EXAMPLE_DB_KEY])
  {
    _showSearchTargetControl = YES;
    [self _addSearchControlToHeader];
  }
}


/**
 * Adds the search target control into the search view
 */
- (void) _addSearchControlToHeader
{
  UIView *tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 35)];
  tableHeaderView.backgroundColor = [UIColor lightGrayColor];
  [tableHeaderView addSubview:[self _targetChooser]];
  [[self tableView] setTableHeaderView:tableHeaderView];
  [tableHeaderView release];
}


/** Delegate view method - pops up the keyboard if no search results, also resets the search variables, makes sure title bar theme is correct */
- (void) viewWillAppear: (BOOL)animated
{
  // View related
  [super viewWillAppear:animated];
  self.navigationController.navigationBar.tintColor = [[ThemeManager sharedThemeManager] currentThemeTintColor];
  self._searchBar.tintColor = [[ThemeManager sharedThemeManager] currentThemeTintColor];

  _searchRan = NO;
  _deepSearchRan = NO;
  
  // Show keyboard if no results
  if ([self _searchArray] == nil || [[self _searchArray] count] == 0)
  {
    [[self _searchBar] becomeFirstResponder];
  }
}


/**
 * Reads the value of the "pill" chooser and sets _searchTarget appropriately
 * In the off case that the caller is not a UISegmentControl, defaults to WORD search
 */
- (void) changeSearchTarget:(id)sender
{
  if ([sender respondsToSelector:@selector(selectedSegmentIndex)])
  {
    _searchTarget = [sender selectedSegmentIndex];
  }
  else
  {
    _searchTarget = SEARCH_TARGET_WORDS;
  }
}


#pragma mark searchBar delegate methods

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
  [self runSearchForString:[[self _searchBar] text] isSlowSearch:NO];
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
  [self runSearchForString:[[self _searchBar] text] isSlowSearch:YES];
}

/** Execute actual search with \param text. Designed to be called in background thread */
- (void) runSearchForString:(NSString*)text isSlowSearch:(BOOL)runSlowSearch
{
  _searchRan = YES;
  if (_searchTarget == SEARCH_TARGET_WORDS)
  {
    [self set_searchArray:[CardPeer searchCardsForKeyword:text doSlowSearch:runSlowSearch]];
  }
  else
  {
//    self.searchArray = [ExampleSentencePeer ]
  }

  [[self _activityIndicator] stopAnimating];
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


/** Returns 75px if _showSearchTargetControl is YES, otherwise returns UITableView standard 0 (no headers) */
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
  if (_showSearchTargetControl)
  {
    return 75.0f;
  }
  else
  {
    return 0.0f;
  }
}


/** Returns 1 row ("no results") if there are no search results, otherwise returns number of results **/
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  if([[self _searchArray] count] == 0 && _searchRan)
  {
    return 1;  // one row to say there are no results
  }
  else
  {
    return [[self _searchArray] count];
  }
}


/** Delegate for table, returns cells */
- (UITableViewCell *)tableView:(UITableView *)lclTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  UITableViewCell *cell;
  if([[self _searchArray] count] == 0 && _searchRan && _deepSearchRan)
  {
    cell = [LWEUITableUtils reuseCellForIdentifier:@"NoResults" onTable:lclTableView usingStyle:UITableViewCellStyleDefault];
  }
  else
  {
    cell = [LWEUITableUtils reuseCellForIdentifier:@"SearchRecord" onTable:lclTableView usingStyle:UITableViewCellStyleSubtitle];
  }
  
  // Determine what kind of cell it is to set the properties
  if([[self _searchArray] count] == 0 && _searchRan)
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
      cell.accessoryView = [self _activityIndicator];
    }
  }
  else
  {     
    // Is a search result record
    Card* searchResult = [[self _searchArray] objectAtIndex:indexPath.row];
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


/**
 * Depending on view controller state, does different things (refactor?)
 * IF there are no search results & the user ran a DEEP search, just return - there's nothing to do
 * IF there are no search results, but the user has not yet run a deep search, run it.
 * IF there are search results and the user pressed one, push an AddTagViewController onto the view stack
 */
- (void)tableView:(UITableView *)lclTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  // if we already did a deep search we can't help them
  if ([[self _searchArray] count] == 0 && _deepSearchRan)
  {
    return;
  }
  else if ([[self _searchArray] count] == 0)
  {
    [[self _activityIndicator] startAnimating];
    // Run selector after delay to allow UIVIew to update on run loop
    [self performSelector:@selector(runSlowSearch) withObject:nil afterDelay:0];
    return;
  }
  else
  {
    AddTagViewController *tagController = [[AddTagViewController alloc] initWithCard:[[self _searchArray] objectAtIndex:indexPath.row]];
    [[self navigationController] pushViewController:tagController animated:YES];
    [tagController release];
  }
  
  // Make sure to deselect
  [lclTableView deselectRowAtIndexPath:indexPath animated:NO];
}


- (void)dealloc
{
  [self set_searchBar:nil];
  [self set_searchArray:nil];
  [self set_activityIndicator:nil];
  [super dealloc];
}


@end
