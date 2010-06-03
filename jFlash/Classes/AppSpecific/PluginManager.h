//
//  PluginManager.h
//  jFlash
//
//  Created by Mark Makdad on 6/3/10.
//  Copyright 2010 Long Weekend Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LWEDownloader.h"

extern NSString *const FTS_DB_KEY;        //! Dictionary key to refer to FTS database filename
extern NSString *const EXAMPLE_DB_KEY;    //! Dictionary key to refer to example database filename

//! Handles downloaded plugins' installation and versioning
@interface PluginManager : NSObject <LWEDownloaderInstallerDelegate>
{
  NSMutableDictionary *_loadedPlugins;    //! Maintains in memory a list of loaded plugins
}

- (BOOL) pluginIsLoaded:(NSString*)name;
- (BOOL) disablePlugin:(NSString*)name;
- (NSString*) loadPluginFromFile:(NSString*)pathname;
- (NSArray*) loadedPluginsByKey;
- (NSArray*) loadedPluginsByName;

@end