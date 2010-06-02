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
  IBOutlet UILabel *cardHeadwordLabel;
  IBOutlet UILabel *cardReadingLabel;
  IBOutlet UIButton *toggleReadingBtn;
  IBOutlet UIButton *cardMeaningBtn;
  IBOutlet UIScrollView *cardReadingLabelScrollContainer;
  IBOutlet UIScrollView *cardHeadwordLabelScrollContainer;
  IBOutlet UIImageView *cardReadingLabelScrollMoreIcon;
  IBOutlet UIImageView *cardHeadwordLabelScrollMoreIcon;
  IBOutlet UIWebView *meaningWebView;
  
  // Tracking XIB Layout Coordinates
  // I think these will go away
  NSInteger cardReadingLabelScrollContainerYPosInXib;
  NSInteger cardHeadwordLabelHeightInXib;
  NSInteger toggleReadingBtnYPosInXib;
  NSInteger cardHeadwordLabelYPosInXib;

  Card *currentCard;
  
  // state control
  BOOL readingRevealed;
  BOOL showReadingBtnHiddenByUser;
  BOOL isBrowseMode;
  BOOL readingVisible;
  BOOL meaningRevealed;
}

- (IBAction) doToggleReadingBtn;
- (void)hideShowReadingBtn;
- (void)displayShowReadingBtn;
- (void)setupReadingVisibility;
- (void)layoutCardContentForStudyDirection: (NSString*)studyDirection;
- (void)toggleMoreIconForLabel: (UILabel *)theLabel forScrollView:(UIScrollView *)scrollViewContainer;
- (void)updateCardReading;
- (void)prepareView;
- (void)displayMeaningWebView;

//we don't retain delegates
@property (assign, nonatomic, readwrite) IBOutlet id delegate;

@property (nonatomic, retain) UILabel *cardHeadwordLabel;
@property (nonatomic, retain) UILabel *cardReadingLabel;
@property (nonatomic, retain) UIButton *toggleReadingBtn;
@property (nonatomic, retain) UIScrollView *cardReadingLabelScrollContainer;
@property (nonatomic, retain) UIScrollView *cardHeadwordLabelScrollContainer;
@property (nonatomic, retain) UIWebView *meaningWebView;
@property (nonatomic, retain) UIImageView *cardHeadwordLabelScrollMoreIcon;
@property (nonatomic, retain) UIImageView *cardReadingLabelScrollMoreIcon;

@property NSInteger cardReadingLabelScrollContainerYPosInXib;
@property NSInteger cardHeadwordLabelHeightInXib;
@property NSInteger toggleReadingBtnYPosInXib;
@property NSInteger cardHeadwordLabelYPosInXib;

//
@property BOOL isBrowseMode;
@property BOOL readingVisible;
@property BOOL meaningRevealed;

@property (nonatomic, retain) Card *currentCard;

@end

//! Notification names
extern NSString  *meaningWebViewWillDisplayNotification;
extern NSString  *meaningWebViewDidDisplayNotification;
extern NSString  *cardViewWillSetupNotification;
extern NSString  *cardViewDidSetupNotification;