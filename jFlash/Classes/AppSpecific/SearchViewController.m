//
//  SearchViewController.m
//  jFlash
//
//  Created by Mark Makdad on 8/2/09.
//  Copyright 2009 LONG WEEKEND INC.. All rights reserved.
//

#import "SearchViewController.h"


@implementation SearchViewController
@synthesize _searchBar, _targetChooser, _cardSearchArray, _sentenceSearchArray, _activityIndicator;


/** Initializer to set up a table view, sets title & tab bar controller icon to "search" */
- (id) init
{
  if (self = [super initWithStyle:UITableViewStylePlain])
  {
    // Set the tab bar controller image png to the targets
    self.tabBarItem = [[UITabBarItem alloc] initWithTabBarSystemItem:UITabBarSystemItemSearch tag:0];
    self.title = NSLocalizedString(@"Search",@"SearchViewController.NavBarTitle");
    [self set_cardSearchArray:nil];
    [self set_sentenceSearchArray:nil];
    
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
  [[self _searchBar] sizeToFit];

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
 * Delegate view method - pops up the keyboard if no search results, also resets the search variables, makes sure title bar theme is correct 
 * If search is not installed, will call shouldShowDownloaderModal notification to stop user from using this screen
 */
- (void) viewWillAppear: (BOOL)animated
{
  // View related
  [super viewWillAppear:animated];
  self.navigationController.navigationBar.tintColor = [[ThemeManager sharedThemeManager] currentThemeTintColor];
  self._searchBar.tintColor = [[ThemeManager sharedThemeManager] currentThemeTintColor];
  
  _searchRan = NO;
  _deepSearchRan = NO;
  
  // Fire off a notification to bring up the downloader?
  PluginManager *pm = [[CurrentState sharedCurrentState] pluginMgr];
  if (![pm pluginIsLoaded:FTS_DB_KEY])
  {
    NSDictionary *dict = [[pm availablePluginsDictionary] objectForKey:FTS_DB_KEY];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"shouldShowDownloaderModal" object:self userInfo:dict];
    self._searchBar.placeholder = NSLocalizedString(@"Tap here to install search",@"SearchViewController.SearchBarPlaceholder_InstallPlugin"); 
  }
  else
  {
    self._searchBar.placeholder = NSLocalizedString(@"Enter search keyword",@"SearchViewController.SearchBarPlaceholder_douzo");
    // Show keyboard if no results
    if ([self _cardSearchArray] == nil || [[self _cardSearchArray] count] == 0)
    {
      [[self _searchBar] becomeFirstResponder];
    }
  }
}


/** 
 * This should be called by something else - maybe a notification-
 * after example sentences have been installed
 */
- (void) pluginDidInstall:(NSNotification*)aNotification
{
  // Only show control if both FTS AND EX are installed
  PluginManager *pm = [[CurrentState sharedCurrentState] pluginMgr];
  if ([pm pluginIsLoaded:FTS_DB_KEY] && [pm pluginIsLoaded:EXAMPLE_DB_KEY])
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


/**
 * Reads the value of the "pill" chooser and sets _searchTarget appropriately
 * In the off case that the caller is not a UISegmentControl, defaults to WORD search
 */
- (void) changeSearchTarget:(id)sender
{
  if ([sender respondsToSelector:@selector(selectedSegmentIndex)])
  {
    // Reload the table
    _searchTarget = [sender selectedSegmentIndex];
    [[self tableView] reloadData];
  }
  else
  {
    _searchTarget = SEARCH_TARGET_WORDS;
  }
}


#pragma mark searchBar delegate methods

/**
 * Check if the plugin installed, returns NO if not, and launches modal via notification
 * If plugin is loaded always returns YES
 */
- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar
{
  PluginManager *pm = [[CurrentState sharedCurrentState] pluginMgr];
  if ([pm pluginIsLoaded:FTS_DB_KEY])
  {
    return YES;
  }
  else
  {
    // And show them the modal again for good measure
    NSDictionary *dict = [[pm availablePluginsDictionary] objectForKey:FTS_DB_KEY];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"shouldShowDownloaderModal" object:self userInfo:dict];
    return NO;
  }
}

/** Only show the cancel button when the keyboard is displayed */
- (void) searchBarTextDidBeginEditing:(UISearchBar*) lclSearchBar
{
  lclSearchBar.showsCancelButton = YES;
}

/** Hide the cancel button when user finishes */
- (void) searchBarTextDidEndEditing:(UISearchBar *)lclSearchBar
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
    [self set_cardSearchArray:[CardPeer searchCardsForKeyword:text doSlowSearch:runSlowSearch]];
  else if (_searchTarget == SEARCH_TARGET_EXAMPLE_SENTENCES)
    [self set_sentenceSearchArray:[ExampleSentencePeer searchSentencesForKeyword:text doSlowSearch:runSlowSearch]];

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
    return 75.0f;
  else
    return 0.0f;
}


/** Returns 1 row ("no results") if there are no search results, otherwise returns number of results **/
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  if([[self _cardSearchArray] count] == 0 && _searchRan)
    return 1;  // one row to say there are no results
  else
    return [[self _cardSearchArray] count];
}


/** Delegate for table, returns cells */
- (UITableViewCell *)tableView:(UITableView *)lclTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  UITableViewCell *cell;
  if([[self _cardSearchArray] count] == 0 && _searchRan && _deepSearchRan)
    cell = [LWEUITableUtils reuseCellForIdentifier:@"NoResults" onTable:lclTableView usingStyle:UITableViewCellStyleDefault];
  else
    cell = [LWEUITableUtils reuseCellForIdentifier:@"SearchRecord" onTable:lclTableView usingStyle:UITableViewCellStyleSubtitle];
  
  // Determine what kind of cell it is to set the properties
  if([[self _cardSearchArray] count] == 0 && _searchRan)
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
    if (_searchTarget == SEARCH_TARGET_WORDS)
    {
      Card* searchResult = [[self _cardSearchArray] objectAtIndex:indexPath.row];
      cell = [self setupTableCell:cell forCard:searchResult];
    }
    else
    {
      ExampleSentence *searchResult = [[self _sentenceSearchArray] objectAtIndex:indexPath.row];
      cell = [self setupTableCell:cell forSentence:searchResult];
    }
  }
  return cell;
}


/** Helper method - makes a cell for cellForIndexPath for a Card */
- (UITableViewCell*) setupTableCell:(UITableViewCell*)cell forCard:(Card*) card
{
  // Is a search result record
  cell.textLabel.text = [card headword];
  cell.detailTextLabel.font = [UIFont boldSystemFontOfSize:12];
  cell.detailTextLabel.lineBreakMode = UILineBreakModeTailTruncation;
  cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
  cell.selectionStyle = UITableViewCellSelectionStyleGray;
  
  NSString *meaningStr = [card meaningWithoutMarkup];
  NSString *readingStr = [card combinedReadingForSettings];

  if (readingStr.length > 0)
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ [%@]", meaningStr, readingStr];
  else
    cell.detailTextLabel.text = meaningStr;
  return cell;
}


/** Helper method - makes a cell for cellForIndexPath for an ExampleSentence */
- (UITableViewCell*) setupTableCell:(UITableViewCell*)cell forSentence:(ExampleSentence*) sentence
{
  // Is a search result record
  cell.textLabel.text = [sentence sentenceJa];
  cell.textLabel.font = [UIFont systemFontOfSize:14];
  cell.detailTextLabel.font = [UIFont boldSystemFontOfSize:12];
  cell.detailTextLabel.lineBreakMode = UILineBreakModeTailTruncation;
  cell.detailTextLabel.text = [sentence sentenceEn];
  cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
  cell.selectionStyle = UITableViewCellSelectionStyleGray;
  return cell;
}


/**
 * Depending on view controller state, does different things (refactor?)
 * IF there are no search results & the user ran a DEEP search, just return - there's nothing to do
 * IF there are no search results, but the user has not yet run a deep search, run it.
 * IF there are search results and the user pressed one, push an appropriate view controller onto the view stack
 * (AddTagViewController = card search)
 */
- (void)tableView:(UITableView *)lclTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  // First, get the appropriate result array
  NSMutableArray *tmpResultArray = nil;
  if (_searchTarget == SEARCH_TARGET_WORDS)
  {
    tmpResultArray = [self _cardSearchArray];
  }
  else if (_searchTarget == SEARCH_TARGET_EXAMPLE_SENTENCES)
  {
    tmpResultArray = [self _sentenceSearchArray];
  }

  // if we already did a deep search we can't help them
  if ([tmpResultArray count] == 0 && _deepSearchRan)
  {
    return;
  }
  else if ([tmpResultArray count] == 0)
  {
    [[self _activityIndicator] startAnimating];
    // Run selector after delay to allow UIVIew to update on run loop
    [self performSelector:@selector(runSlowSearch) withObject:nil afterDelay:0];
    return;
  }
  else
  {
    if (_searchTarget == SEARCH_TARGET_WORDS)
    {
      AddTagViewController *tagController = [[AddTagViewController alloc] initWithCard:[tmpResultArray objectAtIndex:indexPath.row]];
      [[self navigationController] pushViewController:tagController animated:YES];
      [tagController release];
    }
    else if (_searchTarget == SEARCH_TARGET_EXAMPLE_SENTENCES)
    {
      DisplaySearchedSentenceViewController *tmpVC = [[DisplaySearchedSentenceViewController alloc] initWithSentence:[tmpResultArray objectAtIndex:indexPath.row]];
      [[self navigationController] pushViewController:tmpVC animated:YES];
      [tmpVC release];
    }
  }
  
  // Make sure to deselect
  [lclTableView deselectRowAtIndexPath:indexPath animated:NO];
}

//! Standard dealloc
- (void)dealloc
{
  [self set_searchBar:nil];
  [self set_cardSearchArray:nil];
  [self set_activityIndicator:nil];
  [super dealloc];
}


@end
