//
//  RootViewController.h
//  jFlash
//
//  Created by Mark Makdad on 2/20/10.
//  Copyright 2010 LONG WEEKEND INC.. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "PDColoredProgressView.h"

@protocol InitializationDelegate <NSObject>
@optional
- (void)appInitDidComplete;
@end

@interface RootViewController : UIViewController
{
	id<InitializationDelegate> delegate;
	PDColoredProgressView *loadingView;
  NSInteger i;
}

@property (retain) id<InitializationDelegate> delegate;
@property (retain,nonatomic) PDColoredProgressView *loadingView;
@property NSInteger i;

- (void)startView;
- (void)dismissView;
- (void)checkIfDoneYet;

@end
