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

@synthesize _tmpJavascript;

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad 
{
	LWE_LOG(@"Word card view controller get loaded");
  [super viewDidLoad];
  
  // Make sure this is nil before the web view starts loading
  self._tmpJavascript = nil;
  
  // Get values from XIB on first load
  // TODO: iPad customization!
  CGRect tmpFrame;
  tmpFrame = cardReadingLabelScrollContainer.frame;
  cardReadingLabelScrollContainerYPosInXib = tmpFrame.origin.y;
  tmpFrame = cardHeadwordLabel.frame;
  cardHeadwordLabelHeightInXib = tmpFrame.size.height;
  tmpFrame = toggleReadingBtn.frame;
  toggleReadingBtnYPosInXib = tmpFrame.origin.y;
  tmpFrame = cardHeadwordLabelScrollContainer.frame;
  cardHeadwordLabelYPosInXib = tmpFrame.origin.y;  
  
  NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];  
  [self layoutCardContentForStudyDirection:[settings objectForKey:APP_HEADWORD]];
  
  // Modify the inline CSS for current theme
  // TODO: make this work when the user changes themes
  NSString *cssHeader = [[ThemeManager sharedThemeManager] currentThemeCSS];
  NSString *htmlHeader = [HTML_HEADER stringByReplacingOccurrencesOfString:@"##THEMECSS##" withString:cssHeader];  
  NSString *html = [NSString stringWithFormat:@"%@%@",htmlHeader,HTML_FOOTER];

  // Initialize the web view
  [self.meaningWebView loadHTMLString:html baseURL:nil];
}

#pragma mark layout methods

- (void) layoutCardContentForStudyDirection: (NSString*)studyDirection
{
  // Y-Positions for J_TO_E Mode
  // NB: with UIScrollView objects you have to add the height of itself to it's y-position
  int readingY    = cardReadingLabelScrollContainerYPosInXib;
  int readingBtnY = toggleReadingBtnYPosInXib;
  int headwordY   = cardHeadwordLabelYPosInXib;
  
  // TODO: iPad customization!
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
    
  }
  
  // Set new linebreak modes
  if([studyDirection isEqualToString: SET_E_TO_J])
  {
    cardHeadwordLabel.lineBreakMode = UILineBreakModeWordWrap;
  } 
	else 
	{
    cardHeadwordLabel.lineBreakMode = UILineBreakModeCharacterWrap;
  }
  
  // TODO: iPad customization!
  // Move cardReadingLabel
  readingFrame.origin.y = readingY;
  cardReadingLabelScrollContainer.frame = readingFrame;
  
  // TODO: iPad customization!
  // Move revealReadingBtn
  readingBtnFrame.origin.y = readingBtnY;
  toggleReadingBtn.frame = readingBtnFrame;
  
  // TODO: iPad customization!
  // Move cardHeadwordLabelScrollContainer
  headwordFrame.origin.y = headwordY;
  cardHeadwordLabelScrollContainer.frame = headwordFrame;
  
  // TODO: iPad customization!
  // Move the headword Scroll More Icon
  headwordScrollMoreFrame.origin.y = headwordY+(headwordFrame.size.height/3);
  cardHeadwordLabelScrollMoreIcon.frame = headwordScrollMoreFrame;
  
  // TODO: iPad customization!
  // Move cardReadingLabelScrollMoreIcon
  readingScrollMoreFrame.origin.y = readingBtnY+(CARDCONTENT_PADDING*3);
  cardReadingLabelScrollMoreIcon.frame = readingScrollMoreFrame;
}


// Toggle "more" icon to indicate the user can scroll meaning down
- (void) toggleMoreIconForLabel:(UILabel *)theLabel forScrollView: (UIScrollView *)scrollViewContainer 
{
  // TODO: iPad customization!
  CGSize theLabelSize = theLabel.frame.size;
  CGSize theParentSize = scrollViewContainer.frame.size;
  NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
  
  if (theLabel == cardReadingLabel)
  {
    if(theLabelSize.height > theParentSize.height)
    {
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
  else if (theLabel == cardHeadwordLabel)
  {
    if(theLabelSize.height > theParentSize.height)
    {
      [[self cardHeadwordLabelScrollMoreIcon] setHidden:NO];
    }
    else
    {
      [[self cardHeadwordLabelScrollMoreIcon] setHidden:YES];
    }
  }
}

- (void) updateCardReading:(Card*) card
{
  [cardReadingLabel setText:[card combinedReadingForSettings]];
  [LWEUILabelUtils resizeLabelWithConstraints:cardReadingLabel minFontSize:READING_MIN_FONTSIZE maxFontSize:READING_MAX_FONTSIZE forParentViewSize:cardReadingLabelScrollContainer.frame.size];
}

- (void) hideMeaningWebView:(BOOL)hideMeaningWebView
{
  [self.meaningWebView setHidden:hideMeaningWebView];
  [self toggleMoreIconForLabel:[self cardReadingLabel] forScrollView:cardReadingLabelScrollContainer];
}

- (void) setupMeaningWebView: (NSUserDefaults *) settings Card:(Card*)card 
{
  NSString *html;
  if([[settings objectForKey:APP_HEADWORD] isEqualToString: SET_E_TO_J])
  {
    html = [NSString stringWithFormat:@"<span class='jpn'>%@</span>", [card headword]];
  }
  else
  {
    html = [NSString stringWithFormat:@"<span>%@</span>", [card meaning]];    
  }

  self.meaningWebView.backgroundColor = [UIColor clearColor];
  [self.meaningWebView shutOffBouncing];
  
  // Javascript
  NSString *js = [NSString stringWithFormat:@"var textElement = document.getElementById('container');"
  "if (textElement) { textElement.innerHTML = '%@'; } ",html];

  // Save of copy of this in case the webview hasn't finished loading yet
  self._tmpJavascript = js;
    
  // Not loading, do it as normal
  [self.meaningWebView stringByEvaluatingJavaScriptFromString:js];
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
  // Toggle
  [self setReadingVisible:(![self readingVisible])];
  [self setupReadingVisibility];
}

#pragma mark -
#pragma mark UIWebViewDelegate Support

/**
 * This callback should only be called once at the beginning of a study session
 * When the webview doesn't load as fast as the view controllers (so far, always)
 * the javascript call in "setupWebMeaning" or whatever will do nothing - so 
 * it caches the result in _tmpHTML and waits for the delegate callback
 */
- (void)webViewDidFinishLoad:(UIWebView *)webView
{
  // Aha, we have some HTML on first load, so load that shit up
  if (self._tmpJavascript)
  {
    [self.meaningWebView stringByEvaluatingJavaScriptFromString:self._tmpJavascript];
  }
}

#pragma mark -
#pragma mark Plumbing

- (void)viewDidUnload 
{
	[super viewDidUnload];
	self.cardReadingLabelScrollContainer = nil;
	self.cardHeadwordLabelScrollContainer = nil;
	self.cardHeadwordLabelScrollMoreIcon = nil;
	self.cardReadingLabelScrollMoreIcon = nil;
	self.cardHeadwordLabel = nil;
	self.cardReadingLabel = nil;
	self.toggleReadingBtn = nil;
	self.meaningWebView = nil;
}


- (void)dealloc 
{
	[cardReadingLabelScrollContainer release];
	[cardHeadwordLabelScrollContainer release];
	[cardHeadwordLabelScrollMoreIcon release];
	[cardReadingLabelScrollMoreIcon release];
	
  [cardHeadwordLabel release];
  [cardReadingLabel release];
  [toggleReadingBtn release];
  
  // Apparently we're supposed to set this to nil, according to the docs
  // I guess it's in case some other guy is holding a reference to this dude
  self.meaningWebView.delegate = nil;
  [meaningWebView release];
	
  [super dealloc];
}


@end
