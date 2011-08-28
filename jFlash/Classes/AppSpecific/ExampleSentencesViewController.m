//
//  ExampleSentencesViewController.m
//  jFlash
//
//  Created by シャロット ロス on 6/5/10.
//  Copyright 2010 LONG WEEKEND INC.. All rights reserved.
//

#import "ExampleSentencesViewController.h"
#import "RootViewController.h"

// Hack that I need this
#import "WordCardViewController.h"

@implementation ExampleSentencesViewController
@synthesize sentencesWebView;
@synthesize sampleDecomposition;

#pragma mark - UIView subclass methods

- (id)init
{
	if ((self = [super init]))
	{
		self.sampleDecomposition = [NSMutableDictionary dictionary];
	}
	return self;
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
  [super viewDidLoad];

  self.sentencesWebView.backgroundColor = [UIColor clearColor];
  [self.sentencesWebView shutOffBouncing];
  
  // What version of the example sentence plugin are we using?  If 1.1, it's old.
  PluginManager *pm = [[CurrentState sharedCurrentState] pluginMgr];
  NSString *version = [pm versionForLoadedPlugin:EXAMPLE_DB_KEY];
  _useOldPluginMethods = [version isEqualToString:@"1.1"];

  // I want to know if someone updated their example sentence version
  if (_useOldPluginMethods)
  {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_pluginDidInstall:) name:LWEPluginDidInstall object:nil];
  }
}


#pragma mark - Private

/**
 * Callback for when a plugin is installed.  
 * If it's the example sentence DB, update the version
 * of this controller so we know which methods to use
 * (1.1 or 1.2)
 */
- (void) _pluginDidInstall:(NSNotification*)aNotification
{
  NSDictionary *dict = [aNotification userInfo];
  if ([[dict objectForKey:@"plugin_key"] isEqualToString:EXAMPLE_DB_KEY])
  {
    NSString *version = [dict objectForKey:@"plugin_version"];
    if (![version isEqualToString:@"1.1"])
    {
      _useOldPluginMethods = NO;
      [[NSNotificationCenter defaultCenter] removeObserver:self name:LWEPluginDidInstall object:nil];
    }
  }
}


#pragma mark - Core Methods

//* setup the example sentences view with information from the datasource
- (void) setupWithCard:(Card *)card
{
  NSMutableString *html = [[NSMutableString alloc] initWithFormat:@"<div class='readingLabel'>%@</div><h2 class='headwordLabel'>%@</h2><ol>",card.reading,card.headword];

  // Get all sentences out - extract this
  NSMutableArray *sentences = [ExampleSentencePeer getExampleSentencesByCardId:card.cardId];
  for (ExampleSentence *sentence in sentences) 
  {
    [html appendFormat:@"<li>"];
    // Only put this stuff in HTML if we have example sentences 1.2
    if (_useOldPluginMethods == NO)
    {
      [html appendFormat:@"<div class='showWordsDiv'><a id='anchor%d' href='%@/%d?id=%d&open=0'><span class='button'>%@</span></a></div>",sentence.sentenceId,kJFlashServer,TOKENIZE_SAMPLE_SENTENCE,sentence.sentenceId,SHOW_BUTTON_TITLE];
    }
    [html appendFormat:@"%@<br />",sentence.sentenceJa];
    
    // Only put this stuff in HTML if we have example sentences 1.2
    if (_useOldPluginMethods == NO)
    {
      [html appendFormat:@"<div id='detailedCards%d'></div>",sentence.sentenceId];
    }
    [html appendFormat:@"<div class='lowlight'>%@</div></li>",sentence.sentenceEn];
  }
  [html appendFormat:@"</ol>"];
  
  if ([self.sampleDecomposition count] > 0)
  {
    [self.sampleDecomposition removeAllObjects];
  }

  // Modify the inline CSS for current theme
  NSString *cssHeader = [[ThemeManager sharedThemeManager] currentThemeCSS];
  NSString *htmlHeader = [SENTENCES_HTML_HEADER stringByReplacingOccurrencesOfString:@"##THEMECSS##" withString:cssHeader]; 
  [self.sentencesWebView loadHTMLString:[NSString stringWithFormat:@"%@<span>%@</span>%@",htmlHeader,html,LWECardHtmlFooter] baseURL:nil];

  [html release];
}

#pragma mark - UIWebViewDelegate

- (BOOL) webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
	NSString *url = [[request URL] relativePath];
	//TODO: Make this better!!
	if ((url == nil)||([url isEqualToString:@"about:blank"]))
  {
		return YES;
  }

  NSDictionary *dict = [[request URL] queryStrings];

  NSRange slashPosition = [url rangeOfString:@"/"];
  if (slashPosition.location != NSNotFound)
  {
    url = [url substringFromIndex:slashPosition.location+1];
  }
  
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

- (void)_showAddToSetWithCardID:(NSString *)cardID
{
	LWE_LOG(@"Add to set with card ID : %@", cardID);
	// Set up DONE button
	UIBarButtonItem* doneBtn = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Done", @"AddTagViewController.NavDoneButtonTitle") 
																style:UIBarButtonItemStyleBordered 
															   target:self 
															   action:@selector(dismissAddToSetModal)];

	AddTagViewController *tmpVC = [[AddTagViewController alloc] initWithCard:[CardPeer retrieveCardByPK:[cardID intValue]]];
	tmpVC.navigationItem.leftBarButtonItem = doneBtn;
	NSDictionary *dict = [[NSDictionary alloc] initWithObjectsAndKeys:tmpVC, @"controller", nil];
	[[NSNotificationCenter defaultCenter] postNotificationName:LWEShouldShowModal object:self userInfo:dict];
	
	[doneBtn release];
	[tmpVC release];
	[dict release];
}

- (void)_showCardsForSentences:(NSString *)sentenceID isOpen:(NSString *)open webView:(UIWebView *)webView
{
	NSString *js = nil;
	if ([open isEqualToString:@"1"])
	{
		//Close the expanded div. Return back the status of the expaned button
		js = [NSString stringWithFormat:@"document.getElementById('detailedCards%@').innerHTML = ''; ",sentenceID];
		js = [js stringByAppendingFormat:@"document.getElementById('anchor%@').firstChild.innerHTML = '%@'; ",sentenceID,SHOW_BUTTON_TITLE];
		js = [js stringByAppendingFormat:@"document.getElementById('anchor%@').href = '%@/%d?id=%@&open=0'; ",sentenceID,kJFlashServer,TOKENIZE_SAMPLE_SENTENCE,sentenceID];
		[webView stringByEvaluatingJavaScriptFromString:js];
	}
	else
	{
		//expand the sample sentence.
		//Try to look at the dictionary representative of the example decomposition in the memory, if its null, populate a new one,
		//if its not. it just takes the sample decomposition out from it.
		NSString *cardHTML = [self.sampleDecomposition objectForKey:sentenceID];
		if (cardHTML == nil)
		{
			NSArray *arrayOfCards = [CardPeer retrieveCardSetForExampleSentenceID:[sentenceID intValue]];
			cardHTML = @"<table class='ExpandedSentencesTable' cellpadding='5'>";
			NSString *headWord = @"";
			for (Card *c in arrayOfCards)
			{
				cardHTML = [cardHTML stringByAppendingFormat:@"<tr class='HeadwordRow'>"];
				
				if (![[c headword] isEqualToString:headWord])
				{
					cardHTML = [cardHTML stringByAppendingFormat:@"<td class='HeadwordCell'>%@</td>", [c headword]]; 
					headWord = [c headword];
				}
				else 
				{
					cardHTML = [cardHTML stringByAppendingFormat:@"<td class='HeadwordCell'></td>"]; 
				}
				
				cardHTML = [cardHTML stringByAppendingFormat:@"<td class='ContentCell'>%@ </td><td><a href='%@/%d?id=%d' class='AddToSetAnchor'><span class='button'>%@</span></a></td>", 
										[c reading], kJFlashServer, ADD_CARD_TO_SET, [c cardId], ADD_BUTTON_TITLE];
				cardHTML = [cardHTML stringByAppendingFormat:@"</tr>"];
			}
			
			cardHTML = [cardHTML stringByAppendingFormat:@"</table>"];
			[self.sampleDecomposition setObject:cardHTML forKey:sentenceID];
		}
		
		//First, put the tokenized sample sentence to the detailedcard-"id" blank div.
		//then tries to change the anchor value, and the href query string. 
		js = [NSString stringWithFormat:@"document.getElementById('detailedCards%@').innerHTML = \"%@\";", sentenceID, cardHTML];
		js = [js stringByAppendingFormat:@"document.getElementById('anchor%@').firstChild.innerHTML = '%@';", sentenceID,CLOSE_BUTTON_TITLE];
		js = [js stringByAppendingFormat:@"document.getElementById('anchor%@').href = '%@/%d?id=%@&open=1';", 
			  sentenceID, kJFlashServer, TOKENIZE_SAMPLE_SENTENCE, sentenceID];
		
		[webView stringByEvaluatingJavaScriptFromString:js];
	}
}

- (void)dismissAddToSetModal
{
  NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"YES" forKey:@"animated"];
	[[NSNotificationCenter defaultCenter] postNotificationName:LWEShouldDismissModal object:self userInfo:userInfo];
}

#pragma mark - Class Plumbing

- (void)viewDidUnload
{
	//Rendy added this in regards on memory warning, and there has been an obeserver that is registered in the viewDidLoad (Avoid the observer registered twice)
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self name:LWEPluginDidInstall object:nil];
  [sentencesWebView release];
	[sampleDecomposition release];
  [super dealloc];
}

@end