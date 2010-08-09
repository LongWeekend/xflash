//
//  ExampleSentencesViewController.m
//  jFlash
//
//  Created by シャロット ロス on 6/5/10.
//  Copyright 2010 LONG WEEKEND INC.. All rights reserved.
//

#import "ExampleSentencesViewController.h"
#import "RootViewController.h"

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
@synthesize sampleDecomposition;

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
  
  // What version of the example sentence plugin are we using?  If 1.1, it's old.
  PluginManager *pm = [[CurrentState sharedCurrentState] pluginMgr];
  NSString *version = [pm versionForLoadedPlugin:EXAMPLE_DB_KEY];
  if ([version isEqualToString:@"1.1"])
  {
    useOldPluginMethods = YES;
    // I want to know if someone updated their example sentence version
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_pluginDidInstall:) name:LWEPluginDidInstall object:nil];
  }
  else
  {
    useOldPluginMethods = NO;
  }
}


#pragma mark -
#pragma mark Private

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
      useOldPluginMethods = NO;
      [[NSNotificationCenter defaultCenter] removeObserver:self name:LWEPluginDidInstall object:nil];
    }
  }
}


#pragma mark -
#pragma mark Core Methods

- (void) setupSentencesWebView:(NSString *)sentencesHTML
{  
  // Modify the inline CSS for current theme
  NSString *cssHeader = [[ThemeManager sharedThemeManager] currentThemeCSS];
	LWE_LOG(@"CSS : %@", cssHeader);
  NSString *htmlHeader = [SENTENCES_HTML_HEADER stringByReplacingOccurrencesOfString:@"##THEMECSS##" withString:cssHeader]; 
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
    NSMutableArray* sentences = [ExampleSentencePeer getExampleSentencesByCardId:[[datasource currentCard] cardId] showAll:!useOldPluginMethods];
		
		NSString* html = [NSString stringWithFormat: @"<div class='readingLabel'>%@</div>", [[datasource currentCard] combinedReadingForSettings]];    
    html = [html stringByAppendingFormat:@"<h2 class='headwordLabel'>%@</h2>", [[datasource currentCard] headword]];
    html = [html stringByAppendingFormat:@"<ol>"];

	  int counter = 0;
    for (ExampleSentence* sentence in sentences) 
    {
			html = [html stringByAppendingFormat:@"<li>%@", [sentence sentenceJa]];
			//TODO: Change the Expand <dfn> tag to image?
      
      // Only put this stuff in HTML if we have example sentences 1.2
      if (!useOldPluginMethods)
      {
        html = [html stringByAppendingFormat:@"<a id='anchor%d' href='%@/%d?id=%d&open=0'><dfn>Expand</dfn></a><br/>", 
                [sentence sentenceId], kJFlashServer, TOKENIZE_SAMPLE_SENTENCE, [sentence sentenceId]];
        html = [html stringByAppendingFormat:@"<div id='detailedCards%d'></div>", [sentence sentenceId]];
      }
      
			html = [html stringByAppendingFormat:@"<div class='lowlight'>%@</div>", [sentence sentenceEn] ];
			html = [html stringByAppendingFormat:@"</li>"];
			counter++;
    }
    html = [html stringByAppendingString:@"</ol>"];
	  sampleDecomposition = [[NSMutableDictionary alloc] initWithCapacity:counter];
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
  
  UINavigationController *tmpNavController = [[UINavigationController alloc] initWithRootViewController:tmpVC];
  [tmpVC release];
	
	// Set up DONE button
	UIBarButtonItem* doneBtn = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Done", @"AddTagViewController.NavDoneButtonTitle") 
																style:UIBarButtonItemStyleBordered 
															   target:self 
															   action:@selector(dismissAddToSetModal)];
	tmpVC.navigationItem.leftBarButtonItem = doneBtn;
	NSDictionary *dict = [[NSDictionary alloc]
						  initWithObjectsAndKeys:tmpNavController, @"controller", @"YES", @"animated", nil];
	[[NSNotificationCenter defaultCenter] postNotificationName:LWEShouldShowModal object:self userInfo:dict];
	
	[doneBtn release];
	[tmpNavController release];
	[dict release];
}

- (void)_showCardsForSentences:(NSString *)sentenceID isOpen:(NSString *)open webView:(UIWebView *)webView
{
	NSString *js;
	if ([open isEqualToString:@"1"])
	{
		//Close the expanded div. Return back the status of the expaned button
		js = [NSString stringWithFormat:@"document.getElementById('detailedCards%@').innerHTML = ''; ", sentenceID];
		//TODO: Change the Expand tag to image?
		//js = [js stringByAppendingFormat:@"document.getElementById('anchor%@').firstChild.src = '%@'; ", sentenceID, [imagePath]];
		js = [js stringByAppendingFormat:@"document.getElementById('anchor%@').firstChild.innerHTML = 'Expand'; ", sentenceID];
		js = [js stringByAppendingFormat:@"document.getElementById('anchor%@').href = '%@/%d?id=%@&open=0'; ", 
			  sentenceID, kJFlashServer, TOKENIZE_SAMPLE_SENTENCE, sentenceID];
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
			NSDate *start = [NSDate date];
			NSArray *arrayOfCards = [CardPeer retrieveCardSetForExampleSentenceID:[sentenceID intValue] showAll:!useOldPluginMethods];
			cardHTML = @"<table class='ExpandedSentencesTable' cellpadding='5'>";
			NSString *headWord = @"";
			for (Card *c in arrayOfCards)
			{
				cardHTML = [cardHTML stringByAppendingFormat:@"<tr>"];
				LWE_LOG(@"Head Word : %@", headWord);
				if (![[c headword] isEqualToString:headWord])
				{
					cardHTML = [cardHTML stringByAppendingFormat:@"<td class='HeadwordCell'>%@</td>", [c headword]]; 
					headWord = [c headword];
				}
				else 
				{
					cardHTML = [cardHTML stringByAppendingFormat:@"<td class='HeadwordCell'></td>"]; 
				}
				//TODO: Change the add <dfn> tag to image?
				cardHTML = [cardHTML stringByAppendingFormat:@"<td class='ContentCell'>[%@] <a href='%@/%d?id=%d' class='AddToSetAnchor'><dfn>Add</dfn></a></td>", 
										[c readingBasedonSettingsForExpandedSampleSentences], kJFlashServer, ADD_CARD_TO_SET, [c cardId]];
				cardHTML = [cardHTML stringByAppendingFormat:@"</tr>"];
			}
			
			cardHTML = [cardHTML stringByAppendingFormat:@"</table>"];
			[self.sampleDecomposition setObject:cardHTML forKey:sentenceID];
			
			double d = [[NSDate date] timeIntervalSince1970] - [start timeIntervalSince1970];
			LWE_LOG(@"Time : %f", d);
		}
		
		//NSDate *start = [NSDate date];
		LWE_LOG(@"Card HTML : %@", cardHTML);
		//First, put the tokenized sample sentence to the detailedcard-"id" blank div.
		//then tries to change the anchor value, and the href query string. 
		js = [NSString stringWithFormat:@"document.getElementById('detailedCards%@').innerHTML = \"%@\";", sentenceID, cardHTML];
		js = [js stringByAppendingFormat:@"document.getElementById('anchor%@').firstChild.innerHTML = 'Close';", sentenceID];
		js = [js stringByAppendingFormat:@"document.getElementById('anchor%@').href = '%@/%d?id=%@&open=1';", 
			  sentenceID, kJFlashServer, TOKENIZE_SAMPLE_SENTENCE, sentenceID];
		
		[webView stringByEvaluatingJavaScriptFromString:js];
		
		//double d = [[NSDate date] timeIntervalSince1970] - [start timeIntervalSince1970];
		//LWE_LOG(@"Time : %f", d);
	}
}

- (void)dismissAddToSetModal
{
	[[NSNotificationCenter defaultCenter] postNotificationName:LWEShouldDismissModal object:self userInfo:nil];
}

#pragma mark -
#pragma mark Class Plumbing

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self name:LWEPluginDidInstall object:nil];
  [sentencesWebView release];
	[sampleDecomposition release];
  // we don't release datasources and delegates because we don't retain them (hands off shit you don't own)
  [super dealloc];
}


@end
     
NSString * const exampleSentencesViewWillSetupNotification = @"exampleSentencesViewWillSetupNotification";
NSString * const exampleSentencesViewDidSetupNotification = @"exampleSentencesViewDidSetupNotification";
