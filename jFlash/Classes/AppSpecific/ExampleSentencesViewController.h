//
//  ExampleSentencesViewController.h
//  jFlash
//
//  Created by シャロット ロス on 6/5/10.
//  Copyright 2010 LONG WEEKEND INC.. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Card.h"
#import "Plugin.h"

typedef enum 
{
	TOKENIZE_SAMPLE_SENTENCE,
	ADD_CARD_TO_SET
} SampleSentenceMethods;

@interface ExampleSentencesViewController : UIViewController <UIWebViewDelegate>
{
  BOOL _useOldPluginMethods;
}

- (id) initWithExamplesPlugin:(Plugin *)plugin;

- (void) setupWithCard:(Card*)card;

@property (retain) NSMutableDictionary *sampleDecomposition;
@property (nonatomic, retain) IBOutlet UIWebView *sentencesWebView;

- (void)_showAddToSetWithCardID:(NSString *)cardID;
- (void)_showCardsForSentences:(NSString *)sentenceID isOpen:(NSString *)open webView:(UIWebView *)webView;

@end
