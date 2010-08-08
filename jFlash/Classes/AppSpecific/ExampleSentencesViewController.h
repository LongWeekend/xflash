//
//  ExampleSentencesViewController.h
//  jFlash
//
//  Created by シャロット ロス on 6/5/10.
//  Copyright 2010 LONG WEEKEND INC.. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ExampleSentencePeer.h"
#import "UIWebView+LWENoBounces.h"
#import "NSURL+LWEUtilities.h"
#import "AddTagViewController.h"
#import "jFlashAppDelegate.h"

#define kJFlashServer	@"http://jflash.com"

typedef enum 
{
	TOKENIZE_SAMPLE_SENTENCE,
	ADD_CARD_TO_SET
} SampleSentenceMethods;

@interface ExampleSentencesViewController : UIViewController <UIWebViewDelegate>
{
  IBOutlet id delegate;
  IBOutlet id datasource;
  
  IBOutlet UIWebView *sentencesWebView;
  NSMutableDictionary *sampleDecomposition;
  
  BOOL useOldPluginMethods;
}

- (void) setup;

@property (assign, nonatomic, readwrite) IBOutlet id delegate;
@property (assign, nonatomic, readwrite) IBOutlet id datasource;
@property (nonatomic, retain) IBOutlet UIWebView *sentencesWebView;
@property (nonatomic, retain) NSMutableDictionary *sampleDecomposition;

- (void)_showAddToSetWithCardID:(NSString *)cardID;

- (void)_showCardsForSentences:(NSString *)sentenceID isOpen:(NSString *)open webView:(UIWebView *)webView;

@end

//* Notification names
extern NSString * const exampleSentencesViewWillSetupNotification;
extern NSString * const exampleSentencesViewDidSetupNotification;

