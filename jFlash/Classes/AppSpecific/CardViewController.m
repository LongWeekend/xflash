//
//  CardViewController.m
//  jFlash
//
//  Created by シャロット ロス on 5/25/10.
//  Copyright 2010 LONG WEEKEND INC.. All rights reserved.
//

#import "CardViewController.h"

//! Informal protocol defined messages sent to delegate
@interface NSObject (CardViewDelegateSupport)

- (void)meaningWebViewDidDisplay:(NSNotification *)aNotification;
- (void)meaningWebViewWillDisplay:(NSNotification *)aNotification;
- (BOOL)meaningWebView:(id)meaningWebView shouldHide:(BOOL)displayMeaning;
- (void)cardViewWillSetup:(NSNotification *)aNotification;
- (void)cardViewDidSetup:(NSNotification *)aNotification;

@end

@implementation CardViewController
@synthesize delegate, currentCard, toggleReadingBtn;
@synthesize meaningWebView, cardHeadwordLabelScrollMoreIcon, cardHeadwordLabel, cardReadingLabelScrollMoreIcon, cardReadingLabel;
@synthesize cardReadingLabelScrollContainerYPosInXib, cardHeadwordLabelHeightInXib, toggleReadingBtnYPosInXib, cardHeadwordLabelYPosInXib;
@synthesize cardReadingLabelScrollContainer, cardHeadwordLabelScrollContainer, isBrowseMode, readingVisible, meaningRevealed;

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
  
  // Get values from XIB on first load
  CGRect tmpFrame;
  tmpFrame = cardReadingLabelScrollContainer.frame;
  cardReadingLabelScrollContainerYPosInXib = tmpFrame.origin.y;
  tmpFrame = cardHeadwordLabel.frame;
  cardHeadwordLabelHeightInXib = tmpFrame.size.height;
  tmpFrame = toggleReadingBtn.frame;
  toggleReadingBtnYPosInXib = tmpFrame.origin.y;
  tmpFrame = cardHeadwordLabelScrollContainer.frame;
  cardHeadwordLabelYPosInXib = tmpFrame.origin.y;  
  
  // default the reading to hidden
  [[self cardReadingLabel] setHidden: YES];
}

#pragma mark Delegate Methods

- (void)_cardViewWillSetup
{
  NSNotification *notification = [NSNotification notificationWithName: cardViewWillSetupNotification object:self];
  
  // send the selector to the delegate if it responds
  if([[self delegate] respondsToSelector:@selector(cardViewWillSetup:)])
  {
    [[self delegate] cardViewWillSetup:notification];
  }
  
  //in case something else cares.  Seems to be the pattern from the book but I don't know if we really need this
  [[NSNotificationCenter defaultCenter] postNotification:notification];
}

- (void)_cardViewDidSetup
{
  NSNotification *notification = [NSNotification notificationWithName: cardViewDidSetupNotification object:self];
  
  // send the selector to the delegate if it responds
  if([[self delegate] respondsToSelector:@selector(cardViewDidSetup:)])
  {
    [[self delegate] cardViewDidSetup:notification];
  }
  
  //in case something else cares.  Seems to be the pattern from the book but I don't know if we really need this
  [[NSNotificationCenter defaultCenter] postNotification:notification];
}

- (void)_meaningWebViewWillDisplay
{
  NSNotification *notification = [NSNotification notificationWithName: meaningWebViewWillDisplayNotification object:self];
  
  // send the selector to the delegate if it responds
  if([[self delegate] respondsToSelector:@selector(meaningWebViewWillDisplay:)])
  {
    [[self delegate] meaningWebViewWillDisplay:notification];
  }
  
  //in case something else cares.  Seems to be the pattern from the book but I don't know if we really need this
  [[NSNotificationCenter defaultCenter] postNotification:notification];
}

- (void)_meaningWebViewDidDisplay
{
  // we created this name previously
  NSNotification *notification = [NSNotification notificationWithName: meaningWebViewDidDisplayNotification object:self];
  
  // send the selector to the delegate if it responds
  if([[self delegate] respondsToSelector:@selector(meaningWebViewDidDisplay:)])
  {
    [[self delegate] meaningWebViewDidDisplay:notification];
  }
  
  //in case something else cares.  Seems to be the pattern from the book but I don't know if we really need this
  [[NSNotificationCenter defaultCenter] postNotification:notification];
}

//Give the delegate a chance to change the display
- (BOOL)_meaningWebViewShouldBeHidden:(BOOL)hideMeaning
{
  if([[self delegate] respondsToSelector:@selector(meaningWebView:shouldHide:)])
  {
    hideMeaning = [[self delegate] meaningWebView:self shouldHide:hideMeaning];
  }
  
  return hideMeaning;
}

#pragma mark Reading Label Methods

- (void) hideShowReadingBtn
{
  [toggleReadingBtn setBackgroundImage:NULL forState:UIControlStateNormal];
}

- (void) displayShowReadingBtn
{
  [toggleReadingBtn setBackgroundImage:[UIImage imageNamed:@"practice-btn-showreading.png"] forState:UIControlStateNormal];
}

//! shows or hides the reading label and toggleButton according to the readingVisible bool
- (void) setupReadingVisibility {
  if ([self readingVisible])
  { 
    [cardReadingLabelScrollContainer setHidden:NO];
    [cardReadingLabel setHidden:NO];
    [self hideShowReadingBtn];
  }
  else
  {
    [cardReadingLabelScrollContainer setHidden:YES];
    [cardReadingLabel setHidden:YES];
    [self displayShowReadingBtn];
  }

}

//! toggles the readingVisible bool and calls setupReadingVisibility
- (IBAction) doToggleReadingBtn
{
  if ([self readingVisible])
  {
    [self setReadingVisible: NO];
  }
  else
  {
    [self setReadingVisible: YES];
  }
  [self setupReadingVisibility];
}

#pragma mark layout methods

- (void) layoutCardContentForStudyDirection: (NSString*)studyDirection
{
  
  // Y-Positions for J_TO_E Mode
  // NB: with UIScrollView objects you have to add the height of itself to it's y-position
  int readingY    = cardReadingLabelScrollContainerYPosInXib;
  int readingBtnY = toggleReadingBtnYPosInXib;
  int headwordY   = cardHeadwordLabelYPosInXib;
  
  // Text format options for J_TO_E Mode
  UIFont  *readingFont  = [UIFont boldSystemFontOfSize:READING_DEF_FONTSIZE];
  UIColor *readingColor = [UIColor whiteColor];
  
  CGRect readingFrame = cardReadingLabelScrollContainer.frame;
  CGRect headwordFrame = cardHeadwordLabelScrollContainer.frame;
  CGRect readingBtnFrame = toggleReadingBtn.frame;
  CGRect readingScrollMoreFrame = cardReadingLabelScrollMoreIcon.frame;
  CGRect headwordScrollMoreFrame = cardHeadwordLabelScrollMoreIcon.frame;
  
  // Y-Positions for E_TO_J Mode
  if([studyDirection isEqualToString: SET_E_TO_J])
  {
    // Move headword to reading's Y position
    headwordY = readingY;
    
    // Now redefine val for reading Y
    readingY = readingY + headwordFrame.size.height;//+ (cardReadingLabelScrollContainerYPosInXib -readingFrame.size.height);
    readingBtnY = readingY;
    
    // Text format options for J_TO_E Mode
    readingFont = [UIFont boldSystemFontOfSize:READING_DEF_FONTSIZE];
    readingColor = [UIColor whiteColor];
  }
  
  // Set new linebreak modes
  if([studyDirection isEqualToString: SET_E_TO_J])
  {
    cardHeadwordLabel.lineBreakMode = UILineBreakModeWordWrap;
  } else {
    cardHeadwordLabel.lineBreakMode = UILineBreakModeCharacterWrap;
  }
  
  // Move cardReadingLabel
  readingFrame.origin.y = readingY;
  cardReadingLabelScrollContainer.frame = readingFrame;
  
  // Move revealReadingBtn
  readingBtnFrame.origin.y = readingBtnY;
  toggleReadingBtn.frame = readingBtnFrame;
  
  // Move cardHeadwordLabelScrollContainer
  headwordFrame.origin.y = headwordY;
  cardHeadwordLabelScrollContainer.frame = headwordFrame;
  
  // Move the headword Scroll More Icon
  headwordScrollMoreFrame.origin.y = headwordY+(headwordFrame.size.height/3);
  cardHeadwordLabelScrollMoreIcon.frame = headwordScrollMoreFrame;
  
  // Move cardReadingLabelScrollMoreIcon
  readingScrollMoreFrame.origin.y = readingBtnY+(CARDCONTENT_PADDING*3);
  cardReadingLabelScrollMoreIcon.frame = readingScrollMoreFrame;
  
  // Adjust cardReaingLabel properties
  cardReadingLabel.textColor = readingColor;
  cardReadingLabel.font = readingFont;
}


// Toggle "more" icon to indicate the user can scroll meaning down
- (void) toggleMoreIconForLabel:(UILabel *)theLabel forScrollView: (UIScrollView *)scrollViewContainer {
  
  CGSize theLabelSize = theLabel.frame.size;
  CGSize theParentSize = scrollViewContainer.frame.size;
  NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
  
  if(theLabel == cardReadingLabel){
    if(theLabelSize.height > theParentSize.height){
      if([[settings objectForKey:APP_HEADWORD] isEqualToString: SET_E_TO_J] && meaningRevealed){
        [cardReadingLabelScrollMoreIcon setHidden:NO];
      }else if(!meaningRevealed){
        [cardReadingLabelScrollMoreIcon setHidden:YES];
      } else {
        [cardReadingLabelScrollMoreIcon setHidden:NO];
      }
    } else {
      [cardReadingLabelScrollMoreIcon setHidden:YES];
    }
  }
  else if(theLabel == cardHeadwordLabel){
    if(theLabelSize.height > theParentSize.height){
      [cardHeadwordLabelScrollMoreIcon setHidden:NO];
    } else {
      [cardHeadwordLabelScrollMoreIcon setHidden:YES];
    }
  }
}

- (void) updateCardReading
{
  NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
  NSString *combined_reading;
  
  // Mux the readings according to user preference
  if([[settings objectForKey:APP_READING] isEqualToString:SET_READING_KANA])
  {
    combined_reading = [[NSString alloc] initWithFormat:@"%@", [currentCard reading]];
  } 
  else if([[settings objectForKey:APP_READING] isEqualToString: SET_READING_ROMAJI])
  {
    combined_reading = [[NSString alloc] initWithFormat:@"%@", [currentCard romaji]];
  }
  else
  {
    // Both together
    combined_reading = [[NSString alloc] initWithFormat:@"%@\n%@", [currentCard reading], [currentCard romaji]];
  }
  [cardReadingLabel setText:combined_reading];
  [LWEUILabelUtils resizeLabelWithConstraints:cardReadingLabel minFontSize:READING_MIN_FONTSIZE maxFontSize:READING_MAX_FONTSIZE forParentViewSize:cardReadingLabelScrollContainer.frame.size];
  [combined_reading release];
}

- (void) displayMeaningWebView
{
  [self _meaningWebViewWillDisplay];
  [meaningWebView setHidden:[self _meaningWebViewShouldBeHidden:YES]];
  [self _meaningWebViewDidDisplay]; 
  [self toggleMoreIconForLabel:[self cardReadingLabel] forScrollView:cardReadingLabelScrollContainer];
}

- (void) setupMeaningWebView: (NSUserDefaults *) settings {
  
  // Modify the inline CSS for current theme
  NSString *cssHeader = [[ThemeManager sharedThemeManager] currentThemeCSS];
  NSString *htmlHeader = [HTML_HEADER stringByReplacingOccurrencesOfString:@"##THEMECSS##" withString:cssHeader];  
  
  // Show Card Meaning
  // TODO: refactor this
  NSString *html;
  if([[settings objectForKey:APP_HEADWORD] isEqualToString: SET_E_TO_J])
  {
    html = [NSString stringWithFormat:@"%@<span class='jpn'>%@</span>%@", htmlHeader, [currentCard headword], HTML_FOOTER];    
  }
  else
  {
    html = [NSString stringWithFormat:@"%@<span>%@</span>%@", htmlHeader, [currentCard meaning], HTML_FOOTER];    
  }
  
  meaningWebView.backgroundColor = [UIColor clearColor];
  UIScrollView *scrollView = [meaningWebView.subviews objectAtIndex:0];
  
  SEL aSelector = NSSelectorFromString(@"setAllowsRubberBanding:");
  if([scrollView respondsToSelector:aSelector])
  {
    [scrollView performSelector:aSelector withObject:NO];
  }
  [meaningWebView loadHTMLString:html baseURL:nil];
  
  [self displayMeaningWebView];
}

// Prepare the view for the current card
- (void) prepareView
{
  
  LWE_LOG(@"START prepareViewForCard");
  [self _cardViewWillSetup];
  
  NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
  
	// Show Blank Card
  if([[settings objectForKey:APP_HEADWORD] isEqualToString:SET_E_TO_J])
  {
    [cardHeadwordLabel setText:[currentCard headword_en]];    
  }
  else
  {
    [cardHeadwordLabel setText:[currentCard headword]];    
  }
  
  [self updateCardReading];
  
  //setup the web view
  [self setupMeaningWebView: settings];
  
  // Resize text within bounds
  [LWEUILabelUtils autosizeLabelText:cardReadingLabel forScrollView:cardReadingLabelScrollContainer withText:[currentCard reading] minFontSize:READING_MIN_FONTSIZE maxFontSize:READING_MAX_FONTSIZE];
  [LWEUILabelUtils autosizeLabelText:cardHeadwordLabel forScrollView:cardHeadwordLabelScrollContainer withText:[currentCard headword] minFontSize:HEADWORD_MIN_FONTSIZE maxFontSize:HEADWORD_MAX_FONTSIZE];
    
  [self toggleMoreIconForLabel:cardReadingLabel forScrollView:cardReadingLabelScrollContainer];
  [self toggleMoreIconForLabel:cardHeadwordLabel forScrollView:cardHeadwordLabelScrollContainer];
  
  [self _cardViewDidSetup];
  
  LWE_LOG(@"END prepareViewForCard");
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}


- (void)dealloc {
  [cardHeadwordLabel release];
  [cardReadingLabel release];
  [cardMeaningBtn release];
  [toggleReadingBtn release];
  [meaningWebView release];
  [super dealloc];
}


@end

//! Notification names
NSString  *meaningWebViewDidDisplayNotification = @"meaningWebViewDidDisplayNotification";
NSString  *meaningWebViewWillDisplayNotification = @"meaningWebViewWillDisplayNotification";
NSString  *cardViewWillSetupNotification = @"cardViewWillSetupNotification";
NSString  *cardViewDidSetupNotification = @"cardViewDidSetupNotification";