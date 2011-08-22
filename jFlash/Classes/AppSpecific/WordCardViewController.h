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
  //! Holds a reference to the current meaning's string-replacement javascript
  NSString *_tmpJavascript;
}

- (IBAction) doToggleReadingBtn;
- (void)resetReadingVisibility;
- (void)toggleMoreIconForLabel: (UIView *)theLabel forScrollView:(UIScrollView *)scrollViewContainer;
- (void)prepareView:(Card*)card;
- (void)hideMeaningWebView:(BOOL)hideMeaningWebView;

- (void) turnReadingOn;
- (void) turnReadingOff;

@property (nonatomic, retain) IBOutlet UILabel *cardHeadwordLabel;
@property (nonatomic, retain) IBOutlet ReadingView *cardReadingLabel;
@property (nonatomic, retain) IBOutlet UIButton *toggleReadingBtn;

@property (nonatomic, retain) IBOutlet UIScrollView *cardReadingLabelScrollContainer;
@property (nonatomic, retain) IBOutlet UIScrollView *cardHeadwordLabelScrollContainer;
@property (nonatomic, retain) IBOutlet UIImageView *cardReadingLabelScrollMoreIcon;
@property (nonatomic, retain) IBOutlet UIImageView *cardHeadwordLabelScrollMoreIcon;

@property (nonatomic, retain) IBOutlet UIWebView *meaningWebView;

@property BOOL readingVisible;
@property BOOL meaningRevealed;
@end
