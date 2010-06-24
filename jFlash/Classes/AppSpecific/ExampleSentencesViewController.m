//
//  ExampleSentencesViewController.m
//  jFlash
//
//  Created by シャロット ロス on 6/5/10.
//  Copyright 2010 LONG WEEKEND INC.. All rights reserved.
//

#import "ExampleSentencesViewController.h"

@interface NSObject (ExampleSentencesDelegateSupport)
// setup
- (void)exampleSentencesViewWillSetup:(NSNotification *)aNotification;
- (void)exampleSentencesViewDidSetup:(NSNotification *)aNotification;

@end

/** datasource informal protocol.  Officially you don't have to provide a datasource but the view will be empty if you don't */
@interface NSObject (ExampleSentencesDatasourceSupport)
- (Card*) currentCard;
@end


@implementation ExampleSentencesViewController
@synthesize delegate, datasource;
@synthesize sentencesWebView, headwordLabel;

#pragma mark -
#pragma mark Delegate Methods

- (void)_exampleSentencesViewWillSetup
{
  NSNotification *notification = [NSNotification notificationWithName: exampleSentencesViewWillSetupNotification object:self];
  
  // send the selector to the delegate if it responds
  if([[self delegate] respondsToSelector:@selector(exampleSentencesViewWillSetup:)])
  {
    [[self delegate] exampleSentencesViewWillSetup:notification];
  }
  
  //in case something else cares.  Seems to be the pattern from the book but I don't know if we really need this
  [[NSNotificationCenter defaultCenter] postNotification:notification];
}

- (void)_exampleSentencesViewDidSetup
{
  NSNotification *notification = [NSNotification notificationWithName: exampleSentencesViewDidSetupNotification object:self];
  
  // send the selector to the delegate if it responds
  if([[self delegate] respondsToSelector:@selector(exampleSentencesViewDidSetup:)])
  {
    [[self delegate] exampleSentencesViewDidSetup:notification];
  }
  
  //in case something else cares.  Seems to be the pattern from the book but I don't know if we really need this
  [[NSNotificationCenter defaultCenter] postNotification:notification];
}

#pragma mark -
#pragma mark UIView subclass methods

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
  [super viewDidLoad];

  sentencesWebView.backgroundColor = [UIColor clearColor];
  UIScrollView *scrollView = [sentencesWebView.subviews objectAtIndex:0];
  
  SEL aSelector = NSSelectorFromString(@"setAllowsRubberBanding:");
  if([scrollView respondsToSelector:aSelector])
  {
    [scrollView performSelector:aSelector withObject:NO];
  }
}

#pragma mark -
#pragma mark Core Methods

- (void) setupSentencesWebView:(NSString *)sentencesHTML
{  
  // Modify the inline CSS for current theme
  NSString *cssHeader = [[ThemeManager sharedThemeManager] currentThemeCSS];
  NSString *htmlHeader = [SENTENCES_HTML_HEADER stringByReplacingOccurrencesOfString:@"##THEMECSS##" withString:cssHeader];  
  
  NSString *html = [NSString stringWithFormat:@"%@<span>%@</span>%@", htmlHeader, sentencesHTML, HTML_FOOTER];
  
  // shut off rubber banding if we can
  UIScrollView *scrollView = [self.sentencesWebView.subviews objectAtIndex:0];
  SEL aSelector = NSSelectorFromString(@"setAllowsRubberBanding:");
  if([scrollView respondsToSelector:aSelector])
  {
    [scrollView performSelector:aSelector withObject:NO];
  }
  
  [self.sentencesWebView loadHTMLString:html baseURL:nil];
}

//* setup the example sentences view with information from the datasource
- (void) setup
{
  [self _exampleSentencesViewWillSetup];
  
  // the datasource must implement currentcard or we don't set any data
  if([datasource respondsToSelector:@selector(currentCard)])
  {
    NSString* mungedHeadWordWithReading = [[NSString alloc] initWithFormat:@"%@ (%@)", [[datasource currentCard] headword], [[datasource currentCard] combinedReadingForSettings]];
    [[self headwordLabel] setText: mungedHeadWordWithReading];
    
    // Get all sentences out - extract this
    NSMutableArray* sentences = [ExampleSentencePeer getExampleSentencesByCardId:[[datasource currentCard] cardId]];
    NSString* html = @"<ol>";
    for (ExampleSentence* sentence in sentences) 
    {
      html = [html stringByAppendingFormat:@"<li>%@<br/>", [sentence sentenceJa]];
      html = [html stringByAppendingFormat:@"%@</li>", [sentence sentenceEn]];
    }
    html = [html stringByAppendingString:@"</ol>"];
    [self setupSentencesWebView:html];
  }
  
  [self _exampleSentencesViewDidSetup];
}

#pragma mark -
#pragma mark Class Plumbing

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
    [sentencesWebView release];
    [headwordLabel release];
    // we don't release datasources and delegates because we don't retain them (hands off shit you don't own)
    [super dealloc];
}


@end
     
NSString  *exampleSentencesViewWillSetupNotification = @"exampleSentencesViewWillSetupNotification";
NSString  *exampleSentencesViewDidSetupNotification = @"exampleSentencesViewDidSetupNotification";