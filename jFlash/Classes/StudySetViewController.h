//
//  StudySetViewController.h
//  jFlash
//
//  Created by Paul Chapman on 6/26/09.
//  Copyright 2009 LONG WEEKEND INC. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "Group.h"
#import "TagPeer.h"
#import "GroupPeer.h"

@interface StudySetViewController : UITableViewController <UISearchBarDelegate>
{
  Group *group;
  NSMutableArray *tagArray;
  NSMutableArray *subgroupArray;
  UIBarButtonItem *addButton;
  UIAlertView *statusMsgBox;
  NSInteger selectedTagId;
  NSInteger groupId;
  UIActivityIndicatorView *activityIndicator;
	UISearchBar *searchBar;
  UIButton *searchOverlayBtn;
  UIView *searchOverlay;
	BOOL searching;
}

- (void) changeStudySet;
- (void) reloadTableData;
- (void) reloadSubgroupData;
- (void) doDoneSearching:(id)sender;
- (void) hideSearchBar;
- (void) popToRoot;

@property NSInteger selectedTagId;
@property NSInteger groupId;
@property (nonatomic, retain) Group *group;
@property (nonatomic, retain) UIAlertView *statusMsgBox;
@property (nonatomic, retain) NSMutableArray *tagArray;
@property (nonatomic, retain) NSMutableArray *subgroupArray;
@property (nonatomic, retain) UISearchBar *searchBar;
@property (nonatomic, retain) UIActivityIndicatorView *activityIndicator;

@end