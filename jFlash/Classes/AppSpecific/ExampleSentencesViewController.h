//
//  ExampleSentencesViewController.h
//  jFlash
//
//  Created by シャロット ロス on 6/5/10.
//  Copyright 2010 LONG WEEKEND INC.. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>
#import "Card.h"
#import "Plugin.h"

// Strings used as fake URL paths in WKWebView links to intercept button taps.
extern NSString * const TOKENIZE_SAMPLE_SENTENCE;
extern NSString * const ADD_CARD_TO_SET;
extern NSString * const SPEAK_SENTENCE;

// The HTML template we show the example sentences in.
extern NSString * const LWESentencesHTML;

@interface ExampleSentencesViewController : UIViewController <WKNavigationDelegate>
{
  BOOL _useOldPluginMethods;
}

- (id) initWithExamplesPlugin:(Plugin *)plugin;
- (void) setupWithCard:(Card*)card;

@property (retain) NSMutableDictionary *sampleDecomposition;
@property (nonatomic, retain) WKWebView *sentencesWebView;

@end