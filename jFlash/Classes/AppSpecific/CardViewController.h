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
#import "StudyViewProtocols.h"

extern NSString * const LWECardHtmlHeader;
extern NSString * const LWECardHtmlHeader_EtoJ;
extern NSString * const LWECardHtmlFooter;

@class CardViewController;

@protocol CardViewControllerDelegate <NSObject>
@optional
- (void) cardViewDidChangeMode:(CardViewController*)cardViewController;
- (void)cardViewWillSetup:(CardViewController*)cardViewController;
- (void)cardViewDidSetup:(CardViewController*)cardViewController;
- (void)cardViewWillReveal:(CardViewController*)cardViewController;
- (void)cardViewDidReveal:(CardViewController*)cardViewController;
- (BOOL)shouldRevealCardView:(CardViewController*)cvc;
@end

@interface CardViewController : UIViewController <StudyViewSubcontrollerDelegate>
{
  //! Holds a reference to the current meaning's string-replacement javascript
  NSString *_tmpJavascript;
}

- (id) initDisplayMainHeadword:(BOOL)displayMainHeadword;

- (IBAction)doTogglePercentCorrectBtn;
- (IBAction) doToggleReadingBtn;

- (void) turnPercentCorrectOff;
- (void) turnPercentCorrectOn;
- (void) turnReadingOn;
- (void) turnReadingOff;

- (void)resetReadingVisibility;

- (void) setMeaningWebViewHidden:(BOOL)hideMeaningWebView;


@property (assign) IBOutlet id<CardViewControllerDelegate> delegate;

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
