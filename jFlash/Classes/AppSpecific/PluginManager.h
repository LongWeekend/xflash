//
//  PluginManager.h
//  jFlash
//
//  Created by Mark Makdad on 6/3/10.
//  Copyright 2010 Long Weekend Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LWEDownloader.h"
#import "FMResultSet.h"
#import "NSDate+LWEUtilities.h"
#import "ASIHTTPRequest.h"

#define LWE_PLUGIN_UPDATE_PERIOD		14
#define LWE_PLUGIN_SERVER_LIST			@"https://d3580k8bnen6up.cloudfront.net/availablePlugins.plist"
#define LWE_AVAILABLE_PLUGIN_PLIST	@"availablePluginForDownload.plist"
#define LWE_DOWNLOADED_PLUGIN_PLIST	@"downloadedPlugin.plist"

extern NSString * const LWEPluginDidInstall;
extern NSString * const LWEPluginKeyKey;
extern NSString * const LWEPluginNameKey;
extern NSString * const LWEPluginVersionKey;
extern NSString * const LWEPluginFilenameKey;
extern NSString * const LWEPluginTargetPathKey;

//! Handles downloaded plugins' installation and versioning
@interface PluginManager : NSObject <LWEDownloaderInstallerDelegate>
{
  NSMutableDictionary *_loadedPlugins;				//! Maintains in memory a list of loaded plugins
  NSDictionary *_downloadedPlugins;						//! Maintains in memory a list of the downloaded plugin in the user device. This is used for loading the plugin back to the program when the program runs. 
	NSDictionary *availableForDownloadPlugins;	//! Maintains in memory a list of availavle for download plugin.
}

+ (NSDictionary*) preinstalledPlugins;
- (BOOL) pluginIsLoaded:(NSString*)name;
- (BOOL) disablePlugin:(NSString*)name;
- (BOOL) loadInstalledPlugins;
- (NSString*) loadPluginFromFile:(NSString*)filename afterDownload:(BOOL)afterDownload;
- (NSArray*) loadedPluginsByKey;
- (NSArray*) loadedPluginsByName;
- (NSArray*) loadedPlugins;
- (NSString*) versionForLoadedPlugin:(NSString*)key;
- (NSArray*) availablePlugins;
- (NSArray*) downloadedPlugins;
- (NSDictionary*) availablePluginsDictionary;
+ (BOOL)isTimeForCheckingUpdate;
- (void)checkNewPluginsNotifyOnNetworkFail:(BOOL)notifyOnNetworkFail;

- (NSArray*) _plugins:(NSDictionary*)_pluginDictionary;
- (void)_setAvailableForDownloadPlugins:(NSDictionary *)dict;
- (void)_removeFromAvailableDownloadForPlugin:(NSString *)pluginKey;
- (NSString *)_checkWhetherAnUpdate:(NSString *)path;
- (void)_registerPlugin:(NSString*)pluginKey withFilename:(NSString*)filename;
- (void)_sendUpdateBadgeNotification:(NSNumber *)badgeNumber;
- (void)_initAvailableForDownloadPluginsList;
- (void)_initDownloadedPluginsList;

// this is generic, should refactor to reusable class
- (NSDictionary*) findDictionaryContainingObject:(NSString*)object forKey:(id)theKey inDictionary:(NSDictionary*)dictionary;

@property (nonatomic, retain) NSDictionary *availableForDownloadPlugins;

@end