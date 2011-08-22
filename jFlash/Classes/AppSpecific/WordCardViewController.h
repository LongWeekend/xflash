//
//  WordCardViewController.h
//  jFlash
//
//  Created by シャロット ロス on 6/3/10.
//  Copyright 2010 LONG WEEKEND INC.. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Card.h"
#import "UIWebView+LWENoBounces.h"
#import "ReadingView.h"

@interface WordCardViewController : UIViewController 
{
  // state control
  BOOL readingRevealed;
  BOOL showReadingBtnHiddenByUser;
}

- (IBAction) doToggleReadingBtn;
- (void)setupReadingVisibility;
- (void)layoutCardContentForStudyDirection: (NSString*)studyDirection;
- (void)toggleMoreIconForLabel: (UIView *)theLabel forScrollView:(UIScrollView *)scrollViewContainer;
- (void)updateCardReading:(Card*)card;
- (void)prepareView:(Card*)card;
- (void)hideMeaningWebView:(BOOL)hideMeaningWebView;

@property (nonatomic, retain) IBOutlet UILabel *cardHeadwordLabel;

@property (nonatomic, retain) IBOutlet ReadingView *cardReadingLabel;

@property (nonatomic, retain) IBOutlet UIButton *toggleReadingBtn;
@property (nonatomic, retain) IBOutlet UIScrollView *cardReadingLabelScrollContainer;
@property (nonatomic, retain) IBOutlet UIScrollView *cardHeadwordLabelScrollContainer;
@property (nonatomic, retain) IBOutlet UIImageView *cardReadingLabelScrollMoreIcon;
@property (nonatomic, retain) IBOutlet UIImageView *cardHeadwordLabelScrollMoreIcon;
@property (nonatomic, retain) IBOutlet UIWebView *meaningWebView;

//! Holds a reference to the current meaning's string-replacement javascript
@property (nonatomic, retain) NSString *_tmpJavascript;

// Tracking XIB Layout Coordinates
// I think these should go away
@property NSInteger cardReadingLabelScrollContainerYPosInXib;
@property NSInteger cardHeadwordLabelHeightInXib;
@property NSInteger toggleReadingBtnYPosInXib;
@property NSInteger cardHeadwordLabelYPosInXib;

@property BOOL readingVisible;
@property BOOL meaningRevealed;
@end
