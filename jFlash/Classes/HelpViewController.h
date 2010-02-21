//
//  HelpViewController.h
//  jFlash
//
//  Created by シャロット ロス on 12/28/09.
//  Copyright 2009 LONG WEEKEND INC.. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface HelpViewController : UIViewController <UIWebViewDelegate> {
  UIView *baseView;
  UIWebView *htmlView;
}

- (void)loadWebView;

@property (nonatomic, retain) UIView *baseView;
@property (nonatomic, retain) UIWebView *htmlView;
@end
