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
  CGRect tmpFrame = CGRectZero;
  tmpFrame = self.cardReadingLabelScrollContainer.frame;
  self.cardReadingLabelScrollContainerYPosInXib = tmpFrame.origin.y;
  tmpFrame = self.cardHeadwordLabel.frame;
  self.cardHeadwordLabelHeightInXib = tmpFrame.size.height;
  tmpFrame = self.toggleReadingBtn.frame;
  self.toggleReadingBtnYPosInXib = tmpFrame.origin.y;
  tmpFrame = self.cardHeadwordLabelScrollContainer.frame;
  self.cardHeadwordLabelYPosInXib = tmpFrame.origin.y;  
  
  NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];  
  [self layoutCardContentForStudyDirection:[settings objectForKey:APP_HEADWORD]];
  
  // Modify the inline CSS for current theme
  // TODO: make this work when the user changes themes
  // Update - I thnk it does?? MMA 8/2011
  NSString *cssHeader = [[ThemeManager sharedThemeManager] currentThemeCSS];
  NSString *htmlHeader = [HTML_HEADER stringByReplacingOccurrencesOfString:@"##THEMECSS##" withString:cssHeader];  
  NSString *html = [NSString stringWithFormat:@"%@%@",htmlHeader,HTML_FOOTER];

  // Initialize the web view
  [self.meaningWebView loadHTMLString:html baseURL:nil];
}

#pragma mark - layout methods

- (void) layoutCardContentForStudyDirection: (NSString*)studyDirection
{
  // Y-Positions for J_TO_E Mode
  // NB: with UIScrollView objects you have to add the height of itself to it's y-position
  NSInteger readingY    = self.cardReadingLabelScrollContainerYPosInXib;
  NSInteger readingBtnY = self.toggleReadingBtnYPosInXib;
  NSInteger headwordY   = self.cardHeadwordLabelYPosInXib;
  
  // TODO: iPad customization!
  CGRect readingFrame = self.cardReadingLabelScrollContainer.frame;
  CGRect headwordFrame = self.cardHeadwordLabelScrollContainer.frame;
  CGRect readingBtnFrame = self.toggleReadingBtn.frame;
  CGRect readingScrollMoreFrame = self.cardReadingLabelScrollMoreIcon.frame;
  CGRect headwordScrollMoreFrame = self.cardHeadwordLabelScrollMoreIcon.frame;
  
  // Y-Positions for E_TO_J Mode
  if ([studyDirection isEqualToString:SET_E_TO_J])
  {
    // Move headword to reading's Y position
    headwordY = readingY;
    
    // Now redefine val for reading Y
    readingY = readingY + headwordFrame.size.height;//+ (cardReadingLabelScrollContainerYPosInXib -readingFrame.size.height);
    readingBtnY = readingY;
  }
  
  // Set new linebreak modes
  if ([studyDirection isEqualToString:SET_E_TO_J])
  {
    self.cardHeadwordLabel.lineBreakMode = UILineBreakModeWordWrap;
  } 
	else 
	{
    self.cardHeadwordLabel.lineBreakMode = UILineBreakModeCharacterWrap;
  }
  
  // TODO: iPad customization!
  // Move cardReadingLabel
  readingFrame.origin.y = readingY;
  self.cardReadingLabelScrollContainer.frame = readingFrame;
  
  // TODO: iPad customization!
  // Move revealReadingBtn
  readingBtnFrame.origin.y = readingBtnY;
  self.toggleReadingBtn.frame = readingBtnFrame;
  
  // TODO: iPad customization!
  // Move cardHeadwordLabelScrollContainer
  headwordFrame.origin.y = headwordY;
  self.cardHeadwordLabelScrollContainer.frame = headwordFrame;
  
  // TODO: iPad customization!
  // Move the headword Scroll More Icon
  headwordScrollMoreFrame.origin.y = headwordY+(headwordFrame.size.height/3);
  self.cardHeadwordLabelScrollMoreIcon.frame = headwordScrollMoreFrame;
  
  // TODO: iPad customization!
  // Move cardReadingLabelScrollMoreIcon
  readingScrollMoreFrame.origin.y = readingBtnY+(CARDCONTENT_PADDING*3);
  self.cardReadingLabelScrollMoreIcon.frame = readingScrollMoreFrame;
}


// Toggle "more" icon to indicate the user can scroll meaning down
- (void) toggleMoreIconForLabel:(UIView *)theLabel forScrollView: (UIScrollView *)scrollViewContainer 
{
  // TODO: iPad customization!
  CGSize theLabelSize = theLabel.frame.size;
  CGSize theParentSize = scrollViewContainer.frame.size;
  NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
  
  if (theLabel == self.cardReadingLabel)
  {
    if (theLabelSize.height > theParentSize.height)
    {
      if ([[settings objectForKey:APP_HEADWORD] isEqualToString:SET_E_TO_J] && self.meaningRevealed)
      {
        self.cardReadingLabelScrollMoreIcon.hidden = NO;
      }
      else if (self.meaningRevealed == NO)
      {
        self.cardReadingLabelScrollMoreIcon.hidden = YES;
      }
      else 
      {
        self.cardReadingLabelScrollMoreIcon.hidden = NO;
      }
    } 
    else 
    {
      self.cardReadingLabelScrollMoreIcon.hidden = YES;
    }
  }
  else if (theLabel == self.cardHeadwordLabel)
  {
    if (theLabelSize.height > theParentSize.height)
    {
      self.cardHeadwordLabelScrollMoreIcon.hidden = NO;
    }
    else
    {
      self.cardHeadwordLabelScrollMoreIcon.hidden = YES;
    }
  }
}

- (void) updateCardReading:(Card*) card
{
  // TODO: This is where the shit needs to happen (MMA)
  [self.cardReadingLabel updateNumberOfLabels:1];
  [self.cardReadingLabel setText:card.reading andColor:[UIColor greenColor] forLabel:0];
  
  
  [LWEUILabelUtils resizeLabelWithConstraints:[self.cardReadingLabel.labels objectAtIndex:0]
                                  minFontSize:READING_MIN_FONTSIZE
                                  maxFontSize:READING_MAX_FONTSIZE
                            forParentViewSize:self.cardReadingLabelScrollContainer.frame.size];
}

- (void) hideMeaningWebView:(BOOL)hideMeaningWebView
{
  [self.meaningWebView setHidden:hideMeaningWebView];
  [self toggleMoreIconForLabel:self.cardReadingLabel forScrollView:cardReadingLabelScrollContainer];
}

- (void) setupMeaningWebView: (NSUserDefaults *) settings Card:(Card*)card 
{
  NSString *html = nil;
  if ([[settings objectForKey:APP_HEADWORD] isEqualToString: SET_E_TO_J])
  {
    html = [NSString stringWithFormat:@"<span class='jpn'>%@</span>",card.headword];
  }
  else
  {
    html = [NSString stringWithFormat:@"<span>%@</span>",card.meaning];    
  }

  self.meaningWebView.backgroundColor = [UIColor clearColor];
  [self.meaningWebView shutOffBouncing];
  
  // The HTML will be encapsulated in Javascript, make sure to escape that noise
  NSString *escapedHtml = [html stringByReplacingOccurrencesOfString:@"'" withString:@"\\\'"];
  
  // Javascript
  NSString *js = [NSString stringWithFormat:@"var textElement = document.getElementById('container');"
  "if (textElement) { textElement.innerHTML = '%@'; } ",escapedHtml];

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
    self.cardHeadwordLabel.text = card.headword_en;
  }
  else
  {
    self.cardHeadwordLabel.text = card.headword;
  }
  
  [self updateCardReading:card];
  
  //setup the web view
  [self setupMeaningWebView:settings Card:card];
  
  // Resize text within bounds
  [LWEUILabelUtils autosizeLabelText:[self.cardReadingLabel.labels objectAtIndex:0]
                       forScrollView:self.cardReadingLabelScrollContainer
                            withText:card.reading
                         minFontSize:READING_MIN_FONTSIZE
                         maxFontSize:READING_MAX_FONTSIZE];
  
  [LWEUILabelUtils autosizeLabelText:self.cardHeadwordLabel
                       forScrollView:self.cardHeadwordLabelScrollContainer
                            withText:card.headword
                         minFontSize:HEADWORD_MIN_FONTSIZE
                         maxFontSize:HEADWORD_MAX_FONTSIZE];
  
  [self toggleMoreIconForLabel:self.cardReadingLabel forScrollView:self.cardReadingLabelScrollContainer];
  [self toggleMoreIconForLabel:self.cardHeadwordLabel forScrollView:self.cardHeadwordLabelScrollContainer];
  
  LWE_LOG(@"END prepareViewForCard");
}

#pragma mark - Reading Label Methods

//! shows or hides the reading label and toggleButton according to the readingVisible bool
- (void) setupReadingVisibility 
{
  if (self.readingVisible)
  {
    self.cardReadingLabelScrollContainer.hidden = NO;
    self.cardReadingLabel.hidden = NO;
    [self.toggleReadingBtn setBackgroundImage:NULL forState:UIControlStateNormal];
  }
  else
  {
    self.cardReadingLabelScrollContainer.hidden = YES;
    self.cardReadingLabel.hidden = YES;
    [self.toggleReadingBtn setBackgroundImage:[UIImage imageNamed:@"practice-btn-showreading.png"] forState:UIControlStateNormal];
  }
}

//! toggles the readingVisible bool and calls setupReadingVisibility
- (IBAction) doToggleReadingBtn
{
  // Toggle
  [self setReadingVisible:(self.readingVisible == NO)];
  [self setupReadingVisibility];
}

#pragma mark - UIWebViewDelegate Support

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
