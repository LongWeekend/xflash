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

// These are strings that will be used in the UIWebView's links, then as delegate we 
// intercept those links and determine what "button" the user tapped.  Similar to a UIView
// tag in the way we use it.
extern NSString * const TOKENIZE_SAMPLE_SENTENCE;
extern NSString * const ADD_CARD_TO_SET;

// The HTML template we show the example sentences in.
extern NSString * const LWESentencesHTML;

@interface ExampleSentencesViewController : UIViewController <UIWebViewDelegate>
{
  BOOL _useOldPluginMethods;
}

- (id) initWithExamplesPlugin:(Plugin *)plugin;
- (void) setupWithCard:(Card*)card;

@property (retain) NSMutableDictionary *sampleDecomposition;
@property (nonatomic, retain) IBOutlet UIWebView *sentencesWebView;

@end