//
//  RootViewController.h
//  jFlash
//
//  Created by Mark Makdad on 2/20/10.
//  Copyright 2010 LONG WEEKEND INC.. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "LoadingView.h"

@protocol InitializationDelegate <NSObject>
@optional
- (void)appInitDidComplete;
@end

@class PDColoredProgressView;

@interface RootViewController : UIViewController
{
	id<InitializationDelegate> delegate;
//	PDColoredProgressView *loadingView;
  LoadingView *loadingView;
  NSInteger i;
  UITabBarController *tabBarController;
}

@property (retain,nonatomic) UITabBarController *tabBarController;
@property (retain) id<InitializationDelegate> delegate;
@property (retain,nonatomic) LoadingView *loadingView;
@property NSInteger i;

- (void) switchToStudyView;
- (void) applicationWillTerminate;
- (void) showFirstLoadProgressView;
- (void) continueDatabaseCopy;
- (void) finishDatabaseCopy;
- (void) loadTabBar;

@end
