//
//  SettingsViewController.h
//  jFlash
//
//  Created by シャロット ロス on 5/17/09.
//  Copyright 2009 Long Weekend LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DownloadManager.h"
#import "PluginManager.h"

extern NSString * const APP_ABOUT;
extern NSString * const APP_TWITTER;
extern NSString * const APP_FACEBOOK;
extern NSString * const APP_NEW_UPDATE;

@protocol LWESettingsDataSource <NSObject>
@required
- (NSArray*) settingsArrayWithPluginManager:(PluginManager *)pluginManager;
- (NSDictionary*) settingsHash;
- (CGFloat) sizeForAcknowledgementsRow;
@end

@class SettingsViewController;

@interface SettingsViewController : UITableViewController <UIWebViewDelegate>
- (void) updateBadgeValue;
- (void) iterateSetting: (NSString*) setting;

//! This data source is not quite a model in the traditional sense; it is retained - 100% used by this VC
@property (retain) id<LWESettingsDataSource> dataSource;
@property (retain, nonatomic) NSArray *sectionArray;

@property (retain) IBOutlet DownloadManager *downloadManager;
@property (retain) IBOutlet PluginManager *pluginManager;
@end