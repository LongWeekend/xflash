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
#import "MoodIconView.h"
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

- (IBAction) doToggleReadingBtn;

- (void) turnReadingOn;
- (void) turnReadingOff;

- (void) resetReadingVisibility;

- (void) setMeaningWebViewHidden:(BOOL)shouldHide;


@property (assign) IBOutlet id<CardViewControllerDelegate> delegate;

@property BOOL readingVisible;

@property (nonatomic, retain) NSString *baseHtml;

@property (nonatomic, retain) IBOutlet UILabel *cardHeadwordLabel;
@property (nonatomic, retain) IBOutlet UILabel *cardReadingLabel;
@property (nonatomic, retain) IBOutlet UIButton *toggleReadingBtn;

@property (nonatomic, retain) IBOutlet UIScrollView *cardReadingLabelScrollContainer;
@property (nonatomic, retain) IBOutlet UIScrollView *cardHeadwordLabelScrollContainer;
@property (nonatomic, retain) IBOutlet UIImageView *cardReadingLabelScrollMoreIcon;
@property (nonatomic, retain) IBOutlet UIImageView *cardHeadwordLabelScrollMoreIcon;

@property (nonatomic, retain) IBOutlet UIWebView *meaningWebView;
@property (nonatomic, retain) IBOutlet MoodIconView *moodIcon;

@end
