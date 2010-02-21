//
//  RootViewController.h
//  jFlash
//
//  Created by Mark Makdad on 2/20/10.
//  Copyright 2010 LONG WEEKEND INC.. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

@protocol InitializationDelegate <NSObject>
@optional
- (void)appInitDidComplete;
@end

@class PDColoredProgressView;

@interface RootViewController : UIViewController
{
	id<InitializationDelegate> delegate;
	PDColoredProgressView *loadingView;
  NSInteger i;
  UITabBarController *tabBarController;
}

@property (retain,nonatomic) UITabBarController *tabBarController;
@property (retain) id<InitializationDelegate> delegate;
@property (retain,nonatomic) PDColoredProgressView *loadingView;
@property NSInteger i;

- (void) switchToStudyView;
- (void) applicationWillTerminate;
- (void) continueDatabaseCopy;
- (void) startDatabaseCopy;
- (void) finishDatabaseCopy;
- (void) showProgressView;
- (void) loadTabBar;

@end
