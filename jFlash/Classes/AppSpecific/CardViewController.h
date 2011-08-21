//
//  CardViewController.h
//  jFlash
//
//  Created by シャロット ロス on 5/25/10.
//  Copyright 2010 LONG WEEKEND INC.. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Card.h"

@class CardViewController;

@protocol CardViewControllerDelegate <NSObject>
@optional
- (void)cardViewWillSetup:(CardViewController*)cardViewController;
- (void)cardViewDidSetup:(CardViewController*)cardViewController;
- (void)cardViewWillReveal:(CardViewController*)cardViewController;
- (void)cardViewDidReveal:(CardViewController*)cardViewController;
- (BOOL)cardView:(CardViewController*)cvc shouldReveal:(BOOL)shouldReveal;
@end

@interface CardViewController : UIViewController

- (void) setup;
- (void) reveal;

//we don't retain delegates
@property (assign) IBOutlet id<CardViewControllerDelegate> delegate;
@property (nonatomic, retain) Card *currentCard;

@end