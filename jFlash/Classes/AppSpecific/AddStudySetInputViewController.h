//
//  AddStudySetInputViewController.h
//  jFlash
//
//  Created by シャロット ロス on 7/2/09.
//  Copyright 2009 LONG WEEKEND INC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Card.h"

@interface AddStudySetInputViewController : UIViewController

- (id) initWithDefaultCard:(Card*)card groupOwnerId:(NSInteger)groupOwnerId;

@property (nonatomic, retain) IBOutlet UITextField *setNameTextfield;

@property NSInteger ownerId;
@property (retain) Card *defaultCard;
@end
