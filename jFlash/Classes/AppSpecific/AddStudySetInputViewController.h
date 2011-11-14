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

extern NSString* const kSetWasAddedOrUpdated;

- (id) initWithDefaultCard:(Card*)card groupOwnerId:(NSInteger)groupOwnerId;
- (id) initWithTag:(Tag*)aTag;
- (BOOL)isModal;

@property (retain) IBOutlet UITextField *setNameTextfield;
@property (retain) IBOutlet UITextView *setDescriptionTextView;
@property (retain) Tag* tag;
@property (retain) Card *defaultCard;
@property NSInteger ownerId;

@end
