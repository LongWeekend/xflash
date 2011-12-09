//
//  jFlashAppDelegate.h
//  jFlash
//
//  Created by シャロット ロス on 5/4/09.
//  Copyright LONG WEEKEND INC 2009. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DownloadManager.h"
#import "PluginManager.h"

@interface jFlashAppDelegate : NSObject <UIApplicationDelegate>
{
  NSString *_searchedTerm;
}

void uncaughtExceptionHandler(NSException *exception);

@property BOOL isFinishedLoading;
@property BOOL loadSearchOnBoot;

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet UIImageView *splashView;
@property (nonatomic, retain) IBOutlet UITabBarController *tabBarController;

@property (retain) IBOutlet PluginManager *pluginManager;
@property (retain) IBOutlet DownloadManager *downloadManager;

@end