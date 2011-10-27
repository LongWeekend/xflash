//
//  jFlashAppDelegate.h
//  jFlash
//
//  Created by シャロット ロス on 5/4/09.
//  Copyright LONG WEEKEND INC 2009. All rights reserved.
//

#import <UIKit/UIKit.h>

// Tell the compiler about user-defined classes
@class RootViewController;

@interface jFlashAppDelegate : NSObject <UIApplicationDelegate>
{
  NSString *_searchedTerm;
}

void uncaughtExceptionHandler(NSException *exception);

- (void) _prepareUserDatabase;
- (void) _openUserDatabaseWithPlugins;

@property (nonatomic, retain) UIWindow *window;
@property (nonatomic, retain) RootViewController *rootViewController;

@end