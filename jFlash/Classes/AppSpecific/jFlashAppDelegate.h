//
//  jFlashAppDelegate.h
//  jFlash
//
//  Created by シャロット ロス on 5/4/09.
//  Copyright LONG WEEKEND INC 2009. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface jFlashAppDelegate : NSObject <UIApplicationDelegate>
{
  NSString *_searchedTerm;
}

void uncaughtExceptionHandler(NSException *exception);

- (void) _prepareUserDatabase;
- (void) _openUserDatabaseWithPlugins;

@property BOOL isFinishedLoading;
- (void) switchToSearchWithTerm:(NSString*)term;

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet UIImageView *splashView;
@property (nonatomic, retain) IBOutlet UITabBarController *tabBarController;

//@property (nonatomic, retain) RootViewController *rootViewController;

@end