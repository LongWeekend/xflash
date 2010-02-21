//
//  jFlashAppDelegate.h
//  jFlash
//
//  Created by シャロット ロス on 5/4/09.
//  Copyright LONG WEEKEND INC 2009. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SplashView.h"
#import "Appirater.h"

// Tell the compiler about user-defined classes
@class Tag, Card, CardPeer, User, FMDatabase, RootViewController;

@interface jFlashAppDelegate : NSObject <UIApplicationDelegate, SplashViewDelegate>
{
	UIWindow *window;
	RootViewController *rootViewController;
}

- (void) switchToStudyView;

@property (nonatomic, retain) UIWindow *window;
@end