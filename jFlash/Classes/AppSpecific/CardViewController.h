//
//  CardViewController.h
//  jFlash
//
//  Created by シャロット ロス on 5/25/10.
//  Copyright 2010 LONG WEEKEND INC.. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Card.h"

@interface CardViewController : UIViewController {
  IBOutlet id delegate;  
  Card *currentCard;
}

- (void) setup;
- (void) reveal;

//we don't retain delegates
@property (assign, nonatomic, readwrite) IBOutlet id delegate;
@property (nonatomic, retain) Card *currentCard;

@end

//! Notification names
extern NSString  *meaningWebViewWillDisplayNotification;
extern NSString  *meaningWebViewDidDisplayNotification;
extern NSString  *cardViewWillSetupNotification;
extern NSString  *cardViewDidSetupNotification;
extern NSString  *cardViewWillRevealNotification;
extern NSString  *cardViewDidRevealNotification;