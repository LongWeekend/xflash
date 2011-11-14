//
//  PracticeModeCardViewDelegate.h
//  jFlash
//
//  Created by シャロット ロス on 6/1/10.
//  Copyright 2010 LONG WEEKEND INC.. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "StudyViewController.h"
#import "CardViewController.h"
#import "ActionBarViewController.h"

@interface PracticeModeCardViewDelegate : NSObject <StudyViewControllerDelegate,
                                                    CardViewControllerDelegate,
                                                    ActionBarViewControllerDelegate>

@property CGFloat currentPercentageCorrect;

@end
