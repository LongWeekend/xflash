//
//  SearchViewController.m
//  jFlash
//
//  Created by Mark Makdad on 8/2/09.
//  Copyright 2009 LONG WEEKEND INC.. All rights reserved.
//

#import "SearchViewController.h"
const NSInteger KSegmentedTableHeader = 100;

// Private method declarations
@interface SearchViewController ()
- (BOOL) _checkMembershipCacheForCardId: (NSInteger)cardId;
- (void) _removeCardFromMembershipCache: (NSInteger)cardId;
- (void) _toggleMembership:(id)sender event:(id)event;
@end

@implementation SearchViewController
@synthesize _searchBar, _wordsOrSentencesSegment, _cardSearchArray, _sentenceSearchArray, _activityIndicator;
@synthesize tableView, searchTerm;

@synthesize membershipCacheArray;


/** Initializer to set up a table view, sets title & tab bar controller icon to "search" */
- (id) init
{
  if ((self = [super init]))
  {
    // Set the tab bar controller image png to the targets
    self.tabBarItem = [[[UITabBarItem alloc] initWithTabBarSystemItem:UITabBarSystemItemSearch tag:0] autorelease];
    self.title = NSLocalizedString(@"Search",@"SearchViewController.NavBarTitle");
    [self set_cardSearchArray:nil];
    [self set_sentenceSearchArray:nil];
    
    // Is the plugin loaded for example sentences?
    _showSearchTargetControl = NO;
    // Disabled for 1.1 release
    //    _showSearchTargetControl = [[[CurrentState sharedCurrentState] pluginMgr] pluginIsLoaded:EXAMPLE_DB_KEY];
    _searchTarget = SEARCH_TARGET_WORDS;
    
    // Default state
    _searchState = kSearchNoSearch;
    _currentResultArray = nil;
    
    // Register an observer for the example sentences
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pluginDidInstall:) name:LWEPluginDidInstall object:nil];
  }
  return self;
}


/** Programmatically create a UISearchBar & UISegmentedControl for search */
- (void) viewDidLoad
{
  [super viewDidLoad];

  // Programmatically make UISearchBar
  // TODO: iPad customization!
  UISearchBar *tmpSearchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0,0,320,45)];
  tmpSearchBar.delegate = self;
  tmpSearchBar.autocorrectionType = UITextAutocorrectionTypeNo;
  tmpSearchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
  tmpSearchBar.text = self.searchTerm;
  // we don't need the searchTerm anymore
  self.searchTerm = nil;
  [self set_searchBar:tmpSearchBar];
  [tmpSearchBar release];
  // Set the Nav Bar title view to be the search bar itself
  self.navigationItem.titleView = [self _searchBar];
  [[self _searchBar] sizeToFit];

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
  [[[self view] viewWithTag:KSegmentedTableHeader] setBackgroundColor:[[ThemeManager sharedThemeManager] currentThemeTintColor]];
  self._wordsOrSentencesSegment.tintColor = [[ThemeManager sharedThemeManager] currentThemeTintColor];
  
  // Fire off a notification to bring up the downloader?  If we are on the old data version, let them use search!
  PluginManager *pm = [[CurrentState sharedCurrentState] pluginMgr];
  NSUserDefaults *settings = [NSUserDefaults standardUserDefaults]; 
  BOOL hasFTS = [pm pluginIsLoaded:FTS_DB_KEY];
  BOOL isFirstVersion = [[settings objectForKey:APP_DATA_VERSION] isEqualToString:JFLASH_VERSION_1_0];
  if (!(hasFTS || isFirstVersion))
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
    // Disabled for JFlash 1.1 release
//    _showSearchTargetControl = YES;
//    [self _addSearchControlToHeader];
  }
}


/**
 * Adds the search target control into the search view
 */
- (void) _addSearchControlToHeader
{
  // Programmatically create "pill" chooser - searches between words & example sentences - default is words
  UISegmentedControl *tmpChooser;
  tmpChooser = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:NSLocalizedString(@"Words",@"SearchViewController.Search_Words"),
                                                          NSLocalizedString(@"Example Sentences",@"SearchViewController.Search_Sentences"),nil]];
  tmpChooser.segmentedControlStyle = UISegmentedControlStyleBar;
  tmpChooser.selectedSegmentIndex = _searchTarget;
  // TODO: iPad customization!
  tmpChooser.frame = CGRectMake(10,5,300,25);
  tmpChooser.tintColor = [UIColor lightGrayColor];
  [tmpChooser addTarget:self action:@selector(changeSearchTarget:) forControlEvents:UIControlEventValueChanged];
  [self set_wordsOrSentencesSegment:tmpChooser];
  [tmpChooser release];  
  
  // TODO: iPad customization!  
  UIView *tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 35)];
  tableHeaderView.backgroundColor = [[ThemeManager sharedThemeManager] currentThemeTintColor];
  [tableHeaderView addSubview:[self _wordsOrSentencesSegment]];
  [tableHeaderView setTag: KSegmentedTableHeader];
  [[self view] addSubview:tableHeaderView];
  [tableHeaderView setHidden:YES];
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
  NSUserDefaults *settings = [NSUserDefaults standardUserDefaults]; 
  BOOL hasFTS = [pm pluginIsLoaded:FTS_DB_KEY];
  BOOL isFirstVersion = [[settings objectForKey:APP_DATA_VERSION] isEqualToString:JFLASH_VERSION_1_0];
  if (hasFTS || isFirstVersion)
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
  [[self.view viewWithTag:KSegmentedTableHeader] setHidden:NO];
}

/** Hide the cancel button when user finishes */
- (void) searchBarTextDidEndEditing:(UISearchBar *)lclSearchBar
{  
  lclSearchBar.showsCancelButton = NO;
  [[self.view viewWithTag:KSegmentedTableHeader] setHidden:YES];
}

/** Run the search and resign the keyboard */
- (void) searchBarSearchButtonClicked:(UISearchBar *)lclSearchBar
{
  // Reset the state machine
  _searchState = kSearchNoSearch;
  
  // Clear the cache of favorites
  self.membershipCacheArray = nil;
  
  [self runSearchForString:[[self _searchBar] text]];
  [lclSearchBar resignFirstResponder];
}

/** Cancel the keyboard only */
- (void) searchBarCancelButtonClicked:(UISearchBar*)lclSearchBar
{
  [lclSearchBar resignFirstResponder];
}

/** runs a search and sets the text of the searchBar */
- (void) runSearchAndSetSearchBarForString:(NSString*) text
{
  LWE_LOG(@"Should run seach for %@", text);
  [self._searchBar resignFirstResponder];
  self._searchBar.text = text;
  self.searchTerm = text;
  [self runSearchForString:text];
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

- (CGFloat)tableView:(UITableView *)lclTableView heightForRowAtIndexPath:(NSIndexPath*)indexPath
{
  return 64.0f;
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
  UITableViewCell *cell = nil;
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
  
  // Get the headword (or make a new one)
  UILabel *searchResult = (UILabel*)[cell viewWithTag:SEARCH_CELL_HEADWORD];
  if (searchResult == nil) 
  {
    searchResult = [[[UILabel alloc] initWithFrame:CGRectMake(43,3,240,25)] autorelease];  
    searchResult.tag = SEARCH_CELL_HEADWORD;
    searchResult.font = [UIFont boldSystemFontOfSize:18];
    searchResult.lineBreakMode = UILineBreakModeTailTruncation;
    [cell.contentView addSubview:searchResult];
  }
  searchResult.backgroundColor = [UIColor whiteColor];
  searchResult.text = [card headword];
  
  // Now make the button
  UIButton *starButton = (UIButton*)[cell viewWithTag:SEARCH_CELL_BUTTON];
  if (starButton == nil)
  {
    starButton = [[[UIButton alloc] initWithFrame:CGRectMake(7,12,29,39)] autorelease];
    starButton.tag = SEARCH_CELL_BUTTON;
    [starButton addTarget:self action:@selector(_toggleMembership:event:) forControlEvents:UIControlEventTouchUpInside];
    [cell.contentView addSubview:starButton];
  }
  // Now set its state
  if ([self _checkMembershipCacheForCardId:card.cardId])
  {
    [starButton setImage:[UIImage imageNamed:@"star-selected.png"] forState:UIControlStateNormal];
  }
  else
  {
    [starButton setImage:[UIImage imageNamed:@"star-deselected.png"] forState:UIControlStateNormal];
  }
  
  // Get the meaning
  UILabel *meaningLabel = (UILabel*)[cell viewWithTag:SEARCH_CELL_MEANING];
  if (meaningLabel == nil) 
  {
    meaningLabel = [[[UILabel alloc] initWithFrame:CGRectMake(44,41,250,20)] autorelease];
    meaningLabel.tag = SEARCH_CELL_MEANING;
    meaningLabel.font = [UIFont systemFontOfSize:13];
    [cell.contentView addSubview:meaningLabel];
  }
  meaningLabel.text = [card meaningWithoutMarkup];
  
  // And the reading
  UILabel *readingLabel = (UILabel*)[cell viewWithTag:SEARCH_CELL_READING];
  if (readingLabel == nil)
  {
    readingLabel = [[[UILabel alloc] initWithFrame:CGRectMake(43,27,250,16)] autorelease];
    readingLabel.font = [UIFont systemFontOfSize:13];
    readingLabel.textColor = [UIColor grayColor];
    readingLabel.tag = SEARCH_CELL_READING;
    [cell.contentView addSubview:readingLabel];
  }
  readingLabel.text = [card combinedReadingForSettings];

  // Default cell properties
  cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
  cell.selectionStyle = UITableViewCellSelectionStyleGray;
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

#pragma mark -
#pragma mark Private method

/** Checks the membership cache to see if we are in - FYI similar methods are used by AddTagViewController as well */
- (BOOL) _checkMembershipCacheForCardId: (NSInteger)cardId
{
  BOOL returnVal = NO;
  if ([self.membershipCacheArray isKindOfClass:[NSMutableArray class]])
  {
    for (Card *cachedCard in self.membershipCacheArray)
    {
      if (cachedCard.cardId == cardId)
      {
        return YES;
      }
    }
  }
  else
  {
    // Rebuild cache and fail over to manual function
    self.membershipCacheArray = [CardPeer retrieveCardIdsForTagId:FAVORITES_TAG_ID];
    returnVal = [TagPeer checkMembership:cardId tagId:FAVORITES_TAG_ID];
  }
  return returnVal;
}


/** Remove a card from the membership cache */
- (void) _removeCardFromMembershipCache: (NSInteger) cardId
{
  if (self.membershipCacheArray && [self.membershipCacheArray count] > 0)
  {
    for (int i = 0; i < [self.membershipCacheArray count]; i++)
    {
      if ([[self.membershipCacheArray objectAtIndex:i] cardId] == cardId)
      {
        [self.membershipCacheArray removeObjectAtIndex:i];
        return;
      }
    }
  }
}

/**
 * Adds a card to a favorites tag, or removes it, depending on its current
 */
- (void) _toggleMembership:(id)sender event:(id)event
{
  // Get the card ID
  LWE_LOG(@"Toggle");
  NSSet *touches = [event allTouches];
  UITouch *touch = [touches anyObject];
  CGPoint currentTouchPosition = [touch locationInView:self.tableView];
  NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint: currentTouchPosition];
  if (indexPath != nil)
  {
    Card *theCard = [[self _cardSearchArray] objectAtIndex:indexPath.row];
    NSInteger cardId = [theCard cardId];
    
    // Use cache for toggling status if we have it
    BOOL isMember = NO;
    if (self.membershipCacheArray && [self.membershipCacheArray count] > 0)
    {
      isMember = [self _checkMembershipCacheForCardId:cardId];
    }
    else
    {
      isMember = [TagPeer checkMembership:cardId tagId:FAVORITES_TAG_ID];
    }
    
    if (!isMember)
    {
      [TagPeer subscribe:cardId tagId:FAVORITES_TAG_ID];

      // If we are currently studying favorites, add it in there!
      Tag *currentTag = [[CurrentState sharedCurrentState] activeTag];
      if ([currentTag tagId] == FAVORITES_TAG_ID)
      {
        [currentTag addCardToActiveSet:theCard];
      }
      
      // Now add the new ID onto the end of the search cache
      Card *tmpCard = [[Card alloc] init];
      tmpCard.cardId = cardId;
      [self.membershipCacheArray addObject:tmpCard];
      [tmpCard release];
    }
    else
    {
      Tag *currentTag = [[CurrentState sharedCurrentState] activeTag];
      
      // Quick check to make sure it's not the last card
      if (([currentTag tagId] == FAVORITES_TAG_ID) && ([currentTag cardCount] <= 1))
      {
        [LWEUIAlertView notificationAlertWithTitle:NSLocalizedString(@"Last Card in Set",@"AddTagViewController.AlertViewLastCardTitle")
                                           message:NSLocalizedString(@"This set only contains the card you are currently studying.  To delete a set entirely, please change to a different set first.",@"AddTagViewController.AlertViewLastCardMessage")];
      }
      else
      {
        // First of all, do it
        [TagPeer cancelMembership:theCard.cardId tagId:FAVORITES_TAG_ID];
        
        // If we are on starred, remove it from the cache too
        // Also double check that this is not the last card!
        if ([currentTag tagId] == FAVORITES_TAG_ID)
        {
          [currentTag removeCardFromActiveSet:theCard];
        }
      }
      [self _removeCardFromMembershipCache:cardId];
    }

    NSArray *indexPaths = [NSArray arrayWithObject:indexPath];
    [self.tableView reloadRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationNone];
  }
}

#pragma mark -
#pragma mark Class plumbing

//! Standard dealloc
- (void)dealloc
{
  self.searchTerm = nil;
  [self set_searchBar:nil];
  [self set_cardSearchArray:nil];
  [self set_activityIndicator:nil];
  [self set_wordsOrSentencesSegment:nil];
  [super dealloc];
}


@end
