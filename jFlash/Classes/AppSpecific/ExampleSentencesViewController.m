//
//  ExampleSentencesViewController.m
//  jFlash
//
//  Created by シャロット ロス on 6/5/10.
//  Copyright 2010 LONG WEEKEND INC.. All rights reserved.
//

#import "ExampleSentencesViewController.h"

// Hack that I need this
#import "CardViewController.h"

#import "ExampleSentencePeer.h"
#import "UIWebView+LWENoBounces.h"
#import "NSURL+LWEUtilities.h"
#import "AddTagViewController.h"
#import "jFlashAppDelegate.h"

#define SHOW_BUTTON_TITLE NSLocalizedString(@"Read",@"ReadButton")
#define CLOSE_BUTTON_TITLE NSLocalizedString(@"Close",@"CloseButton")
#define ADD_BUTTON_TITLE NSLocalizedString(@"Add",@"AddButton")

@interface ExampleSentencesViewController ()
- (void)_showAddToSetWithCardID:(NSString *)cardID;
- (void)_showCardsForSentences:(NSString *)sentenceIDStr isOpen:(NSString *)open webView:(UIWebView *)webView;
@end

@implementation ExampleSentencesViewController
@synthesize sentencesWebView;
@synthesize sampleDecomposition;

#pragma mark - UIView subclass methods

- (id)initWithExamplesPlugin:(Plugin *)plugin
{
	if ((self = [super init]))
	{
    LWE_ASSERT_EXC([plugin.pluginId isEqualToString:EXAMPLE_DB_KEY], @"This class only knows how to deal with EXAMPLE_DB_KEY plugin");
		self.sampleDecomposition = [NSMutableDictionary dictionary];
    
    // What version of the example sentence plugin are we using?  If 1.1, it's old.
#if defined (LWE_JFLASH)
    _useOldPluginMethods = [plugin.version isEqualToString:@"1.1"];
    // I want to know if someone updated their example sentence version
#endif
    if (_useOldPluginMethods)
    {
      [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_pluginDidInstall:) name:LWEPluginDidInstall object:nil];
    }
	}
	return self;
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
  [super viewDidLoad];
  self.sentencesWebView.backgroundColor = [UIColor clearColor];
  [self.sentencesWebView shutOffBouncing];
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
  Plugin *installedPlugin = (Plugin *)aNotification.object;
  if ([installedPlugin.pluginId isEqualToString:EXAMPLE_DB_KEY] && [installedPlugin.version isEqualToString:@"1.1"])
  {
    _useOldPluginMethods = NO;
    [[NSNotificationCenter defaultCenter] removeObserver:self name:LWEPluginDidInstall object:nil];
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
      [html appendFormat:@"<div class='showWordsDiv'><a id='anchor%d' href='http://xflash.com/%d?id=%d&open=0'><span class='button'>%@</span></a></div>",
        sentence.sentenceId,TOKENIZE_SAMPLE_SENTENCE,sentence.sentenceId,SHOW_BUTTON_TITLE];
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
	AddTagViewController *tmpVC = [[AddTagViewController alloc] initWithCard:[CardPeer retrieveCardByPK:[cardID intValue]]];

	// Set up DONE button
	UIBarButtonItem *doneBtn = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Done", @"AddTagViewController.NavDoneButtonTitle") 
																style:UIBarButtonItemStyleBordered 
															   target:tmpVC
															   action:@selector(dismissModalViewControllerAnimated:)];

	tmpVC.navigationItem.leftBarButtonItem = doneBtn;
	NSDictionary *dict = [[NSDictionary alloc] initWithObjectsAndKeys:tmpVC, @"controller", nil];
	[[NSNotificationCenter defaultCenter] postNotificationName:LWEShouldShowModal object:self userInfo:dict];
	
	[doneBtn release];
	[tmpVC release];
	[dict release];
}

- (void)_showCardsForSentences:(NSString *)sentenceIDStr isOpen:(NSString *)open webView:(UIWebView *)webView
{
	NSString *js = nil;
  // TODO: WTF is this
	if ([open isEqualToString:@"1"])
	{
		//Close the expanded div. Return back the status of the expaned button
		js = [NSString stringWithFormat:@"document.getElementById('detailedCards%@').innerHTML = ''; ",sentenceIDStr];
		js = [js stringByAppendingFormat:@"document.getElementById('anchor%@').firstChild.innerHTML = '%@'; ",sentenceIDStr,SHOW_BUTTON_TITLE];
		js = [js stringByAppendingFormat:@"document.getElementById('anchor%@').href = 'http://xflash.com/%d?id=%@&open=0'; ",sentenceIDStr,TOKENIZE_SAMPLE_SENTENCE,sentenceIDStr];
		[webView stringByEvaluatingJavaScriptFromString:js];
	}
	else
	{
		//expand the sample sentence.
		//Try to look at the dictionary representative of the example decomposition in the memory, if its null, populate a new one,
		//if its not. it just takes the sample decomposition out from it.
		NSString *cardHTML = [self.sampleDecomposition objectForKey:sentenceIDStr];
		if (cardHTML == nil)
		{
			NSArray *arrayOfCards = [CardPeer retrieveCardSetForExampleSentenceId:[sentenceIDStr intValue]];
			cardHTML = @"<table class='ExpandedSentencesTable' cellpadding='5'>";
			NSString *lastHeadword = @"";
			for (Card *c in arrayOfCards)
			{
				cardHTML = [cardHTML stringByAppendingFormat:@"<tr class='HeadwordRow'>"];

        // This block keeps us from showing the same headword over and over when it just has multiple meanings
        NSString *cardHeadword = [c headwordIgnoringMode:YES];
				if ([cardHeadword isEqualToString:lastHeadword] == NO)
				{
					cardHTML = [cardHTML stringByAppendingFormat:@"<td class='HeadwordCell'>%@</td>",cardHeadword]; 
					lastHeadword = cardHeadword;
				}
				else 
				{
					cardHTML = [cardHTML stringByAppendingFormat:@"<td class='HeadwordCell'></td>"]; 
				}
				
				cardHTML = [cardHTML stringByAppendingFormat:@"<td class='ContentCell'>%@ </td><td><a href='http://xflash.com/%d?id=%d' class='AddToSetAnchor'><span class='button'>%@</span></a></td>", 
										c.reading,ADD_CARD_TO_SET,c.cardId,ADD_BUTTON_TITLE];
				cardHTML = [cardHTML stringByAppendingFormat:@"</tr>"];
			}
			
			cardHTML = [cardHTML stringByAppendingFormat:@"</table>"];
			[self.sampleDecomposition setObject:cardHTML forKey:sentenceIDStr];
		}
		
		//First, put the tokenized sample sentence to the detailedcard-"id" blank div.
		//then tries to change the anchor value, and the href query string. 
		js = [NSString stringWithFormat:@"document.getElementById('detailedCards%@').innerHTML = \"%@\";",sentenceIDStr,cardHTML];
		js = [js stringByAppendingFormat:@"document.getElementById('anchor%@').firstChild.innerHTML = '%@';",sentenceIDStr,CLOSE_BUTTON_TITLE];
		js = [js stringByAppendingFormat:@"document.getElementById('anchor%@').href = 'http://xflash.com/%d?id=%@&open=1';",sentenceIDStr,TOKENIZE_SAMPLE_SENTENCE,sentenceIDStr];
		
		[webView stringByEvaluatingJavaScriptFromString:js];
	}
}

#pragma mark - Class Plumbing

- (void)viewDidUnload
{
  [super viewDidUnload];
  self.sentencesWebView = nil;
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self name:LWEPluginDidInstall object:nil];
  [sentencesWebView release];
	[sampleDecomposition release];
  [super dealloc];
}

@end

NSString * const SENTENCES_HTML_HEADER = @""
"<!DOCTYPE html PUBLIC '-//W3C//DTD XHTML 1.0 Transitional//EN' 'http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd'>"
"<html><head><meta http-equiv='Content-Type' content='text/html; charset=utf-8' /><style>"
"body{ background-color: transparent; height:72px; display:table; margin:0px; padding:0px; text-align:left; line-height:21px; font-size:16px; font-weight:bold; font-family:Helvetica,sanserif; color:#fff; text-shadow:darkslategray 0px 1px 0px; } "
"dfn{ text-shadow:none; font-weight:normal; color:#000; position:relative; top:-1px; font-family:verdana; font-size:10.5px; background-color:#C79810; line-height:10.5px; margin:4px 4px 0px 0px; height:14px; padding:2px 3px; -webkit-border-radius:4px; border:1px solid #F9F7ED; display:inline-block;} "
".button{ font-size:14px; margin:2px 0px 2px 0px; padding: 2px 4px 3px 4px; display: inline; background: #777; border: none; color: #fff; font-weight: bold; border-radius: 3px; -moz-border-radius: 3px; -webkit-border-radius: 3px; text-shadow: 1px 1px #666; background: rgba(0,0,0,0.3);} "
".showWordsDiv { float: right; margin: 0px 5px 9px 9px; }"
"#container{width:315px; display:table-cell; vertical-align:middle;text-align:left;} "
"ol{color:white; text-shadow:#000 0px 1px 0px; text-align:left; width:265px; margin:0px; margin-left:19px; padding-left:10px;} "
"li{color:white; text-shadow:#000 0px 1px 0px; margin:0px; margin-bottom:17px; line-height:17px;} "
".lowlight {display:inline-block; margin-top:3px;color:#181818;text-shadow:none;font-weight:normal;} "
".readingLabel {font-size:14px;font-weight:bold; margin:3px 0px 0px 4px;} "
".headwordLabel {font-size:19px; margin:0px 0px 9px 4px;color:yellow;text-shadow:black 0px 1px 0px;} "
".ExpandedSentencesTable { width:250px; border-collapse:collapse; margin: 10px 0px 5px 0px;  } "
".AddToSetAnchor { float:right; } "
".ExpandedSentencesTable td { border-bottom:1px solid #CCC; border-collapse:collapse; border-top:1px solid #CCC } "
".HeadwordRow { height: 45px; } "
".HeadwordCell { vertical-align:middle; border-right:none; font-size:15px; width:100px; } "
".ContentCell { vertical-align:middle; border-left:none; font-size:14px; width:100px; } "
" a {text-decoration: none; } "
"##THEMECSS##</style></head>"
"<body><div id='container'>";