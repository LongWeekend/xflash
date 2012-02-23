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
#import "DownloadManager.h"
#import "PluginManager.h"
#import "ExternalAppManager.h"

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

@class ExternalAppManager;

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

- (IBAction) returnToExternalApp:(id)sender;

//! Calls "runSearchForString" after programmatically populating the search bar w/ text - used for Rikai
- (void) runSearchAndSetSearchBarForString:(NSString*)text;

//! Call to search the database & populate the table w/ results
- (void) runSearchForString:(NSString*)text;

//! Callback from the above runSearchForString: async call
- (void) receivedSearchResults:(NSArray *)results;

//! Contains the returned search results (array of ExampleSentence objects)
@property (nonatomic, retain) NSString *searchTerm; // used to tell viewDidLoad to set the search boxes text

// UIView-related properties
@property (nonatomic, retain) IBOutlet UITableViewCell *searchingCell;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (nonatomic, retain) IBOutlet UISearchBar *searchBar;

//! The view to show in the header when the user comes from an external app
@property (nonatomic, retain) IBOutlet UIView *returnToExternalAppView;
@property (nonatomic, retain) IBOutlet UIButton *externalAppBtn;

@property (nonatomic, retain) IBOutlet PluginManager *pluginManager;

@property (nonatomic, retain) IBOutlet ExternalAppManager *externalAppManager;

@end