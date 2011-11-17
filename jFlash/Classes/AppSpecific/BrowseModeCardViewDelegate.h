//
//  BrowseModeCardViewDelegate.h
//  jFlash
//
//  Created by シャロット ロス on 6/1/10.
//  Copyright 2010 LONG WEEKEND INC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "StudyViewController.h"
#import "ActionBarViewController.h"
#import "CardViewController.h"

@interface BrowseModeCardViewDelegate : NSObject <StudyViewControllerDelegate,
                                                  CardViewControllerDelegate,
                                                  ActionBarViewControllerDelegate>

@end
