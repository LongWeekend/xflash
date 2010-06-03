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
 * Loads a plugin from a file, returns plugin key name
 */
- (NSString*) loadPluginFromFile:(NSString*)filename
{
  // First, get database instance
  LWEDatabase *db = [LWEDatabase sharedLWEDatabase];
  
  // Make sure we can find the file!
  if (![db databaseFileExists:filename]) return NO;
  
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
        NSDictionary *pluginPair = [NSDictionary dictionaryWithObjectsAndKeys:filename,@"filename",pluginName,@"name",nil];
        [_loadedPlugins setObject:pluginPair forKey:pluginKey];
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


//! Gets array of plugins loaded by key
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


//! Gets array of plugins loaded by name
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


- (void) dealloc
{
  [super dealloc];
  _loadedPlugins = nil;
}

@end
