//
//  ExampleSentencesViewController.h
//  jFlash
//
//  Created by シャロット ロス on 6/5/10.
//  Copyright 2010 LONG WEEKEND INC.. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Card.h"
#import "ExampleSentencePeer.h"
#import "UIWebView+LWENoBounces.h"
#import "NSURL+LWEUtilities.h"
#import "AddTagViewController.h"
#import "jFlashAppDelegate.h"

#define kJFlashServer	@"http://jflash.com"
#define SHOW_BUTTON_TITLE @"Read"
#define CLOSE_BUTTON_TITLE @"Close"
#define ADD_BUTTON_TITLE @"Add"

typedef enum 
{
	TOKENIZE_SAMPLE_SENTENCE,
	ADD_CARD_TO_SET
} SampleSentenceMethods;

@interface ExampleSentencesViewController : UIViewController <UIWebViewDelegate>
{
  BOOL _useOldPluginMethods;
}

- (void) setupWithCard:(Card*)card;

@property (retain) NSMutableDictionary *sampleDecomposition;
@property (nonatomic, retain) IBOutlet UIWebView *sentencesWebView;

- (void)_showAddToSetWithCardID:(NSString *)cardID;
- (void)_showCardsForSentences:(NSString *)sentenceID isOpen:(NSString *)open webView:(UIWebView *)webView;

@end
