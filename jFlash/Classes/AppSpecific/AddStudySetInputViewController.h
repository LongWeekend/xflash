//
//  AddStudySetInputViewController.h
//  jFlash
//
//  Created by シャロット ロス on 7/2/09.
//  Copyright 2009 LONG WEEKEND INC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Card.h"
#import "Group.h"

@interface AddStudySetInputViewController : UIViewController

extern NSString * const kSetWasAddedOrUpdated;

- (id) initWithDefaultCard:(Card *)card inGroup:(Group *)group;
- (id) initWithTag:(Tag*)aTag;
- (BOOL)isModal;

@property (retain) IBOutlet UITextField *setNameTextfield;
@property (retain) Tag *tag;
@property (retain) Card *defaultCard;
@property (retain) Group *owner;

@end
