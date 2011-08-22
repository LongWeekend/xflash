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
@synthesize cardReadingLabelScrollContainer, cardHeadwordLabelScrollContainer, readingVisible, meaningRevealed;

- (void)viewDidLoad 
{
  [super viewDidLoad];
  
  // Modify the inline CSS for current theme
  // TODO: make this work when the user changes themes
  // Update - I thnk it does?? MMA 8/2011
  NSString *cssHeader = [[ThemeManager sharedThemeManager] currentThemeCSS];
  NSString *htmlHeader = [HTML_HEADER stringByReplacingOccurrencesOfString:@"##THEMECSS##" withString:cssHeader];  
  NSString *html = [NSString stringWithFormat:@"%@%@",htmlHeader,HTML_FOOTER];
  [self.meaningWebView loadHTMLString:html baseURL:nil];
}

#pragma mark - layout methods

// Toggle "more" icon to indicate the user can scroll meaning down
- (void) toggleMoreIconForLabel:(UIView *)theLabel forScrollView:(UIScrollView *)scrollViewContainer 
{
  BOOL isTooTall = (theLabel.frame.size.height > scrollViewContainer.frame.size.height);
  if (theLabel == self.cardReadingLabel)
  {
    // Hide the scroll icon if the label fits, or if the reading isn't visible yet.
    self.cardReadingLabelScrollMoreIcon.hidden = ((isTooTall == NO) || (self.readingVisible == NO));
  }
  else if (theLabel == self.cardHeadwordLabel)
  {
    self.cardHeadwordLabelScrollMoreIcon.hidden = (isTooTall == NO);
  }
}

- (void) hideMeaningWebView:(BOOL)hideMeaningWebView
{
  self.meaningWebView.hidden = hideMeaningWebView;
  [self toggleMoreIconForLabel:[[self.cardReadingLabel labels] objectAtIndex:0] forScrollView:cardReadingLabelScrollContainer];
}

- (void) setupMeaningWebView: (NSUserDefaults *) settings card:(Card*)card 
{
  self.meaningWebView.backgroundColor = [UIColor clearColor];
  [self.meaningWebView shutOffBouncing];

  NSString *html = nil;
  if ([[settings objectForKey:APP_HEADWORD] isEqualToString: SET_E_TO_J])
  {
    // We'd love to set the size of the font in the NIB, but since this is a web view that's not possible.
    // The class "JPN" makes it big.
    html = [NSString stringWithFormat:@"<span class='jpn'>%@</span>",card.headword];
  }
  else
  {
    html = [NSString stringWithFormat:@"<span>%@</span>",card.meaning];    
  }
  
  // The HTML will be encapsulated in Javascript, make sure to escape that noise
  NSString *escapedHtml = [html stringByReplacingOccurrencesOfString:@"'" withString:@"\\\'"];
  
  // Javascript
  NSString *js = [NSString stringWithFormat:@"var textElement = document.getElementById('container');"
  "if (textElement) { textElement.innerHTML = '%@'; } ",escapedHtml];

  // Save of copy of this in case the webview hasn't finished loading yet
  _tmpJavascript = [js retain];
    
  // Not loading, do it as normal
  [self.meaningWebView stringByEvaluatingJavaScriptFromString:js];
}

// Prepare the view for the current card
- (void) prepareView:(Card*)card
{
  self.cardHeadwordLabel.text = card.headword;

  // TODO: This is where the shit needs to happen (MMA)
  [self.cardReadingLabel updateNumberOfLabels:1];
  [self.cardReadingLabel setText:card.reading andColor:[UIColor greenColor] forLabel:0];
  
  // TODO: Maybe make this work again too?
  [LWEUILabelUtils resizeLabelWithConstraints:[self.cardReadingLabel.labels objectAtIndex:0]
                                  minFontSize:READING_MIN_FONTSIZE
                                  maxFontSize:READING_MAX_FONTSIZE
                            forParentViewSize:self.cardReadingLabelScrollContainer.frame.size];
  
  // Setup the web view
  NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
  [self setupMeaningWebView:settings card:card];
  
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
  
  [self toggleMoreIconForLabel:[[self.cardReadingLabel labels] objectAtIndex:0] forScrollView:self.cardReadingLabelScrollContainer];
  [self toggleMoreIconForLabel:self.cardHeadwordLabel forScrollView:self.cardHeadwordLabelScrollContainer];
}

#pragma mark - Reading Label Methods

- (void) turnReadingOn
{
  self.readingVisible = YES;
  self.cardReadingLabelScrollContainer.hidden = NO;
  [self.toggleReadingBtn setBackgroundImage:nil forState:UIControlStateNormal];
}

- (void) turnReadingOff
{
  self.readingVisible = NO;
  self.cardReadingLabelScrollContainer.hidden = YES;
  [self.toggleReadingBtn setBackgroundImage:[UIImage imageNamed:@"practice-btn-showreading.png"]
                                   forState:UIControlStateNormal];
}

//! shows or hides the reading label and toggleButton according to the readingVisible bool
- (void) resetReadingVisibility 
{
  self.cardReadingLabelScrollContainer.hidden = (self.readingVisible == NO);

  // Set the button image to nil when we have a reading showing, and show the "show reading" button when not.
  UIImage *displayReadingImage = (self.readingVisible) ? nil : [UIImage imageNamed:@"practice-btn-showreading.png"];
  [self.toggleReadingBtn setBackgroundImage:displayReadingImage forState:UIControlStateNormal];
}

//! toggles the readingVisible bool and calls setupReadingVisibility
- (IBAction) doToggleReadingBtn
{
  if (self.cardReadingLabelScrollContainer.hidden)
  {
    [self turnReadingOn];
  }
  else
  {
    [self turnReadingOff];
  }
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
  if (_tmpJavascript)
  {
    [self.meaningWebView stringByEvaluatingJavaScriptFromString:_tmpJavascript];
  }
}

#pragma mark - Plumbing

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
  [_tmpJavascript release];
  
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
