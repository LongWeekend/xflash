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
#import "OHAttributedLabel.h"
#import "MoodIcon.h"

extern NSString * const LWECardHtmlHeader;
extern NSString * const LWECardHtmlHeader_EtoJ;
extern NSString * const LWECardHtmlFooter;

@interface WordCardViewController : UIViewController 
{
  //! Holds a reference to the current meaning's string-replacement javascript
  NSString *_tmpJavascript;
}

- (id) initDisplayMainHeadword:(BOOL)displayMainHeadword;

- (IBAction)doTogglePercentCorrectBtn;
- (void) turnPercentCorrectOff;
- (void) turnPercentCorrectOn;

- (void)toggleMoreIconForLabel: (UIView *)theLabel forScrollView:(UIScrollView *)scrollViewContainer;
- (void)prepareView:(Card*)card;
- (void)hideMeaningWebView:(BOOL)hideMeaningWebView;

- (void) turnReadingOn;
- (void) turnReadingOff;
- (void)resetReadingVisibility;
- (IBAction) doToggleReadingBtn;

@property (nonatomic, retain) NSString *baseHtml;

@property (nonatomic, retain) IBOutlet UILabel *cardHeadwordLabel;
@property (nonatomic, retain) IBOutlet UILabel *cardReadingLabel;
@property (nonatomic, retain) IBOutlet UIButton *toggleReadingBtn;

@property (nonatomic, retain) IBOutlet UIScrollView *cardReadingLabelScrollContainer;
@property (nonatomic, retain) IBOutlet UIScrollView *cardHeadwordLabelScrollContainer;
@property (nonatomic, retain) IBOutlet UIImageView *cardReadingLabelScrollMoreIcon;
@property (nonatomic, retain) IBOutlet UIImageView *cardHeadwordLabelScrollMoreIcon;

@property (nonatomic, retain) IBOutlet UIWebView *meaningWebView;

// Mood Icon
@property (nonatomic, retain) IBOutlet UIImageView *percentCorrectTalkBubble;
@property (nonatomic, retain) IBOutlet UILabel *percentCorrectLabel;
@property (nonatomic, retain) IBOutlet UIButton *moodIconBtn;
@property (nonatomic, retain) MoodIcon *moodIcon;
@property (nonatomic, retain) IBOutlet UIImageView *hhAnimationView;

@property BOOL readingVisible;
@end
