//
//  WordCardViewController.m
//  jFlash
//
//  Created by シャロット ロス on 6/3/10.
//  Copyright 2010 LONG WEEKEND INC.. All rights reserved.
//

#import "WordCardViewController.h"

@implementation WordCardViewController
@synthesize meaningWebView, cardHeadwordLabelScrollMoreIcon, cardHeadwordLabel, cardReadingLabelScrollMoreIcon, cardReadingLabel, toggleReadingBtn;
@synthesize cardReadingLabelScrollContainerYPosInXib, cardHeadwordLabelHeightInXib, toggleReadingBtnYPosInXib, cardHeadwordLabelYPosInXib;
@synthesize cardReadingLabelScrollContainer, cardHeadwordLabelScrollContainer, readingVisible, meaningRevealed;

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
  
  if(theLabel == cardReadingLabel)
  {
    if(theLabelSize.height > theParentSize.height){
      if([[settings objectForKey:APP_HEADWORD] isEqualToString: SET_E_TO_J] && meaningRevealed)
      {
        [[self cardReadingLabelScrollMoreIcon] setHidden:NO];
      }
      else if(!meaningRevealed)
      {
        [[self cardReadingLabelScrollMoreIcon] setHidden:YES];
      }
      else 
      {
        [[self cardReadingLabelScrollMoreIcon] setHidden:NO];
      }
    } 
    else 
    {
      [[self cardReadingLabelScrollMoreIcon] setHidden:YES];
    }
  }
  else if(theLabel == cardHeadwordLabel){
    if(theLabelSize.height > theParentSize.height){
      [[self cardHeadwordLabelScrollMoreIcon] setHidden:NO];
    } else {
      [[self cardHeadwordLabelScrollMoreIcon] setHidden:YES];
    }
  }
}

- (void) updateCardReading:(Card*) card
{
  NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
  NSString *combined_reading;
  
  // Mux the readings according to user preference
  if([[settings objectForKey:APP_READING] isEqualToString:SET_READING_KANA])
  {
    combined_reading = [[NSString alloc] initWithFormat:@"%@", [card reading]];
  } 
  else if([[settings objectForKey:APP_READING] isEqualToString: SET_READING_ROMAJI])
  {
    combined_reading = [[NSString alloc] initWithFormat:@"%@", [card romaji]];
  }
  else
  {
    // Both together
    combined_reading = [[NSString alloc] initWithFormat:@"%@\n%@", [card reading], [card romaji]];
  }
  [cardReadingLabel setText:combined_reading];
  [LWEUILabelUtils resizeLabelWithConstraints:cardReadingLabel minFontSize:READING_MIN_FONTSIZE maxFontSize:READING_MAX_FONTSIZE forParentViewSize:cardReadingLabelScrollContainer.frame.size];
  [combined_reading release];
}

- (void) hideMeaningWebView:(BOOL)hideMeaningWebView
{
  [meaningWebView setHidden:hideMeaningWebView];
  [self toggleMoreIconForLabel:[self cardReadingLabel] forScrollView:cardReadingLabelScrollContainer];
}

- (void) setupMeaningWebView: (NSUserDefaults *) settings Card:(Card*)card {  
  // Modify the inline CSS for current theme
  NSString *cssHeader = [[ThemeManager sharedThemeManager] currentThemeCSS];
  NSString *htmlHeader = [HTML_HEADER stringByReplacingOccurrencesOfString:@"##THEMECSS##" withString:cssHeader];  
  
  // Show Card Meaning
  // TODO: refactor this
  NSString *html;
  if([[settings objectForKey:APP_HEADWORD] isEqualToString: SET_E_TO_J])
  {
    html = [NSString stringWithFormat:@"%@<span class='jpn'>%@</span>%@", htmlHeader, [card headword], HTML_FOOTER];    
  }
  else
  {
    html = [NSString stringWithFormat:@"%@<span>%@</span>%@", htmlHeader, [card meaning], HTML_FOOTER];    
  }
  
  meaningWebView.backgroundColor = [UIColor clearColor];
  UIScrollView *scrollView = [meaningWebView.subviews objectAtIndex:0];
  
  SEL aSelector = NSSelectorFromString(@"setAllowsRubberBanding:");
  if([scrollView respondsToSelector:aSelector])
  {
    [scrollView performSelector:aSelector withObject:NO];
  }
  [meaningWebView loadHTMLString:html baseURL:nil];
}

// Prepare the view for the current card
- (void) prepareView:(Card*)card
{
  LWE_LOG(@"START prepareViewForCard");
  NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
  
	// Show Blank Card
  if([[settings objectForKey:APP_HEADWORD] isEqualToString:SET_E_TO_J])
  {
    [cardHeadwordLabel setText:[card headword_en]];    
  }
  else
  {
    [cardHeadwordLabel setText:[card headword]];    
  }
  
  [self updateCardReading:card];
  
  //setup the web view
  [self setupMeaningWebView:settings Card:card];
  
  // Resize text within bounds
  [LWEUILabelUtils autosizeLabelText:cardReadingLabel forScrollView:cardReadingLabelScrollContainer withText:[card reading] minFontSize:READING_MIN_FONTSIZE maxFontSize:READING_MAX_FONTSIZE];
  [LWEUILabelUtils autosizeLabelText:cardHeadwordLabel forScrollView:cardHeadwordLabelScrollContainer withText:[card headword] minFontSize:HEADWORD_MIN_FONTSIZE maxFontSize:HEADWORD_MAX_FONTSIZE];
  
  [self toggleMoreIconForLabel:cardReadingLabel forScrollView:cardReadingLabelScrollContainer];
  [self toggleMoreIconForLabel:cardHeadwordLabel forScrollView:cardHeadwordLabelScrollContainer];
  
  LWE_LOG(@"END prepareViewForCard");
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
- (void) setupReadingVisibility 
{
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

#pragma mark -
#pragma mark Plumbing

- (void)didReceiveMemoryWarning 
{
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload 
{
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}


- (void)dealloc 
{
  [cardHeadwordLabel release];
  [cardReadingLabel release];
  [toggleReadingBtn release];
  [meaningWebView release];  
  [super dealloc];
}


@end