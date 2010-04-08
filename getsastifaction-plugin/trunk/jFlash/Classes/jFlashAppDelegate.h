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
@class Tag, Card, CardPeer, User, FMDatabase;

@interface jFlashAppDelegate : NSObject <UIApplicationDelegate, UITabBarControllerDelegate, SplashViewDelegate> {
	UIWindow *window;
	UITabBarController *tabBarController;
}

- (void) switchToStudyView;

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet UITabBarController *tabBarController;
@end