//
//  DownloadManager.h
//  jFlash
//
//  Created by Mark Makdad on 12/9/11.
//  Copyright (c) 2011 Long Weekend LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PluginManager.h"
#import "LWEPackageDownloader.h"

@interface DownloadManager : NSObject <LWEPackageDownloaderDelegate>

//! Holds PluginManager instance
@property (retain) PluginManager *pluginMgr;

- (void) startTabAnimation;
- (void) stopTabAnimation;

- (BOOL) pluginIsDownloading;

@property (retain, nonatomic) UIViewController *modalTaskViewController;

@property (retain) NSTimer *tabIconTimer;
@property (retain) NSArray *tabIconImages;
@property NSInteger tabIconIndex;



@end
