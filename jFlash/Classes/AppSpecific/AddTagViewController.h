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

// TODO: really?  needs a better name, probably in a better place, with a better description/comment
#define FONT_SIZE 14

@interface AddTagViewController : UIViewController

- (id) initWithCard:(Card*) card;
- (IBAction) addStudySet;

@property (retain) IBOutlet UITableView *studySetTable;

@property (retain) NSArray *myTagArray;
@property (retain) NSArray *sysTagArray;
@property (retain) Card *currentCard;

@end
