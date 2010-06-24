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

//! Handles downloaded plugins' installation and versioning
@interface PluginManager : NSObject <LWEDownloaderInstallerDelegate>
{
  NSMutableDictionary *_loadedPlugins;    //! Maintains in memory a list of loaded plugins
  NSDictionary *_availablePlugins;        //! Maintains in memory a list of available plugins to this software version
}

+ (NSDictionary*) preinstalledPlugins;
- (BOOL) pluginIsLoaded:(NSString*)name;
- (BOOL) disablePlugin:(NSString*)name;
- (BOOL) loadInstalledPlugins;
- (NSString*) loadPluginFromFile:(NSString*)filename;
- (NSArray*) loadedPluginsByKey;
- (NSArray*) loadedPluginsByName;
- (NSArray*) _plugins:(NSDictionary*)_pluginDictionary;
- (NSArray*) loadedPlugins;
- (NSArray*) availablePlugins;
- (NSArray*) allAvailablePlugins;
- (NSDictionary*) availablePluginsDictionary;
- (void) _registerPlugin:(NSString*)pluginKey withFilename:(NSString*)filename;

// Should be subclassed - TODO
- (BOOL) examplesPluginIsLoaded;
- (BOOL) searchPluginIsLoaded;


// this is generic, should refactor to reusable class
- (NSDictionary*) findDictionaryContainingObject:(NSString*)object forKey:(id)theKey inDictionary:(NSDictionary*)dictionary;

@end