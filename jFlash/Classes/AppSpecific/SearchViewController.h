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
#import "DisplaySearchedSentenceViewController.h"

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
  kSearchHasResults,            //! Any search returned results 
  kSearchHasNoResults,          //! Regular search returned nothing
  kSearchDeepHasNoResults,      //! Deep search returned nothing
} _searchStates;

/**
 * Handles dictionary-like search functions inside JFlash
 */
@interface SearchViewController : UIViewController <UISearchBarDelegate, UITableViewDelegate>
{
  NSMutableArray *_cardSearchArray;               //! Contains the returned search results (array of Card objects)
  NSMutableArray *_sentenceSearchArray;           //! Contains the returned search results (array of ExampleSentence objects)
  UISegmentedControl *_wordsOrSentencesSegment;             //! Holds the instance of the UISegmentedControl allowing us to choose our data target
  UIActivityIndicatorView *_activityIndicator;    //! Holds the instance to the spinner
  UISearchBar *_searchBar;                        //! Holds the instance to the UISearchBar
  NSInteger _searchTarget;                        //! Specifies which data set to search against - words or example sentences
  BOOL _showSearchTargetControl;                  //! If NO, the "pill" control will not be shown
  NSInteger _searchState;                         //! Holds the "state" of the search
  NSMutableArray *_currentResultArray;            //! Holds the current results (switched when the user switches the pill control)
  UITableView *tableView;
}

- (void) runSearchForString:(NSString*)text;
- (void) changeSearchTarget:(id)sender;
- (void) pluginDidInstall:(NSNotification *)aNotification;
- (void) _addSearchControlToHeader;

// Helper functions for UITableView delegate methods
- (UITableViewCell*) setupTableCell:(UITableViewCell*)cell forCard:(Card*) card;
- (UITableViewCell*) setupTableCell:(UITableViewCell*)cell forSentence:(ExampleSentence*)sentence;

@property (nonatomic, retain) NSMutableArray *_cardSearchArray;
@property (nonatomic, retain) NSMutableArray *_sentenceSearchArray;
@property (nonatomic, retain) IBOutlet UISegmentedControl *_wordsOrSentencesSegment;
@property (nonatomic, retain) UIActivityIndicatorView *_activityIndicator;
@property (nonatomic, retain) UISearchBar *_searchBar;
@property (nonatomic, retain) IBOutlet UITableView *tableView;

@end