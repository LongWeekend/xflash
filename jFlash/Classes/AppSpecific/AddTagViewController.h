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

extern NSString * const LWEActiveTagContentDidChange;

@interface AddTagViewController : UIViewController
{
  IBOutlet UITableView *studySetTable;
  NSInteger _restrictedTagId;
}

- (id) initWithCard:(Card*) card;
- (void) removeFromMembershipCache: (NSInteger) tagId;
- (BOOL) checkMembershipCacheForTagId: (NSInteger)tagId;
- (void) reloadTableData;
- (void) addStudySet;
- (void) restrictMembershipChangeForTagId:(NSInteger) tagId;


@property (nonatomic,retain) NSMutableArray *myTagArray;
@property (nonatomic,retain) NSMutableArray *sysTagArray;
@property (nonatomic,retain) NSMutableArray *membershipCacheArray;
@property (nonatomic,retain) Card *currentCard;
@property (nonatomic) NSInteger cardId;
@property (nonatomic,retain) UITableView *studySetTable;

@end
