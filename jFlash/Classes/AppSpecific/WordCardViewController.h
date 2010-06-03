//
//  WordCardViewController.h
//  jFlash
//
//  Created by シャロット ロス on 6/3/10.
//  Copyright 2010 LONG WEEKEND INC.. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Card.h"

@interface WordCardViewController : UIViewController 
{
  IBOutlet UILabel *cardHeadwordLabel;
  IBOutlet UILabel *cardReadingLabel;
  IBOutlet UIButton *toggleReadingBtn;
  IBOutlet UIScrollView *cardReadingLabelScrollContainer;
  IBOutlet UIScrollView *cardHeadwordLabelScrollContainer;
  IBOutlet UIImageView *cardReadingLabelScrollMoreIcon;
  IBOutlet UIImageView *cardHeadwordLabelScrollMoreIcon;
  IBOutlet UIWebView *meaningWebView;
  
  // Tracking XIB Layout Coordinates
  // I think these should go away
  NSInteger cardReadingLabelScrollContainerYPosInXib;
  NSInteger cardHeadwordLabelHeightInXib;
  NSInteger toggleReadingBtnYPosInXib;
  NSInteger cardHeadwordLabelYPosInXib;
  
  // state control
  BOOL readingRevealed;
  BOOL showReadingBtnHiddenByUser;
  BOOL readingVisible;
  BOOL meaningRevealed;
}

- (IBAction) doToggleReadingBtn;
- (void)hideShowReadingBtn;
- (void)displayShowReadingBtn;
- (void)setupReadingVisibility;
- (void)layoutCardContentForStudyDirection: (NSString*)studyDirection;
- (void)toggleMoreIconForLabel: (UILabel *)theLabel forScrollView:(UIScrollView *)scrollViewContainer;
- (void)updateCardReading:(Card*)card;
- (void)prepareView:(Card*)card;
- (void)hideMeaningWebView:(BOOL)hideMeaningWebView;

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

@property BOOL readingVisible;
@property BOOL meaningRevealed;
@end
