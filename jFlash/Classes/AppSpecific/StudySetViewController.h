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
#import <MessageUI/MFMailComposeViewController.h>
#import "BackupManager.h"
#import "DSActivityView.h"

@interface StudySetViewController : UITableViewController <UITableViewDelegate, UISearchBarDelegate, MFMailComposeViewControllerDelegate, BackupManagerDelegate>
{
  UIBarButtonItem *_addButton;
  UIButton *searchOverlayBtn;
  UIView *_searchOverlay;
	BOOL searching;
}

- (void) changeStudySet: (Tag*) tag;
- (void) reloadTableData;
- (void) reloadSubgroupData;
- (void) doDoneSearching;
- (void) hideSearchBar;

@property NSInteger selectedTagId;
@property NSInteger groupId;
@property (nonatomic, retain) Group *group;
@property (nonatomic, retain) NSMutableArray *tagArray;
@property (nonatomic, retain) NSArray *subgroupArray;
@property (nonatomic, retain) UISearchBar *searchBar;
@property (nonatomic, retain) UIActivityIndicatorView *activityIndicator;
@property (retain) BackupManager *backupManager;
@property (retain) DSActivityView *activityView;

@end