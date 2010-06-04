//
//  PracticeModeCardViewDelegate.h
//  jFlash
//
//  Created by シャロット ロス on 6/1/10.
//  Copyright 2010 LONG WEEKEND INC.. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CardViewController.h"
#import "WordCardViewController.h"
#import "ActionBarViewController.h"

@interface PracticeModeCardViewDelegate : NSObject {
  id cardViewController;
}

@property (nonatomic, retain) id cardViewController;

@end
