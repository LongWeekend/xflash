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
    
    // Default state
    _searchState = kSearchNoSearch;
    _currentResultArray = nil;
    
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
    if (_searchState == kSearchNoSearch)
    {
      // Show keyboard if no results
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
    _searchTarget = [sender selectedSegmentIndex];
    _currentResultArray = nil;
    _searchState = kSearchNoSearch;
    [[self _searchBar] becomeFirstResponder];
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
  // Reset the state machine
  _searchState = kSearchNoSearch;
  [self runSearchForString:[[self _searchBar] text]];
  [lclSearchBar resignFirstResponder];
}

/** Cancel the keyboard only */
- (void) searchBarCancelButtonClicked:(UISearchBar*)lclSearchBar
{
  [lclSearchBar resignFirstResponder];
}

/** Execute actual search with \param text. Designed to be called in background thread */
- (void) runSearchForString:(NSString*) text
{
  // Do we want a slow search?
  BOOL runSlowSearch = NO;
  if (_searchState == kSearchHasNoResults) runSlowSearch = YES;
  
  NSMutableArray *tmpResults = nil;
  if (_searchTarget == SEARCH_TARGET_WORDS)
  {
    tmpResults = [CardPeer searchCardsForKeyword:text doSlowSearch:runSlowSearch];
    [self set_cardSearchArray:tmpResults];
    _currentResultArray = [self _cardSearchArray];
  }
  else if (_searchTarget == SEARCH_TARGET_EXAMPLE_SENTENCES)
  {
    tmpResults = [ExampleSentencePeer searchSentencesForKeyword:text doSlowSearch:runSlowSearch];
    [self set_sentenceSearchArray:tmpResults];
    _currentResultArray = [self _sentenceSearchArray];
  }
  
  // Change state based on results (move us through state diagram --> has results -> no results -> no deep results)
  if ([tmpResults count] > 0)
    _searchState = kSearchHasResults;
  else if (_searchState == kSearchHasNoResults)
    _searchState = kSearchDeepHasNoResults;
  else
    _searchState = kSearchHasNoResults;

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
  if (_searchState == kSearchHasNoResults || _searchState == kSearchDeepHasNoResults)
  {
    return 1;
  }
  else 
  {
    if (_currentResultArray)
    {
      // Some results
      return [_currentResultArray count];
    }
    else
    {
      // Nothing searched for
      return 0;
    }
  }
}


/** Delegate for table, returns cells */
- (UITableViewCell *)tableView:(UITableView *)lclTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  // Get different kinds of cells depending on the state
  UITableViewCell *cell;
  switch (_searchState)
  {
    // Default to the same behavior if we have NO search results as well as having them
    case kSearchNoSearch:
      cell = [LWEUITableUtils reuseCellForIdentifier:@"NoSearch" onTable:lclTableView usingStyle:UITableViewCellStyleSubtitle];
      break;
      
    case kSearchHasResults:
      cell = [LWEUITableUtils reuseCellForIdentifier:[NSString stringWithFormat:@"Record-%d",_searchTarget] onTable:lclTableView usingStyle:UITableViewCellStyleSubtitle];
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
      break;
      
    // Regular search had no results
    case kSearchHasNoResults:
      cell = [LWEUITableUtils reuseCellForIdentifier:@"NoResults" onTable:lclTableView usingStyle:UITableViewCellStyleSubtitle];
      cell.textLabel.text = NSLocalizedString(@"No Results Found",@"SearchViewController.NoResults");
      cell.detailTextLabel.text = NSLocalizedString(@"Tap here to do a DEEP search.",@"SearchViewController.DoDeepSearch");
      cell.detailTextLabel.font = [UIFont boldSystemFontOfSize:12];
      cell.detailTextLabel.lineBreakMode = UILineBreakModeWordWrap;
      cell.selectionStyle = UITableViewCellSelectionStyleGray;
      cell.accessoryView = [self _activityIndicator];
      break;

    // Ran deep search, still nothing
    case kSearchDeepHasNoResults:
      cell = [LWEUITableUtils reuseCellForIdentifier:@"NoResults-DEEP" onTable:lclTableView usingStyle:UITableViewCellStyleDefault];
      cell.textLabel.text = NSLocalizedString(@"No Results Found",@"SearchViewController.NoResults");
      cell.selectionStyle = UITableViewCellSelectionStyleNone;
      cell.accessoryType = UITableViewCellAccessoryNone;
      break;
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
  if (_searchState == kSearchHasNoResults)
  {
    // Do deep search
    [[self _activityIndicator] startAnimating];
    // Run selector after delay to allow UIVIew to update on run loop
    [self performSelector:@selector(runSearchForString:) withObject:[[self _searchBar] text] afterDelay:0];
    return;
  }
  else if (_searchState == kSearchHasResults)
  {
    // Load child controller onto nav stack
    if (_searchTarget == SEARCH_TARGET_WORDS)
    {
      AddTagViewController *tagController = [[AddTagViewController alloc] initWithCard:[[self _cardSearchArray] objectAtIndex:indexPath.row]];
      [[self navigationController] pushViewController:tagController animated:YES];
      [tagController release];
    }
    else if (_searchTarget == SEARCH_TARGET_EXAMPLE_SENTENCES)
    {
      DisplaySearchedSentenceViewController *tmpVC = [[DisplaySearchedSentenceViewController alloc] initWithSentence:[[self _sentenceSearchArray] objectAtIndex:indexPath.row]];
      [[self navigationController] pushViewController:tmpVC animated:YES];
      [tmpVC release];
    }
  }
  
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
