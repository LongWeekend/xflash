//
//  WordCardViewController.m
//  jFlash
//
//  Created by シャロット ロス on 6/3/10.
//  Copyright 2010 LONG WEEKEND INC.. All rights reserved.
//

#import "CardViewController.h"

#import "ChineseCard.h"

// Private Methods
@interface CardViewController()
- (void) _injectMeaningHTML:(NSString*)html;
- (void) _prepareView:(Card*)card;
- (void) _toggleMoreIconForLabel:(UIView *)theLabel forScrollView:(UIScrollView *)scrollViewContainer;
@end

@implementation CardViewController

@synthesize delegate;
@synthesize meaningWebView, cardHeadwordLabelScrollMoreIcon, cardHeadwordLabel, cardReadingLabelScrollMoreIcon, cardReadingLabel, toggleReadingBtn;
@synthesize cardReadingLabelScrollContainer, cardHeadwordLabelScrollContainer, readingVisible;

@synthesize baseHtml;

@synthesize  moodIcon, moodIconBtn, percentCorrectLabel, hhAnimationView, percentCorrectTalkBubble;

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
  NSString *nibName = nil;
  NSString *htmlHeader = nil;
  NSString *cssHeader = [[ThemeManager sharedThemeManager] currentThemeCSS];
  if (displayMainHeadword)
  {
    // Main headword, so don't do anything differently.
    htmlHeader = [LWECardHtmlHeader stringByReplacingOccurrencesOfString:@"##THEMECSS##" withString:cssHeader];  
    nibName = @"CardViewController";
  }
  else
  {
    // Prepare the view for displaying in E-to-J mode
    htmlHeader = [LWECardHtmlHeader_EtoJ stringByReplacingOccurrencesOfString:@"##THEMECSS##" withString:cssHeader];  
    nibName = @"CardViewController-EtoJ";
  }
  self = [super initWithNibName:nibName bundle:nil];
  if (self)
  {
    self.baseHtml = [NSString stringWithFormat:@"%@%@",htmlHeader,LWECardHtmlFooter];
  }
  return self;
}

- (void)viewDidLoad 
{
  [super viewDidLoad];
  [self.meaningWebView loadHTMLString:self.baseHtml baseURL:nil];
  [self.meaningWebView shutOffBouncing];
  self.meaningWebView.backgroundColor = [UIColor clearColor];
  
  // Create a default mood icon object
  self.moodIcon = [[[MoodIcon alloc] init] autorelease];
  self.moodIcon.moodIconBtn = self.moodIconBtn;
  self.moodIcon.percentCorrectLabel = self.percentCorrectLabel;
  
  self.percentCorrectLabel.text = percentCorrectLabelStartText;
  [self.moodIcon updateMoodIcon:100.0f];
}

#pragma mark - IBAction Methods

/**
 * Turns the % correct button on and off, in case it is in the way of the meaning
 */
- (IBAction) doTogglePercentCorrectBtn
{
  // Hide the percentage talk bubble on click; use its current state to check which we should do.
  if (self.percentCorrectTalkBubble.hidden == YES)
  {
    [self turnPercentCorrectOn];
  }
  else
  {
    [self turnPercentCorrectOff];
  }
}

/**
 * If the reading scroll container is hidden, this shows it.
 * If it's showing, it hides it.
 */
- (IBAction) doToggleReadingBtn
{
  if (self.cardReadingLabelScrollContainer.hidden == YES)
  {
    [self turnReadingOn];
  }
  else
  {
    [self turnReadingOff];
  }
}

#pragma mark - Public Helper Methods

- (void) turnPercentCorrectOff
{
  self.percentCorrectTalkBubble.hidden = YES;
  self.percentCorrectLabel.hidden = YES;
}

- (void) turnPercentCorrectOn
{
  self.percentCorrectTalkBubble.hidden = NO;
  self.percentCorrectLabel.hidden = NO;
}

- (void) turnReadingOn
{
  self.readingVisible = YES;
  self.cardReadingLabelScrollContainer.hidden = NO;
  [self.toggleReadingBtn setBackgroundImage:nil forState:UIControlStateNormal];
  [self.cardReadingLabel setNeedsDisplay];
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

- (void) setMeaningWebViewHidden:(BOOL)shouldHide
{
  self.meaningWebView.hidden = shouldHide;
  [self _toggleMoreIconForLabel:self.cardReadingLabel forScrollView:cardReadingLabelScrollContainer];
}

#pragma mark - Private Methods

// Toggle "more" icon to indicate the user can scroll meaning down
- (void) _toggleMoreIconForLabel:(UILabel *)theLabel forScrollView:(UIScrollView *)scrollViewContainer 
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


// Prepare the view for the current card
- (void) _prepareView:(Card*)card
{
  // Fix up the headword & the meaning; those are a bit easier.
  [self _injectMeaningHTML:card.meaning];
  self.cardHeadwordLabel.text = card.headword;
  
  // Now do the hard part (for CFlash)
#if defined(LWE_JFLASH)
  self.cardReadingLabel.text = card.reading;
#elif defined(LWE_CFLASH)
  NSMutableAttributedString *attrString = [[[[NSAttributedString alloc] init] autorelease] mutableCopy];
  NSArray *readingHashes = [(ChineseCard*)card readingComponents];
  for (NSDictionary *readingHash in readingHashes)
  {
    NSString *stringToAppend = [NSString stringWithFormat:@"%@ ",[readingHash objectForKey:@"pinyin"]];
    NSMutableAttributedString *tmpAttrString = [[[[NSAttributedString alloc] initWithString:stringToAppend] autorelease] mutableCopy];
    NSRange allRange = NSMakeRange(0, [stringToAppend length]);
    [tmpAttrString addAttribute:(NSString *)kCTForegroundColorAttributeName
                          value:(id)[(UIColor*)[readingHash objectForKey:@"color"] CGColor]
                          range:allRange];
    [attrString appendAttributedString:tmpAttrString];
    [tmpAttrString release];
  }
  
  [(OHAttributedLabel *)self.cardReadingLabel setAttributedText:attrString];
  [attrString release];
  
  // Unfortunately this class (OHAttributedLabel) doesn't seem to preserve the UILabel attributes
  // from the XIB file, so we have to re-set it as centered :(   TTTAttributedLabel did, but it was 
  // wonky, so we have to go with what works
  self.cardReadingLabel.shadowOffset = CGSizeMake(1.0f, 1.0f);
  self.cardReadingLabel.shadowColor = [UIColor blackColor];
  self.cardReadingLabel.textAlignment = UITextAlignmentCenter;
#endif
  
  [LWEUILabelUtils resizeLabelWithConstraints:self.cardReadingLabel
                                  minFontSize:READING_MIN_FONTSIZE
                                  maxFontSize:READING_MAX_FONTSIZE
                            forParentViewSize:self.cardReadingLabelScrollContainer.frame.size];
  
  // Resize text within bounds
  [LWEUILabelUtils autosizeLabelText:self.cardReadingLabel
                       forScrollView:self.cardReadingLabelScrollContainer
                            withText:card.reading
                         minFontSize:READING_MIN_FONTSIZE
                         maxFontSize:READING_MAX_FONTSIZE];
  
  [LWEUILabelUtils autosizeLabelText:self.cardHeadwordLabel
                       forScrollView:self.cardHeadwordLabelScrollContainer
                            withText:card.headword
                         minFontSize:HEADWORD_MIN_FONTSIZE
                         maxFontSize:HEADWORD_MAX_FONTSIZE];
  
  [self _toggleMoreIconForLabel:self.cardReadingLabel forScrollView:self.cardReadingLabelScrollContainer];
  [self _toggleMoreIconForLabel:self.cardHeadwordLabel forScrollView:self.cardHeadwordLabelScrollContainer];
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
	self.cardReadingLabelScrollContainer = nil;
	self.cardHeadwordLabelScrollContainer = nil;
	self.cardHeadwordLabelScrollMoreIcon = nil;
	self.cardReadingLabelScrollMoreIcon = nil;
	self.cardHeadwordLabel = nil;
	self.cardReadingLabel = nil;
	self.toggleReadingBtn = nil;
	self.meaningWebView = nil;
  
	self.moodIcon = nil;
	self.moodIconBtn = nil;
	self.hhAnimationView = nil;
	self.percentCorrectLabel = nil;
	self.percentCorrectTalkBubble = nil;
}


- (void)dealloc 
{
  //moodicon
  [moodIcon release];
  [moodIconBtn release];
  [hhAnimationView release];
  [percentCorrectLabel release];
	[percentCorrectTalkBubble release];

  [baseHtml release];
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

NSString * const LWECardHtmlHeader = @""
"<html><head><meta http-equiv='Content-Type' content='text/html; charset=utf-8' />"
"<style>"
"body{ background-color: transparent; height:72px; display:table; margin:0px; padding:0px; text-align:center; line-height:21px; font-size:16px; font-weight:bold; font-family:Helvetica,sanserif; color:#fff; text-shadow:darkslategray 0px 1px 0px; } "
"dfn{ text-shadow:none; font-weight:normal; color:#000; position:relative; top:-1px; font-family:verdana; font-size:10.5px; background-color:#C79810; line-height:10.5px; margin:4px 4px 0px 0px; height:14px; padding:2px 3px; -webkit-border-radius:4px; border:1px solid #F9F7ED; display:inline-block;} "
"#container{width:300px; display:table-cell; vertical-align:middle;text-align:center;} "
"ol{color:white; text-align:left; width:240px; margin:0px; margin-left:24px; padding-left:10px;} "
"li{color:white; text-shadow:darkslategray 0px 1px 0px; margin:0px; margin-bottom:7px; line-height:17px;} "
"##THEMECSS##"
"</style></head>"
"<body><div id='container'>";

NSString * const LWECardHtmlHeader_EtoJ = @""
"<html><head><meta http-equiv='Content-Type' content='text/html; charset=utf-8' />"
"<style>"
"body{ background-color: transparent; height:72px; display:table; margin:0px; padding:0px; text-align:center; line-height:21px; font-size:16px; font-weight:bold; font-family:Helvetica,sanserif; color:#fff; text-shadow:darkslategray 0px 1px 0px; } "
"dfn{ text-shadow:none; font-weight:normal; color:#000; position:relative; top:-1px; font-family:verdana; font-size:10.5px; background-color:#C79810; line-height:10.5px; margin:4px 4px 0px 0px; height:14px; padding:2px 3px; -webkit-border-radius:4px; border:1px solid #F9F7ED; display:inline-block;} "
"#container{width:300px; display:table-cell; vertical-align:middle;text-align:center;font-size:34px; padding-left:3px; line-height:32px;} "
"ol{color:white; text-align:left; width:240px; margin:0px; margin-left:24px; padding-left:10px;} "
"li{color:white; text-shadow:darkslategray 0px 1px 0px; margin:0px; margin-bottom:7px; line-height:17px;} "
"##THEMECSS##"
"</style></head>"
"<body><div id='container'>";

NSString * const LWECardHtmlFooter = @"</div></body></html>";