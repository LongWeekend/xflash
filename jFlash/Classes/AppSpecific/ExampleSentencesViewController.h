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
#define SHOW_BUTTON_TITLE @"Read"
#define CLOSE_BUTTON_TITLE @"Close"
#define ADD_BUTTON_TITLE @"Add"

typedef enum 
{
	TOKENIZE_SAMPLE_SENTENCE,
	ADD_CARD_TO_SET
} SampleSentenceMethods;

/** datasource informal protocol.  Officially you don't have to provide a datasource but the view will be empty if you don't */
@protocol ExampleSentencesDataSource <NSObject>
- (Card*) currentCard;
@end

@interface ExampleSentencesViewController : UIViewController <UIWebViewDelegate>
{
  BOOL useOldPluginMethods;
}

- (id) initWithDataSource:(id<ExampleSentencesDataSource>)aDataSource;

- (void) setup;

@property (assign) IBOutlet id<ExampleSentencesDataSource> dataSource;
@property (nonatomic, retain) IBOutlet UIWebView *sentencesWebView;
@property (nonatomic, retain) NSMutableDictionary *sampleDecomposition;

- (void)_showAddToSetWithCardID:(NSString *)cardID;

- (void)_showCardsForSentences:(NSString *)sentenceID isOpen:(NSString *)open webView:(UIWebView *)webView;

@end

//* Notification names
extern NSString * const exampleSentencesViewWillSetupNotification;
extern NSString * const exampleSentencesViewDidSetupNotification;

