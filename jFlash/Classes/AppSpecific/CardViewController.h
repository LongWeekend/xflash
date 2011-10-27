//
//  CardViewController.h
//  jFlash
//
//  Created by シャロット ロス on 5/25/10.
//  Copyright 2010 LONG WEEKEND INC.. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Card.h"

@class StudyViewController;
@class CardViewController;

@protocol CardViewControllerDelegate <NSObject>
@optional
- (void)studyModeDidChange:(StudyViewController*)svc;
- (void)setupViews:(StudyViewController*)svc;
- (void)refreshSessionDetailsViews:(StudyViewController*)svc;
- (void)cardViewWillSetup:(CardViewController*)cardViewController;
- (void)cardViewDidSetup:(CardViewController*)cardViewController;
- (void)cardViewWillReveal:(CardViewController*)cardViewController;
- (void)cardViewDidReveal:(CardViewController*)cardViewController;
- (BOOL)cardView:(CardViewController*)cvc shouldReveal:(BOOL)shouldReveal;
@end

@interface CardViewController : UIViewController

- (void) setupWithCard:(Card*)card;
- (void) reveal;

// These two methods are more temporary, to pull more browsemode/practice mode stuff out of SVC
- (void) setupViews:(StudyViewController*)svc;
- (void) refreshSessionDetailsViews:(StudyViewController*)svc;
- (void) studyModeDidChange:(StudyViewController*)svc;

@property (assign) IBOutlet id<CardViewControllerDelegate> delegate;
@property (retain) Card *currentCard;

@end