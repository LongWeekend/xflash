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

#import "ChineseCard.h"

#define FONT_SIZE 14

@interface AddTagViewController : UIViewController
{
  NSInteger _restrictedTagId;
}

- (id) initWithCard:(Card*) card;
- (void) removeFromMembershipCache:(NSInteger)tagId;
- (BOOL) checkMembershipCacheForTagId:(NSInteger)tagId;
- (void) reloadTableData;
- (void) addStudySet;
- (void) restrictMembershipChangeForTagId:(NSInteger) tagId;

@property (retain) IBOutlet UITableView *studySetTable;

@property (retain) NSArray *myTagArray;
@property (retain) NSArray *sysTagArray;
@property (retain) Card *currentCard;
@property NSInteger cardId;

@end
