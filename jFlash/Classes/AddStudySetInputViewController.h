//
//  AddStudySetInputViewController.h
//  jFlash
//
//  Created by シャロット ロス on 7/2/09.
//  Copyright 2009 LONG WEEKEND INC. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface AddStudySetInputViewController : UIViewController
{
  IBOutlet UITextField *setNameTextfield;
  NSInteger defaultCardId;
  NSInteger ownerId;
}

@property NSInteger ownerId;
@property NSInteger defaultCardId;
@property (nonatomic,retain) UITextField *setNameTextfield;
@end
