//
//  SearchViewController.h
//  jFlash
//
//  Created by Mark Makdad on 8/2/09.
//  Copyright 2009 LONG WEEKEND INC.. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CardPeer.h"
#import "ExampleSentencePeer.h"
#import "AddTagViewController.h"
// MMA: we're not using this yet, as of 1.3.1
//#import "DisplaySearchedSentenceViewController.h"

#define SEARCH_TARGET_WORDS 0
#define SEARCH_TARGET_EXAMPLE_SENTENCES 1

// View tags for the custom table view cells
#define SEARCH_CELL_HEADWORD 200
#define SEARCH_CELL_READING 201
#define SEARCH_CELL_MEANING 202
#define SEARCH_CELL_BUTTON 203

//! State machine for searching
typedef enum searchStates
{
  kSearchNoSearch,              //! Default state when not searching
  kSearchSearching,             //! When a search is active but nothing is happening yet
  kSearchHasResults,            //! Any search returned results 
  kSearchHasNoResults,          //! Regular search returned nothing
} LWEFlashSearchStates;

/**
 * Handles dictionary-like search functions inside JFlash
 */
@interface SearchViewController : UITableViewController <UISearchBarDelegate>
{
  NSInteger _searchTarget;                        //! Specifies which data set to search against - words or example sentences
  LWEFlashSearchStates _searchState;              //! Holds the "state" of the search
  BOOL _showSearchTargetControl;                  //! If NO, the "pill" control will not be shown
  NSArray *_currentResultArray;                   //! Holds the current results (switched when the user switches the pill control)
}

- (IBAction) changeSearchTarget:(id)sender;
- (void) runSearchAndSetSearchBarForString:(NSString*)text;
- (void) runSearchForString:(NSString*)text;
- (void) receivedSearchResults:(NSArray *)results;
- (void) pluginDidInstall:(NSNotification *)aNotification;

//! Contains the returned search results (array of ExampleSentence objects)
@property (nonatomic, retain) NSString *searchTerm; // used to tell viewDidLoad to set the search boxes text

// UIView-related properties
@property (nonatomic, retain) IBOutlet UITableViewCell *searchingCell;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (nonatomic, retain) IBOutlet UISearchBar *searchBar;

@end