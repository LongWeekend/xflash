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

extern NSString * const TOKENIZE_SAMPLE_SENTENCE;
extern NSString * const ADD_CARD_TO_SET;

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