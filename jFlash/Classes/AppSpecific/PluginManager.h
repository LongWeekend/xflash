//
//  PluginManager.h
//  jFlash
//
//  Created by Mark Makdad on 6/3/10.
//  Copyright 2010 Long Weekend Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FMResultSet.h"
#import "Plugin.h"
#import "NSDate+LWEUtilities.h"
#import "ASIHTTPRequest.h"
#import "LWEPackageDownloader.h"

extern NSString * const LWEShouldUpdateSettingsBadge;
extern NSString * const LWEPluginDidInstall;
extern NSString * const LWEPluginKeyKey;
extern NSString * const LWEPluginNameKey;
extern NSString * const LWEPluginVersionKey;
extern NSString * const LWEPluginFilenameKey;
extern NSString * const LWEPluginTargetPathKey;

//! Handles downloaded plugins' installation and versioning
@interface PluginManager : NSObject
{
  NSMutableDictionary *_loadedPlugins;
  NSMutableArray *_downloadedPlugins;
}

- (void)_initAvailableForDownloadPluginsList;
- (void)_initDownloadedPluginsList;


// ======= THESE DO SOMETHING =========

//! Returns YES if the plugin was able to be disabled.  Directory plugins always return YES.
- (BOOL) disablePlugin:(Plugin*)plugin;

//! Returns YES after successfully loading (enabling) all installed plugins.
- (BOOL) loadInstalledPlugins;

/**
 * Pass the full pathname to a plugin, as well as the type.
 * Potential types are "database" and "directory".  In the case of "directory", pass
 * the path as a path with trailing slash.
 *
 * In the case of a database, point directly at the database file.
 */
- (BOOL) installPlugin:(Plugin *)plugin error:(NSError **)error;


//========= THESE GIVE STATE ========
/**
 * Returns a dictionary of plugins that should be in the bundle as pre-installed
 */
+ (NSDictionary*) preinstalledPlugins;

//! Returns YES if the plugin is loaded.  Directory plugins always return YES.
- (BOOL) pluginKeyIsLoaded:(NSString *)pluginKey;

- (Plugin *)pluginForKey:(NSString *)pluginKey;

- (NSString*) versionForLoadedPlugin:(NSString*)key;

- (BOOL) loadPlugin:(Plugin *)plugin error:(NSError **)error;

- (void) processPlistHash:(NSDictionary*)plistHash;

// Used to fix the plugin paths after a restore/transfer to a different device
//- (void) _updatePluginPaths:(BOOL) debug pluginList:(NSString*)plistFileName;

- (NSDictionary *) downloadedPlugins;

//! Maintains in memory a list of availavle for download plugin.
@property (nonatomic, retain) NSMutableDictionary *availableForDownloadPlugins;

@end