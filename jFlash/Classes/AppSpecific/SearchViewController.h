//
//  SearchViewController.h
//  jFlash
//
//  Created by Mark Makdad on 8/2/09.
//  Copyright 2009 LONG WEEKEND INC.. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface SearchViewController : UITableViewController <UISearchBarDelegate, UIAlertViewDelegate>
{
  UISearchBar *searchBar;
  NSMutableArray *searchArray;
  UIActivityIndicatorView *activityIndicator;
  BOOL _searchRan;
  BOOL _deepSearchRan;
}

- (void) runSearch:(BOOL) runSlowSearch;

// convenience method for performSelecterInBackground
- (void) runSlowSearch;

@property (nonatomic, retain) UISearchBar *searchBar;
@property (nonatomic, retain) NSMutableArray *searchArray;
@property (nonatomic, retain) UIActivityIndicatorView *activityIndicator;

@end
