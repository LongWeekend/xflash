//
//  SearchViewController.h
//  jFlash
//
//  Created by Mark Makdad on 8/2/09.
//  Copyright 2009 LONG WEEKEND INC.. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface SearchViewController : UIViewController <UITableViewDelegate, UITableViewDataSource> {
  IBOutlet UITableView *tableView;
  IBOutlet UISearchBar *searchBar;
  NSMutableArray *searchArray;
  BOOL _searchRan;
  UIActivityIndicatorView *activityIndicator;
}

- (void) runSearch:(BOOL) runSlowSearch;

// convenience method for performSelecterInBackground
- (void) runSlowSearch;

@property (nonatomic, retain) IBOutlet UISearchBar *searchBar;
@property (nonatomic, retain) NSMutableArray *searchArray;
@property (nonatomic, retain) UIActivityIndicatorView *activityIndicator;

@end
