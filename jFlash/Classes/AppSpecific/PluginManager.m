//
//  PluginManager.m
//  jFlash
//
//  Created by Mark Makdad on 6/3/10.
//  Copyright 2010 Long Weekend Inc. All rights reserved.
//

#import "PluginManager.h"

NSString *const FTS_DB_KEY = @"FTS_DB";
NSString *const EXAMPLE_DB_KEY = @"EX_DB";

@implementation PluginManager

//! Customized initializer
- (id) init
{
  if (self = [super init])
  {
    _loadedPlugins = [[NSMutableDictionary alloc] init];
    _availablePlugins = [[NSDictionary alloc] initWithObjectsAndKeys:
                           // FTS
                           [NSDictionary dictionaryWithObjectsAndKeys:
                            @"Awesomely Fast Search",@"plugin_name",
                            @"Adds sub-second full dictionary search (~16MB)",@"plugin_details",
                            @"http://mini.local:8080/hudson/jFlash-CORE-v1.1.db.gz",@"target_url",
                            [LWEFile createDocumentPathWithFilename:@"jFlash-CORE-v1.1.db"],@"target_path",nil],FTS_DB_KEY,
                           
                           // Example sentences
                           [NSDictionary dictionaryWithObjectsAndKeys:
                            @"50,000+ Example Sentences",@"plugin_name",
                            @"Adds sentences to practice modes (~25MB)",@"plugin_details",
                            @"http://mini.local:8080/hudson/jFlash-EX-v1.1.db.gz",@"target_url",
                            [LWEFile createDocumentPathWithFilename:@"jFlash-EX-v1.1.db"],@"target_path",nil],EXAMPLE_DB_KEY,
                           nil];
  }
  return self;
}


/**
 * Tells whether or not a plugin is in the dictionary as loaded
 */
- (BOOL) pluginIsLoaded:(NSString*)name
{
  if ([_loadedPlugins objectForKey:name])
  {
    return YES;
  }
  else
  {
    return NO;
  }
}


/**
 * Takes the plugin out of active use
 */
- (BOOL) disablePlugin:(NSString*)name
{
  // First, make sure the plugin is actually loaded
  if ([_loadedPlugins objectForKey:name])
  {
    LWEDatabase *db = [LWEDatabase sharedLWEDatabase];
    if ([db detachDatabase:name])
    {
      [_loadedPlugins removeObjectForKey:name];
      return YES;
    }
  }
  return NO;
}


/**
 * Load all plugins from settings file
 */
- (BOOL) loadInstalledPlugins
{
  BOOL success = YES;
  // Add each plugin database if it exists
  NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
  NSMutableDictionary *plugins = [settings objectForKey:@"plugins"];
  NSEnumerator *keyEnumerator = [plugins keyEnumerator];
  NSString *key;
  while (key = [keyEnumerator nextObject])
  {
    NSString* filename = [LWEFile createDocumentPathWithFilename:[plugins objectForKey:key]];
    if ([self loadPluginFromFile:filename] == nil)
    {
      LWE_LOG(@"FAILED to load plugin: %@",filename);
      success = NO;
    }
  }
  return success;
}


/**
 * Loads a plugin from a file, returns plugin key name
 */
- (NSString*) loadPluginFromFile:(NSString*)filename
{
  // First, get database instance
  LWEDatabase *db = [LWEDatabase sharedLWEDatabase];
  
  // Make sure we can find the file!
  if (![LWEFile fileExists:filename]) return NO;
  
  // Test drive the attachment to verify it matches
  if ([db attachDatabase:filename withName:@"LWEDATABASETMP"])
  {
    NSString* version = nil;
    NSString* pluginKey = nil;
    NSString* pluginName = nil;
    BOOL foundVersionTable = NO;
    NSString* sql = [[NSString alloc] initWithFormat:@"SELECT version,plugin_key,plugin_name FROM LWEDATABASETMP.version LIMIT 1"];
    FMResultSet *rs = [db.dao executeQuery:sql];
    [sql release];
    while ([rs next])
    {
      foundVersionTable = YES;
      version = [rs stringForColumn:@"version"];
      pluginKey = [rs stringForColumn:@"plugin_key"];
      pluginName = [rs stringForColumn:@"plugin_name"];
    }
    
    // Now detach the database
    [db detachDatabase:@"LWEDATABASETMP"];
    
    if (foundVersionTable)
    {
      LWE_LOG(@"Found version table, plugin file is OK");
      
      // Reattach with proper name and register
      if ([db attachDatabase:filename withName:pluginKey])
      {
        [_loadedPlugins setObject:[_availablePlugins objectForKey:pluginKey] forKey:pluginKey];
        return pluginKey;
      }
      else
      {
        // TODO: Put an event here?
        LWE_LOG(@"Could not re-attach database w/ new name - pluginKey invalid?");
      }
    }
    else
    {
      // TODO: Put an event here?
      LWE_LOG(@"Attached database, but could not find version table data");
    }
  }
  else 
  {
    // TODO: Put an event here?
    LWE_LOG(@"Failed to attach database");
  }
  return nil;
}


/**
 * LWEDownloader delegate method - installs a plugin database
 */
- (BOOL) installPluginWithPath:(NSString *) filename
{
  NSString* pluginKey;
  if (pluginKey = [self loadPluginFromFile:filename])
  {
    // Update the settings so we maintain this on startup
    NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
    NSDictionary *pluginSettings = [settings objectForKey:@"plugins"];
    if (pluginSettings)
    {
      // This means we already have a settings database (e.g. not first load)
      LWE_LOG(@"Added %@ key with filename '%@' to NSUserDefaults' plugin key",pluginKey,[filename lastPathComponent]);
      NSMutableDictionary *tmpDict = [NSMutableDictionary dictionaryWithDictionary:pluginSettings];
      [tmpDict setObject:[filename lastPathComponent] forKey:pluginKey];
      [settings setValue:tmpDict forKey:@"plugins"];
      
      // Tell the root view controller to do some stuff if we are FTS_DB_KEY
      if ([pluginKey isEqualToString:FTS_DB_KEY])
      {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"shouldSwapSearchViewController" object:self];
      }
      
      return YES;
    }
    else
    {
      // This should NOT happen
      [NSException raise:@"Plugin installer method executed without default settings" format:@"Was passed filename: %@",filename];
    }
  }
  return NO;
}


//! Gets array of NSString keys of plugins
- (NSArray*) loadedPluginsByKey;
{
  NSEnumerator *keyEnumerator = [_loadedPlugins keyEnumerator];
  NSString *key;
  NSMutableArray *tmpArray = [[NSMutableArray alloc] init];
  while (key = [keyEnumerator nextObject])
  {
    [tmpArray addObject:key];
  }
  // Make immutable copy
  NSArray *returnArray = [NSArray arrayWithArray:tmpArray];
  [tmpArray release];
  return returnArray;
}


//! Gets array of NSString names of plugins
- (NSArray*) loadedPluginsByName
{
  NSMutableArray *tmpArray = [[NSMutableArray alloc] init];
  NSArray *keys = [self loadedPluginsByKey];
  NSEnumerator *enumerator = [keys objectEnumerator];
  NSDictionary *tmpDict;
  while (tmpDict = [_loadedPlugins objectForKey:[enumerator nextObject]])
  {
    [tmpArray addObject:[tmpDict objectForKey:@"name"]];
  }
  // Make immutable copy
  NSArray *returnArray = [NSArray arrayWithArray:tmpArray];
  [tmpArray release];
  return returnArray;
}


// Internal helper class that does the heavy lifting for loadedPlugins
- (NSArray*) _plugins:(NSDictionary*)_pluginDictionary
{
  NSEnumerator *keyEnumerator = [_pluginDictionary keyEnumerator];
  NSString *key;
  NSMutableArray *tmpArray = [[NSMutableArray alloc] init];
  while (key = [keyEnumerator nextObject])
  {
    [tmpArray addObject:[_pluginDictionary objectForKey:key]];
  }
  // Make immutable copy
  NSArray *returnArray = [NSArray arrayWithArray:tmpArray];
  [tmpArray release];
  return returnArray;
}


//! Gets array of dictionaries with all info about loaded plugins
- (NSArray*) loadedPlugins
{
  return [self _plugins:_loadedPlugins];
}


//! Gets array of dictionaries with all info about available plugins
- (NSArray*) allAvailablePlugins
{
  return [self _plugins:_availablePlugins];
}


//! Gets array of dictionaries with available plugins that are not loaded
- (NSArray*) availablePlugins
{
  NSEnumerator *keyEnumerator = [_availablePlugins keyEnumerator];
  NSString *key;
  NSMutableArray *tmpArray = [[NSMutableArray alloc] init];
  while (key = [keyEnumerator nextObject])
  {
    // If NOT in loaded, then add it
    if (![_loadedPlugins objectForKey:key])
    {
      [tmpArray addObject:[_availablePlugins objectForKey:key]];
    }
  }
  // Make immutable copy
  NSArray *returnArray = [NSArray arrayWithArray:tmpArray];
  [tmpArray release];
  return returnArray;
}


//! Gets all available plugins as a dictionary
- (NSDictionary*) availablePluginsDictionary
{
  return [NSDictionary dictionaryWithDictionary:_availablePlugins];
}


- (void) dealloc
{
  [super dealloc];
  _loadedPlugins = nil;
}

@end
