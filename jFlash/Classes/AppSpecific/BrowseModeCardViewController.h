//
//  BrowseModeCardViewDelegate.h
//  jFlash
//
//  Created by シャロット ロス on 6/1/10.
//  Copyright 2010 LONG WEEKEND INC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WordCardViewController.h"

#import "ActionBarViewController.h"
#import "CardViewController.h"

@interface BrowseModeCardViewController : UIViewController <CardViewControllerDelegate, ActionBarViewControllerDelegate>

@property (nonatomic, retain) WordCardViewController *wordCardViewController;

@end
