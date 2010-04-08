//
//  AddTagViewController.h
//  jFlash
//
//  Created by Mark Makdad on 6/28/09.
//  Copyright 2009 LONG WEEKEND LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AddStudySetInputViewController.h"
#import "TagPeer.h"

#define FONT_SIZE 14.0f
#define CELL_CONTENT_WIDTH 320.0f
#define CELL_CONTENT_MARGIN 10.0f

@interface AddTagViewController : UIViewController {
  IBOutlet UITableView *studySetTable;
  IBOutlet UISearchBar *searchBar;
  NSMutableArray *myTagArray;
  NSMutableArray *sysTagArray;
  NSMutableArray *membershipCacheArray;
  NSInteger cardId;
  Card* currentCard;
}

- (void) removeFromMembershipCache: (NSInteger) tagId;
- (BOOL) checkMembershipCacheForTagId: (NSInteger)tagId;
- (void) reloadTableData;
- (void) addStudySet:sender;

@property (nonatomic,retain) NSMutableArray *myTagArray;
@property (nonatomic,retain) NSMutableArray *sysTagArray;
@property (nonatomic,retain) NSMutableArray *membershipCacheArray;
@property (nonatomic,retain) Card *currentCard;
@property (nonatomic) NSInteger cardId;

@end
