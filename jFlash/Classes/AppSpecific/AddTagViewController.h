//
//  AddTagViewController.h
//  jFlash
//
//  Created by Mark Makdad on 6/28/09.
//  Copyright 2009 LONG WEEKEND LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Card.h"


@interface AddTagViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>

- (id) initWithCard:(Card*) card;
- (IBAction) addStudySet;

@property (retain) IBOutlet UITableView *studySetTable;

@property (retain) NSArray *myTagArray;
@property (retain) NSArray *sysTagArray;
@property (retain) Card *currentCard;

@end
