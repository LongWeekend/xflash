//
//  WordCardViewController.m
//  jFlash
//
//  Created by シャロット ロス on 6/3/10.
//  Copyright 2010 LONG WEEKEND INC.. All rights reserved.
//

#import "CardViewController.h"
#import "UIScrollView+LWEUtilities.h"
#import <AVFoundation/AVFoundation.h>

// Maps iOS system text size category to a CSS font-size string for WKWebView/UIWebView HTML.
static NSString *LWEDynamicTypeCSSFontSize(void)
{
  static NSDictionary *map = nil;
  if (!map) {
    map = [@{
      UIContentSizeCategoryExtraSmall:                            @"13px",
      UIContentSizeCategorySmall:                                 @"14px",
      UIContentSizeCategoryMedium:                                @"15px",
      UIContentSizeCategoryLarge:                                 @"16px",
      UIContentSizeCategoryExtraLarge:                            @"18px",
      UIContentSizeCategoryExtraExtraLarge:                       @"20px",
      UIContentSizeCategoryExtraExtraExtraLarge:                  @"22px",
      UIContentSizeCategoryAccessibilityMedium:                   @"26px",
      UIContentSizeCategoryAccessibilityLarge:                    @"30px",
      UIContentSizeCategoryAccessibilityExtraLarge:               @"34px",
      UIContentSizeCategoryAccessibilityExtraExtraLarge:          @"38px",
      UIContentSizeCategoryAccessibilityExtraExtraExtraLarge:     @"44px",
    } retain];
  }
  NSString *category = [UIApplication sharedApplication].preferredContentSizeCategory;
  return map[category] ?: @"16px";
}

// Scale factor relative to the default (Large) category, used to scale native label font sizes.
static CGFloat LWEDynamicTypeSizeMultiplier(void)
{
  static NSDictionary *map = nil;
  if (!map) {
    map = [@{
      UIContentSizeCategoryExtraSmall:                            @(0.82f),
      UIContentSizeCategorySmall:                                 @(0.88f),
      UIContentSizeCategoryMedium:                                @(0.94f),
      UIContentSizeCategoryLarge:                                 @(1.00f),
      UIContentSizeCategoryExtraLarge:                            @(1.06f),
      UIContentSizeCategoryExtraExtraLarge:                       @(1.12f),
      UIContentSizeCategoryExtraExtraExtraLarge:                  @(1.19f),
      UIContentSizeCategoryAccessibilityMedium:                   @(1.35f),
      UIContentSizeCategoryAccessibilityLarge:                    @(1.53f),
      UIContentSizeCategoryAccessibilityExtraLarge:               @(1.76f),
      UIContentSizeCategoryAccessibilityExtraExtraLarge:          @(1.94f),
      UIContentSizeCategoryAccessibilityExtraExtraExtraLarge:     @(2.35f),
    } retain];
  }
  NSString *category = [UIApplication sharedApplication].preferredContentSizeCategory;
  NSNumber *multiplier = map[category];
  return multiplier ? multiplier.floatValue : 1.0f;
}

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

#if defined(LWE_JFLASH)
- (AVSpeechSynthesisVoice *) _bestJapaneseVoice;
- (void) _updateSpeakBtnPosition;
@property (nonatomic, retain) AVSpeechSynthesizer *speechSynthesizer;
#endif
@end

@implementation CardViewController

@synthesize delegate;
@synthesize meaningWebViewContainer, headwordMoreIcon, headwordLabel, readingMoreIcon, readingLabel, toggleReadingBtn;
@synthesize readingScrollContainer, headwordScrollContainer, readingVisible = _readingVisible;
@synthesize baseHtml;
@synthesize moodIcon;
#if defined(LWE_JFLASH)
@synthesize speakBtn, speechSynthesizer;
#endif

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
    
    html = [html stringByReplacingOccurrencesOfString:@"##TEXTSIZE##" withString:LWEDynamicTypeCSSFontSize()];
    
    self.baseHtml = html;
  }
  return self;
}

- (void)viewDidLoad
{
  [super viewDidLoad];

  // Create the WKWebView programmatically inside the XIB-instantiated container.
  // (UIWebView is removed in modern iOS so we no longer instantiate it from the XIB.)
  WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
  _meaningWebView = [[WKWebView alloc] initWithFrame:self.meaningWebViewContainer.bounds
                                       configuration:config];
  [config release];
  _meaningWebView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  _meaningWebView.navigationDelegate = self;
  _meaningWebView.opaque = NO;
  _meaningWebView.backgroundColor = [UIColor clearColor];
  _meaningWebView.scrollView.backgroundColor = [UIColor clearColor];
  _meaningWebView.scrollView.bounces = NO;
  [self.meaningWebViewContainer addSubview:_meaningWebView];
  [_meaningWebView loadHTMLString:self.baseHtml baseURL:nil];

  // Add mood icon subview - TODO: MMA this is 90% complete, but I want to find a way to do this in the NIB
  CGRect moodIconRect = CGRectMake(235, 197, 80, 73);
  self.moodIcon.view.frame = moodIconRect;
  self.moodIcon.view.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin;
  [self.view addSubview:self.moodIcon.view];
  [self.moodIcon updateMoodIcon:100.0f];

  // For languages such as Chinese, we may need to configure the font
  self.headwordLabel.font = [Card configureFontForLabel:self.headwordLabel];

#if defined(LWE_JFLASH)
  self.speechSynthesizer = [[[AVSpeechSynthesizer alloc] init] autorelease];

  UIButton *speak = [UIButton buttonWithType:UIButtonTypeSystem];
  UIImage *speakerImg = [UIImage systemImageNamed:@"speaker.wave.2"];
  [speak setImage:speakerImg forState:UIControlStateNormal];
  speak.tintColor = [UIColor whiteColor];
  speak.accessibilityLabel = NSLocalizedString(@"Speak word", @"CardViewController.SpeakWordAccessibility");
  [speak addTarget:self action:@selector(doSpeakHeadword) forControlEvents:UIControlEventTouchUpInside];
  [self.view addSubview:speak];
  self.speakBtn = speak;
#endif
}

#pragma mark - Layout

- (void)layoutCardSubviews
{
  CGFloat w = self.view.bounds.size.width;
  CGFloat h = self.view.bounds.size.height;
  if (w <= 0 || h <= 0) return;

  CGFloat hPad = 10.0;
  CGFloat contentW = w - 2.0 * hPad;

  // Reading row at ~25% from top of card area so it lands near 30% of screen height.
  CGFloat readingY = MAX(20.0, roundf(h * 0.25));
  CGFloat readingH = 42.0;
  self.readingScrollContainer.frame = CGRectMake(hPad, readingY, contentW, readingH);
  self.readingMoreIcon.frame = CGRectMake(2.0, readingY + readingH - 17.0, 26.0, 17.0);
  // Toggle overlays the full reading row; positioned above the reveal-button zone
  // so it intercepts taps without triggering the definition reveal.
  self.toggleReadingBtn.frame = CGRectMake(hPad, readingY, contentW, readingH);

  // Headword immediately below reading.
  CGFloat headwordY = readingY + readingH + 4.0;
  CGFloat headwordH = 55.0;
  self.headwordScrollContainer.frame = CGRectMake(hPad, headwordY, contentW, headwordH);
  self.headwordMoreIcon.frame = CGRectMake(2.0, headwordY + headwordH - 17.0, 26.0, 17.0);
#if defined(LWE_JFLASH)
  [self _updateSpeakBtnPosition];
#endif

  // Meaning webview fills everything below the headword, giving it full space to the bottom.
  CGFloat webY = headwordY + headwordH + 8.0;
  CGFloat webH = MAX(60.0, h - webY - 8.0);
  self.meaningWebViewContainer.frame = CGRectMake(hPad, webY, contentW, webH);
}

#pragma mark - IBAction Methods

#if defined(LWE_JFLASH)

- (void)_updateSpeakBtnPosition
{
  CGRect container = self.headwordScrollContainer.frame;
  if (container.size.width <= 0 || self.headwordLabel.text.length == 0) return;

  // Text is center-aligned in the label; compute the visual right edge from intrinsic text width.
  CGSize textSize = [self.headwordLabel.text sizeWithAttributes:
                     @{NSFontAttributeName: self.headwordLabel.font}];
  CGFloat textWidth = MIN(textSize.width, container.size.width);
  CGFloat containerCenterX = container.origin.x + container.size.width / 2.0;
  CGFloat textRightEdge = containerCenterX + textWidth / 2.0;

  CGFloat btnSize = 36.0;
  CGFloat maxX = self.view.bounds.size.width - 2.0;
  CGFloat speakX = MIN(textRightEdge + 6.0, maxX - btnSize);
  CGFloat speakY = container.origin.y + roundf((container.size.height - btnSize) / 2.0);
  self.speakBtn.frame = CGRectMake(speakX, speakY, btnSize, btnSize);
}

- (AVSpeechSynthesisVoice *)_bestJapaneseVoice
{
  AVSpeechSynthesisVoice *enhanced = nil;
  for (AVSpeechSynthesisVoice *v in [AVSpeechSynthesisVoice speechVoices]) {
    if (![v.language isEqualToString:@"ja-JP"]) continue;
    if (@available(iOS 16.0, *)) {
      if (v.quality == AVSpeechSynthesisVoiceQualityPremium) return v;
    }
    if (v.quality == AVSpeechSynthesisVoiceQualityEnhanced) enhanced = v;
  }
  return enhanced ?: [AVSpeechSynthesisVoice voiceWithLanguage:@"ja-JP"];
}

- (IBAction)doSpeakHeadword
{
  // Reading label text is "kana - romaji"; speak only the kana part.
  NSString *reading = self.readingLabel.text;
  NSString *text = [[reading componentsSeparatedByString:@" - "] firstObject];
  if (text.length == 0) return;

  [self.speechSynthesizer stopSpeakingAtBoundary:AVSpeechBoundaryImmediate];

  AVSpeechUtterance *utterance = [AVSpeechUtterance speechUtteranceWithString:text];
  utterance.voice = [self _bestJapaneseVoice];
  utterance.rate = 0.4f;
  [self.speechSynthesizer speakUtterance:utterance];
}

#endif

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
  // Reset the meaning's scroll view location.
  _meaningWebView.scrollView.contentOffset = CGPointZero;
  
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
  CGFloat dtScale = LWEDynamicTypeSizeMultiplier();
  [self.readingLabel resizeWithMinFontSize:(NSInteger)(READING_MIN_FONTSIZE * dtScale) maxFontSize:(NSInteger)(READING_MAX_FONTSIZE * dtScale)];
  [self.headwordLabel resizeWithMinFontSize:(NSInteger)(HEADWORD_MIN_FONTSIZE * dtScale) maxFontSize:(NSInteger)(HEADWORD_MAX_FONTSIZE * dtScale)];
  
  // Now resize the scroll views as necessary based on the resized views above, if necessary.
  // This call also centers the label inside the scroll view.
  [self.readingScrollContainer resizeScrollViewWithContentView:self.readingLabel];
  [self.headwordScrollContainer resizeScrollViewWithContentView:self.headwordLabel];

  //[self _updateReadingContainer];
  self.headwordMoreIcon.hidden = [self _shouldHideMoreIconForLabel:self.headwordLabel
                                                     forScrollView:self.headwordScrollContainer];
#if defined(LWE_JFLASH)
  [self _updateSpeakBtnPosition];
#endif
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
  // The HTML will be encapsulated in Javascript, escape backslash, quote, and
  // newline so the resulting JS string literal stays well-formed for any
  // characters that might appear in card meanings.
  NSString *escapedHtml = [html stringByReplacingOccurrencesOfString:@"\\" withString:@"\\\\"];
  escapedHtml = [escapedHtml stringByReplacingOccurrencesOfString:@"'" withString:@"\\'"];
  escapedHtml = [escapedHtml stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n"];
  escapedHtml = [escapedHtml stringByReplacingOccurrencesOfString:@"\r" withString:@""];
  NSString *js = [NSString stringWithFormat:@"var textElement = document.getElementById('container'); if (textElement) { textElement.innerHTML = '%@'; }",escapedHtml];

  // Save a copy of this in case the webview hasn't finished loading yet
  // (see WKNavigationDelegate callback below).
  [_tmpJavascript release];
  _tmpJavascript = [js retain];

  [_meaningWebView evaluateJavaScript:js completionHandler:nil];
}


#pragma mark - WKNavigationDelegate

/**
 * The HTML template loads from a string and a JS-injection request can race the
 * load. If the JS was queued before the WebView finished loading, replay it now.
 */
- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation
{
  if (_tmpJavascript)
  {
    [_meaningWebView evaluateJavaScript:_tmpJavascript completionHandler:nil];
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
  self.meaningWebViewContainer = nil;
  self.moodIcon = nil;
#if defined(LWE_JFLASH)
  self.speakBtn = nil;
  self.speechSynthesizer = nil;
#endif
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

#if defined(LWE_JFLASH)
  [speakBtn release];
  [speechSynthesizer release];
#endif

  _meaningWebView.navigationDelegate = nil;
  [_meaningWebView release];
  [meaningWebViewContainer release];

  [super dealloc];
}

@end

// HTML Header content that will be displayed in the meaning UIWebView before the actual meaning
NSString * const LWECardHTMLTemplate = @""
"<html><head><meta http-equiv='Content-Type' content='text/html; charset=utf-8' />"
"<style>"
"body{ background-color:transparent; margin:0; padding:0; text-align:center; font-size:##TEXTSIZE##; font-weight:bold; font-family:Helvetica,sanserif; color:#fff; line-height:1.4; } "
"dfn{ text-shadow:none; font-weight:normal; color:#000; position:relative; top:-1px; font-family:verdana; font-size:10.5px; background-color:#C79810; line-height:1.4; margin:4px 4px 0px 0px; height:14px; padding:2px 3px; -webkit-border-radius:4px; border:1px solid #F9F7ED; display:inline-block;} "
"#container{ width:100%; text-align:center; padding-top:12px; } "
"ol{color:white; text-align:left; width:240px; margin:0px; margin-left:24px; padding-left:10px;} "
"li{color:white; margin:0px; margin-bottom:7px;} "
"##THEMECSS##"
"</style></head>"
"<body><div id='container'>"
"</div></body></html>";

NSString * const LWECardHTMLTemplate_EtoJ = @""
"<html><head><meta http-equiv='Content-Type' content='text/html; charset=utf-8' />"
"<style>"
"html,body{ height:100%; } "
"body{ background-color:transparent; display:-webkit-flex; display:flex; -webkit-justify-content:center; justify-content:center; -webkit-align-items:flex-start; align-items:flex-start; margin:0; padding:10px 0 0 0; box-sizing:border-box; font-size:##TEXTSIZE##; font-weight:bold; font-family:Helvetica,sanserif; color:#fff; line-height:1.4; } "
"dfn{ text-shadow:none; font-weight:normal; color:#000; position:relative; top:-1px; font-family:verdana; font-size:10.5px; background-color:#C79810; line-height:1.4; margin:4px 4px 0px 0px; height:14px; padding:2px 3px; -webkit-border-radius:4px; border:1px solid #F9F7ED; display:inline-block;} "
"#container{ width:100%; text-align:center; font-size:34px; padding-left:3px; line-height:1.4; } "
"ol{color:white; text-align:left; width:240px; margin:0px; margin-left:24px; padding-left:10px;} "
"li{color:white; margin:0px; margin-bottom:7px;} "
"##THEMECSS##"
"</style></head>"
"<body><div id='container'>"
"</div></body></html>";
