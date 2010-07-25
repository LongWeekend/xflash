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
@synthesize sentencesWebView;

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
  [self.sentencesWebView shutOffBouncing];
}

#pragma mark -
#pragma mark Core Methods

- (void) setupSentencesWebView:(NSString *)sentencesHTML
{  
  // Modify the inline CSS for current theme
  NSString *cssHeader = [[ThemeManager sharedThemeManager] currentThemeCSS];
	LWE_LOG(@"CSS : %@", cssHeader);
  NSString *htmlHeader = [SENTENCES_HTML_HEADER stringByReplacingOccurrencesOfString:@"##THEMECSS##" withString:cssHeader]; 
	
	LWE_LOG(@"HTML HEADER : %@", htmlHeader);
  
  NSString *html = [NSString stringWithFormat:@"%@<span>%@</span>%@", htmlHeader, sentencesHTML, HTML_FOOTER];
  
  [self.sentencesWebView loadHTMLString:html baseURL:nil];
}

//* setup the example sentences view with information from the datasource
- (void) setup
{
  [self _exampleSentencesViewWillSetup];
  
  // the datasource must implement currentcard or we don't set any data
  if([datasource respondsToSelector:@selector(currentCard)])
  {    
    // Get all sentences out - extract this
    NSMutableArray* sentences = [ExampleSentencePeer getExampleSentencesByCardId:[[datasource currentCard] cardId]];
    
	  
	  NSString* html = [NSString stringWithFormat: @"<div class='readingLabel'>%@</div>", [[datasource currentCard] combinedReadingForSettings]];
	  
	  
	  //html = [html stringByAppendingFormat:@"<script type='text/javascript'>function btnShowWord_Clicked() { alert('GG'); }</script>"];     
    html = [html stringByAppendingFormat:@"<h2 class='headwordLabel'>%@</h2>", [[datasource currentCard] headword]];
    html = [html stringByAppendingFormat:@"<ol>"];

    for (ExampleSentence* sentence in sentences) 
    {
		
      html = [html stringByAppendingFormat:@"<li>%@", [sentence sentenceJa]];
		
		html = [html stringByAppendingFormat:@"<a id='anchor%d' href='%@/%d?id=%d&open=0'><dfn>Expand</dfn></a><br/>", 
				[sentence sentenceId], kJFlashServer, TOKENIZE_SAMPLE_SENTENCE, [sentence sentenceId]];
		
      html = [html stringByAppendingFormat:@"<div class='lowlight'>%@</div>", [sentence sentenceEn] ];
		
		html = [html stringByAppendingFormat:@"<div id='detailedCards%d'></div>", [sentence sentenceId]];
		
		
		
		/*html = [html stringByAppendingFormat:@"<form method='GET' action='http://flash.com'>"];
		html = [html stringByAppendingFormat:@"<input type='hidden' value='%d' id='id%d' name='id' />", [sentence sentenceId], [sentence sentenceId]];
		html = [html stringByAppendingFormat:@"<input type='hidden' value='0' id='open%d' name='open' />", [sentence sentenceId]];
		html = [html stringByAppendingFormat:@"<input type='submit' id='submit%d' value='Reading' />", [sentence sentenceId]];
		html = [html stringByAppendingFormat:@"</form>"];*/
		
		
		html = [html stringByAppendingFormat:@"</li>"];
    }
    html = [html stringByAppendingString:@"</ol>"];

    [self setupSentencesWebView:html];
  }
  
  [self _exampleSentencesViewDidSetup];
}

#pragma mark -
#pragma mark UIWebViewDelegate

- (BOOL) webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
	NSString *url = [[request URL] relativePath];
	LWE_LOG(@"LOG : Load URL with relative path : %@", url);
	//TODO: Make this better!!
	if ((url == nil)||([url isEqualToString:@"about:blank"]))
		return YES;
	else
	{
		NSDictionary *dict = [[request URL] queryStrings];
		
		NSRange slashPosition = [url rangeOfString:@"/"];
		if (slashPosition.location != NSNotFound)
			url = [url substringFromIndex:slashPosition.location+1];
		
		switch ([url intValue]) 
		{
			case TOKENIZE_SAMPLE_SENTENCE:
				[self _showCardsForSentences:[dict objectForKey:@"id"] isOpen:[dict objectForKey:@"open"] webView:webView];
				break;
			case ADD_CARD_TO_SET:
				[self _showAddToSetWithCardID:[dict objectForKey:@"id"]];
				break;
			default:
				break;
		}
		return NO;
	}
}

- (void)_showAddToSetWithCardID:(NSString *)cardID
{
	LWE_LOG(@"Add to set with card ID : %@", cardID);
	AddTagViewController *tmpVC = [[AddTagViewController alloc] initWithCard:[CardPeer retrieveCardByPK:[cardID intValue]]];
	
	// Set up DONE button
	UIBarButtonItem* doneBtn = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Done", @"AddTagViewController.NavDoneButtonTitle") 
																style:UIBarButtonItemStyleBordered 
															   target:self 
															   action:@selector(dismissAddToSetModal)];
	tmpVC.navigationItem.leftBarButtonItem = doneBtn;
	[doneBtn release];
	
	NSDictionary *dict = [[NSDictionary alloc]
						  initWithObjectsAndKeys:tmpVC, @"controller", @"YES", @"animated", nil];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"shouldShowModal" object:self userInfo:dict];
}

- (void)_showCardsForSentences:(NSString *)sentenceID isOpen:(NSString *)open webView:(UIWebView *)webView
{
	NSString *js;
	if ([open isEqualToString:@"1"])
	{
		//Close the expanded div. Return back the status of the expaned button
		js = [NSString stringWithFormat:@"document.getElementById('detailedCards%@').innerHTML = ''; ", sentenceID];
		js = [js stringByAppendingFormat:@"document.getElementById('anchor%@').firstChild.innerHTML = 'Expand'; ", sentenceID];
		js = [js stringByAppendingFormat:@"document.getElementById('anchor%@').href = '%@/%d?id=%@&open=0'; ", 
			  sentenceID, kJFlashServer, TOKENIZE_SAMPLE_SENTENCE, sentenceID];
		[webView stringByEvaluatingJavaScriptFromString:js];
	}
	else 
	{
		//expand the sample sentence.
		NSMutableArray *arrayOfCards = [CardPeer retrieveCardSetForExampleSentenceID:[sentenceID intValue]];
		NSString *cardHTML = @"<ul>";
		for (Card *c in arrayOfCards)
		{
			LWE_LOG(@"English Head Word : %@, Head word : %@", [c headword_en], [c headword]);
			cardHTML = [cardHTML stringByAppendingFormat:@"<li>"];
			cardHTML = [cardHTML stringByAppendingFormat:@"%@ [%@]", [c headword], [c combinedReadingForSettings]]; 
			cardHTML = [cardHTML stringByAppendingFormat:@"<a href='%@/%d?id=%d'><dfn>Add to set</dfn></a></li>",  kJFlashServer, ADD_CARD_TO_SET, [c cardId]];
			cardHTML = [cardHTML stringByAppendingFormat:@"</li>"];
		}
		cardHTML = [cardHTML stringByAppendingFormat:@"</ul>"];
		
		//First, put the tokenized sample sentence to the detailedcard-"id" blank div.
		//then tries to change the anchor value, and the href query string. 
		js = [NSString stringWithFormat:@"document.getElementById('detailedCards%@').innerHTML = \"%@\";", sentenceID, cardHTML];
		js = [js stringByAppendingFormat:@"document.getElementById('anchor%@').firstChild.innerHTML = 'Close';", sentenceID];
		js = [js stringByAppendingFormat:@"document.getElementById('anchor%@').href = '%@/%d?id=%@&open=1';", 
			  sentenceID, kJFlashServer, TOKENIZE_SAMPLE_SENTENCE, sentenceID];
		
		[webView stringByEvaluatingJavaScriptFromString:js];
	}
	
}

- (void)dismissAddToSetModal
{
	[[NSNotificationCenter defaultCenter] postNotificationName:@"shouldDismissModal" object:self userInfo:nil];
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
    // we don't release datasources and delegates because we don't retain them (hands off shit you don't own)
    [super dealloc];
}


@end
     
NSString  *exampleSentencesViewWillSetupNotification = @"exampleSentencesViewWillSetupNotification";
NSString  *exampleSentencesViewDidSetupNotification = @"exampleSentencesViewDidSetupNotification";
