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

@interface ExampleSentencesViewController : UIViewController
{
  IBOutlet id delegate;
  IBOutlet id datasource;
  
  IBOutlet UIWebView *sentencesWebView;
}

- (void) setup;

@property (assign, nonatomic, readwrite) IBOutlet id delegate;
@property (assign, nonatomic, readwrite) IBOutlet id datasource;
@property (nonatomic, retain) IBOutlet UIWebView *sentencesWebView;

@end

//* Notification names
extern NSString  *exampleSentencesViewWillSetupNotification;
extern NSString  *exampleSentencesViewDidSetupNotification;

