//
//  WordCardViewController.m
//  jFlash
//
//  Created by シャロット ロス on 6/3/10.
//  Copyright 2010 LONG WEEKEND INC.. All rights reserved.
//

#import "CardViewController.h"
#import "UIScrollView+LWEUtilities.h"

#if defined (LWE_CFLASH)
  #import "ChineseCard.h"
  #import "TTTAttributedLabel.h"
#endif

// Private Methods
@interface CardViewController()
- (void) _injectMeaningHTML:(NSString*)html;
- (void) _prepareView:(Card*)card;
- (void) _updateReadingContainer;

//! Returns YES if the contents of theLabel fit in scrollViewContainer w/o scrolling
- (BOOL) _shouldHideMoreIconForLabel:(UIView *)theLabel forScrollView:(UIScrollView *)scrollViewContainer;
@end

@implementation CardViewController

@synthesize delegate;
@synthesize meaningWebView, headwordMoreIcon, headwordLabel, readingMoreIcon, readingLabel, toggleReadingBtn;
@synthesize readingScrollContainer, headwordScrollContainer, readingVisible = _readingVisible;

@synthesize baseHtml;

@synthesize moodIcon;

#pragma mark - Flow Methods

- (void) setupWithCard:(Card*)card
{
  LWE_DELEGATE_CALL(@selector(cardViewWillSetup:),self);
  [self _prepareView:card];
  LWE_DELEGATE_CALL(@selector(cardViewDidSetup:),self);
}

- (void) studyViewModeDidChange:(StudyViewController*)svc
{
  if (self.delegate && [self.delegate respondsToSelector:@selector(cardViewDidChangeMode:)])
  {
    [self.delegate cardViewDidChangeMode:self];
  }
}


/**
 * Default "reveal" behavior is no
 */
- (void) reveal
{
  if (self.delegate && [self.delegate respondsToSelector:@selector(shouldRevealCardView:)])
  {
    BOOL shouldReveal = [self.delegate shouldRevealCardView:self];
    if (shouldReveal)
    {
      LWE_DELEGATE_CALL(@selector(cardViewWillReveal:),self);
      LWE_DELEGATE_CALL(@selector(cardViewDidReveal:),self);
    }
  }
}

#pragma mark - Class Plumbing

- (id) initDisplayMainHeadword:(BOOL)displayMainHeadword
{
  // First get the appropriate NIB name & HTML to display
  NSString *nibName = nil;
  NSString *html = nil;
  if (displayMainHeadword)
  {
    // Main headword, so don't do anything differently.
    html = LWECardHTMLTemplate;
    nibName = @"CardViewController";
  }
  else
  {
    // Prepare the view for displaying in E-to-J mode
    html = LWECardHTMLTemplate_EtoJ;
    nibName = @"CardViewController-EtoJ";
  }
    
  // Now initialize the class with this information
  self = [super initWithNibName:nibName bundle:nil];
  if (self)
  {
    // Replace out the CSS to match the current theme
    NSString *cssHeader = [[ThemeManager sharedThemeManager] currentThemeCSS];
    html = [html stringByReplacingOccurrencesOfString:@"##THEMECSS##" withString:cssHeader];
    
    // Replace the font tag with the current setting
    NSString *textSize = [[NSUserDefaults standardUserDefaults] objectForKey:APP_TEXT_SIZE];
    html = [html stringByReplacingOccurrencesOfString:@"##TEXTSIZE##" withString:textSize];
    
    self.baseHtml = html;
  }
  return self;
}

- (void)viewDidLoad 
{
  [super viewDidLoad];
  [self.meaningWebView loadHTMLString:self.baseHtml baseURL:nil];
  [self.meaningWebView shutOffBouncing];
  self.meaningWebView.backgroundColor = [UIColor clearColor];
  
  // Add mood icon subview - TODO: MMA this is 90% complete, but I want to find a way to do this in the NIB
  CGRect moodIconRect = CGRectMake(235, 197, 80, 73);
  self.moodIcon.view.frame = moodIconRect;
  self.moodIcon.view.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
  [self.view addSubview:self.moodIcon.view];
  [self.moodIcon updateMoodIcon:100.0f];
  
  // For languages such as Chinese, we may need to configure the font
  self.headwordLabel.font = [Card configureFontForLabel:self.headwordLabel];
}

#pragma mark - IBAction Methods

/**
 * If the reading scroll container is hidden, this shows it.
 * If it's showing, it hides it.
 */
- (IBAction) doToggleReadingBtn
{
  if (self.readingScrollContainer.hidden == YES)
  {
    [self turnReadingOn];
    self.readingVisible = YES;
  }
  else
  {
    [self turnReadingOff];
    self.readingVisible = NO;
  }
}

#pragma mark - Public Helper Methods

- (void) turnReadingOn
{
  // Change state
  self.readingScrollContainer.hidden = NO;
  [self.toggleReadingBtn setTitle:@"" forState:UIControlStateNormal];
  
  // This will handle the "more" icon after the state change
  [self _updateReadingContainer];
}

- (void) turnReadingOff
{
  // This will handle the "more" icon
  [self _updateReadingContainer];
  
  self.readingScrollContainer.hidden = YES;
  [self.toggleReadingBtn setTitle:@"Show Reading" forState:UIControlStateNormal];

  // This will handle the "more" icon after the state change
  [self _updateReadingContainer];
}

//! shows or hides the reading label and toggleButton according to the readingVisible bool
- (void) resetReadingVisibility 
{
  if (self.readingVisible == NO)
  {
    [self turnReadingOff];
  }
  else
  {
    [self turnReadingOn];
  }
}

#pragma mark - Private Methods

// Toggle "more" icon to indicate the user can scroll meaning down
- (BOOL) _shouldHideMoreIconForLabel:(UILabel *)theLabel forScrollView:(UIScrollView *)scrollViewContainer 
{
  return (theLabel.frame.size.height <= scrollViewContainer.frame.size.height);
}

// Prepare the view for the current card
- (void) _prepareView:(Card*)card
{
  // Reset the meaning's scroll view location -- this is not available earlier than iOS5, so wrap it.
  if ([self.meaningWebView respondsToSelector:@selector(scrollView)])
  {
    self.meaningWebView.scrollView.contentOffset = CGPointZero;
  }
  
  // Fix up the headword & the meaning; those are a bit easier.
  [self _injectMeaningHTML:card.meaning];
  self.headwordLabel.text = card.headword;
  
  // Now do the hard part (for CFlash)
#if defined(LWE_JFLASH)
  self.readingLabel.text = card.reading;
#elif defined(LWE_CFLASH)
  [(TTTAttributedLabel *)self.readingLabel setText:[card attributedReading]];
#endif
  // These calls re-size the reading & headword labels.  They used to take the scrollContainer as well,
  // but we infer it (superview) of the labels inside this call.
  [self.readingLabel resizeWithMinFontSize:READING_MIN_FONTSIZE maxFontSize:READING_MAX_FONTSIZE];
  [self.headwordLabel resizeWithMinFontSize:HEADWORD_MIN_FONTSIZE maxFontSize:HEADWORD_MAX_FONTSIZE];
  
  // Now resize the scroll views as necessary based on the resized views above, if necessary.
  // This call also centers the label inside the scroll view.
  [self.readingScrollContainer resizeScrollViewWithContentView:self.readingLabel];
  [self.headwordScrollContainer resizeScrollViewWithContentView:self.headwordLabel];

  //[self _updateReadingContainer];
  self.headwordMoreIcon.hidden = [self _shouldHideMoreIconForLabel:self.headwordLabel
                                                     forScrollView:self.headwordScrollContainer];
}

- (void) _updateReadingContainer
{
  // Hide the scroll icon if the label fits, or if the reading isn't visible yet.
  BOOL shouldHideReadingScroll = [self _shouldHideMoreIconForLabel:self.readingLabel
                                                     forScrollView:self.readingScrollContainer];
  self.readingMoreIcon.hidden = (shouldHideReadingScroll || (self.readingScrollContainer.hidden == YES));
}

- (void) _injectMeaningHTML:(NSString*)html
{
  // The HTML will be encapsulated in Javascript, make sure to escape that noise
  NSString *escapedHtml = [html stringByReplacingOccurrencesOfString:@"'" withString:@"\\\'"];
  NSString *js = [NSString stringWithFormat:@"var textElement = document.getElementById('container'); if (textElement) { textElement.innerHTML = '%@'; }",escapedHtml];
  
  // Save of copy of this in case the webview hasn't finished loading yet (see WebView delegate below)
  _tmpJavascript = [js retain];
  
  // Not loading, do it as normal
  [self.meaningWebView stringByEvaluatingJavaScriptFromString:js];
}


#pragma mark - UIWebViewDelegate Support

/**
 * This callback should only be called once at the beginning of a study session
 * When the webview doesn't load as fast as the view controllers (so far, always)
 * the javascript call in "setupWebMeaning" or whatever will do nothing - so 
 * it caches the result in _tmpJavascript and waits for the delegate callback
 */
- (void)webViewDidFinishLoad:(UIWebView *)webView
{
  // Aha, we have some HTML on first load, so load that shit up
  if (_tmpJavascript)
  {
    [self.meaningWebView stringByEvaluatingJavaScriptFromString:_tmpJavascript];
    [_tmpJavascript release];
    _tmpJavascript = nil;
  }
}

#pragma mark - Plumbing

- (void)viewDidUnload 
{
	[super viewDidUnload];
	self.readingScrollContainer = nil;
	self.headwordScrollContainer = nil;
	self.headwordMoreIcon = nil;
	self.readingMoreIcon = nil;
	self.headwordLabel = nil;
	self.readingLabel = nil;
	self.toggleReadingBtn = nil;
	self.meaningWebView = nil;
	self.moodIcon = nil;
}


- (void)dealloc 
{
  [moodIcon release];

  [baseHtml release];
  [_tmpJavascript release];
  
	[headwordScrollContainer release];
	[headwordMoreIcon release];
  [headwordLabel release];
	
	[readingScrollContainer release];
	[readingMoreIcon release];
  [readingLabel release];
  [toggleReadingBtn release];
  
  // Apparently we're supposed to set this to nil, according to the docs
  // I guess it's in case some other guy is holding a reference to this dude
  self.meaningWebView.delegate = nil;
  [meaningWebView release];
	
  [super dealloc];
}

@end

// HTML Header content that will be displayed in the meaning UIWebView before the actual meaning
NSString * const LWECardHTMLTemplate = @""
"<html><head><meta http-equiv='Content-Type' content='text/html; charset=utf-8' />"
"<style>"
"body{ background-color: transparent; height:72px; display:table; margin:0px; padding:0px; text-align:center; line-height:21px; font-size:##TEXTSIZE##; font-weight:bold; font-family:Helvetica,sanserif; color:#fff; } "
"dfn{ text-shadow:none; font-weight:normal; color:#000; position:relative; top:-1px; font-family:verdana; font-size:10.5px; background-color:#C79810; line-height:10.5px; margin:4px 4px 0px 0px; height:14px; padding:2px 3px; -webkit-border-radius:4px; border:1px solid #F9F7ED; display:inline-block;} "
"#container{width:300px; display:table-cell; vertical-align:middle;text-align:center;vertical-align:middle;} "
"ol{color:white; text-align:left; width:240px; margin:0px; margin-left:24px; padding-left:10px;} "
"li{color:white; margin:0px; margin-bottom:7px;} "
"##THEMECSS##"
"</style></head>"
"<body><div id='container'>"
"</div></body></html>";

NSString * const LWECardHTMLTemplate_EtoJ = @""
"<html><head><meta http-equiv='Content-Type' content='text/html; charset=utf-8' />"
"<style>"
"body{ background-color: transparent; height:72px; display:table; margin:0px; padding:0px; text-align:center; line-height:21px; font-size:##TEXTSIZE##; font-weight:bold; font-family:Helvetica,sanserif; color:#fff; } "
"dfn{ text-shadow:none; font-weight:normal; color:#000; position:relative; top:-1px; font-family:verdana; font-size:10.5px; background-color:#C79810; line-height:10.5px; margin:4px 4px 0px 0px; height:14px; padding:2px 3px; -webkit-border-radius:4px; border:1px solid #F9F7ED; display:inline-block;} "
"#container{width:300px; display:table-cell; vertical-align:middle;text-align:center;font-size:34px; padding-left:3px; line-height:32px;} "
"ol{color:white; text-align:left; width:240px; margin:0px; margin-left:24px; padding-left:10px;} "
"li{color:white; margin:0px; margin-bottom:7px;} "
"##THEMECSS##"
"</style></head>"
"<body><div id='container'>"
"</div></body></html>";
