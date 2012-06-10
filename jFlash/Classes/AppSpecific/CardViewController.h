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
#import "MoodIcon.h"
#import "StudyViewProtocols.h"

// These strings define the HTML that expresses how the card's meeting will be 
// displayed in each study direction.
extern NSString * const LWECardHTMLTemplate;
extern NSString * const LWECardHTMLTemplate_EtoJ;

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

@interface CardViewController : UIViewController <StudyViewSubcontrollerProtocol>
{
  //! Holds a reference to the current meaning's string-replacement javascript
  NSString *_tmpJavascript;
}

//! Designated initializer.  Passing "NO" to displayMainHeadword shows alt headword (e.g. English)
- (id) initDisplayMainHeadword:(BOOL)displayMainHeadword;

- (IBAction) doToggleReadingBtn;

//! Use when you want to show the reading (w/o persisting that state)
- (void) turnReadingOn;

//! Use when you want to stop the reading from showing (w/o persisting that state)
- (void) turnReadingOff;

//! Whatever the value of readingVisible is, this will reset it to that state.
- (void) resetReadingVisibility;

//! Implement this delegate to control how the card is displayed in a mode.
@property (assign) IBOutlet id<CardViewControllerDelegate> delegate;

//! Our little guy.
@property (nonatomic, retain) IBOutlet MoodIcon *moodIcon;

//! The label holding the reading for this card
@property (nonatomic, retain) IBOutlet UILabel *readingLabel;

//! If yes, the reading is visible.  Separate variable than label.hidden because we preserve state across cards.
@property BOOL readingVisible;

//! Toggles the visibility of the reading off and on.  Will persist state to readingVisible
@property (nonatomic, retain) IBOutlet UIButton *toggleReadingBtn;

//! Scroll view containing the reading label.  If the reading doesn't fit, we can scroll it.
@property (nonatomic, retain) IBOutlet UIScrollView *readingScrollContainer;

//! If the reading is scrollable, the "more icon" will show to help the user understand
@property (nonatomic, retain) IBOutlet UIImageView *readingMoreIcon;

//! The label holding the card's main headword
@property (nonatomic, retain) IBOutlet UILabel *headwordLabel;

//! Scroll view containing the headword label.  If the headword doesn't fit, we can scroll it.
@property (nonatomic, retain) IBOutlet UIScrollView *headwordScrollContainer;

//! If the headword is scrollable, the "more icon" will show to help the user understand
@property (nonatomic, retain) IBOutlet UIImageView *headwordMoreIcon;

//! Web view that renders the meaning HTML
@property (nonatomic, retain) IBOutlet UIWebView *meaningWebView;

@property (nonatomic, retain) NSString *baseHtml;
@end
