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
@property (retain) IBOutlet PluginManager *pluginManager;

- (void) startTabAnimation;
- (void) stopTabAnimation;

- (BOOL) pluginIsDownloading;

@property (retain, nonatomic) IBOutlet UIViewController *baseViewController;

//! Todo: make this readonly MMA
@property (retain, nonatomic) UIViewController *modalTaskViewController;

@property (retain) NSTimer *tabIconTimer;
@property (retain) NSArray *tabIconImages;
@property NSInteger tabIconIndex;



@end
