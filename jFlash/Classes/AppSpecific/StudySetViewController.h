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

#define SECTION_TAG 1
#define SECTION_GROUP 0

@interface StudySetViewController : UITableViewController <UITableViewDelegate, UISearchBarDelegate>
{
  Group *group;
  NSMutableArray *tagArray;
  NSMutableArray *subgroupArray;
  UIBarButtonItem *_addButton;
  UIAlertView *statusMsgBox;
  NSInteger selectedTagId;
  NSInteger groupId;
  UIActivityIndicatorView *activityIndicator;
	UISearchBar *searchBar;
  UIButton *searchOverlayBtn;
  UIView *_searchOverlay;
	BOOL searching;
}

- (void) changeStudySet: (Tag*) tag;
- (void) reloadTableData;
- (void) reloadSubgroupData;
- (void) doDoneSearching;
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