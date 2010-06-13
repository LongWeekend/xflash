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

/**
 * Handles dictionary-like search functions inside JFlash
 */
@interface SearchViewController : UITableViewController <UISearchBarDelegate>
{
  NSMutableArray *_cardSearchArray;               //! Contains the returned search results (array of Card objects)
  NSMutableArray *_sentenceSearchArray;           //! Contains the returned search results (array of ExampleSentence objects)
  UISegmentedControl *_targetChooser;             //! Holds the instance of the UISegmentedControl allowing us to choose our data target
  UIActivityIndicatorView *_activityIndicator;    //! Holds the instance to the spinner
  UISearchBar *_searchBar;                        //! Holds the instance to the UISearchBar
  NSInteger _searchTarget;                        //! Specifies which data set to search against - words or example sentences
  BOOL _showSearchTargetControl;                  //! If NO, the "pill" control will not be shown
  BOOL _searchRan;                                //! YES if the user ran a search (reset when they change the text to NO)
  BOOL _deepSearchRan;                            //! YES if the user ran a deep search (reset when they change the text to NO)
}

- (void) runSlowSearch;
- (void) runSearchForString:(NSString*)text isSlowSearch:(BOOL)runSlowSearch;
- (void) changeSearchTarget:(id)sender;
- (void) pluginDidInstall:(NSNotification *)aNotification;
- (void) _addSearchControlToHeader;

// Helper functions for UITableView delegate methods
- (UITableViewCell*) setupTableCell:(UITableViewCell*)cell forCard:(Card*) card;
- (UITableViewCell*) setupTableCell:(UITableViewCell*)cell forSentence:(ExampleSentence*)sentence;

@property (nonatomic, retain) NSMutableArray *_cardSearchArray;
@property (nonatomic, retain) NSMutableArray *_sentenceSearchArray;
@property (nonatomic, retain) UISegmentedControl *_targetChooser;
@property (nonatomic, retain) UIActivityIndicatorView *_activityIndicator;
@property (nonatomic, retain) UISearchBar *_searchBar;

@end
