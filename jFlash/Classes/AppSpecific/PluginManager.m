//
//  PluginManager.m
//  jFlash
//
//  Created by Mark Makdad on 6/3/10.
//  Copyright 2010 Long Weekend Inc. All rights reserved.
//

#import "PluginManager.h"

@implementation PluginManager

/**
 * Customized initializer - the available plugin dictionary is defined in this method
 */
- (id) init
{
  if (self = [super init])
  {
    
    // TODO - put real plugin path in
    _loadedPlugins = [[NSMutableDictionary alloc] init];
    _availablePlugins = [[NSDictionary alloc] initWithObjectsAndKeys:
                          // Cards
                          [NSDictionary dictionaryWithObjectsAndKeys:
                           CARD_DB_KEY,@"plugin_key",
                           @"Japanese Flash Cards",@"plugin_name",
                           @"Core cards",@"plugin_details",
                           @"",@"plugin_notes_file",
                           @"http://makbook.local/~phooze/jFlash-CARD-1.1.db.gz",@"target_url",
                           [LWEFile createBundlePathWithFilename:@"jFlash-CARD-1.1.db"],@"target_path",
                           @"jFlash-CARD-1.1.db",@"file_name",
                           nil],CARD_DB_KEY,
                         
                           // FTS
                           [NSDictionary dictionaryWithObjectsAndKeys:
                            FTS_DB_KEY,@"plugin_key",
                            @"Awesomely Fast Search",@"plugin_name",
                            @"full-text-search",@"plugin_notes_file",
                            @"Adds sub-second full dictionary search (13MB)",@"plugin_details",
                            @"https://d3580k8bnen6up.cloudfront.net/jFlash-FTS-1.1.db.gz",@"target_url",
                            [LWEFile createDocumentPathWithFilename:@"jFlash-FTS-1.1.db"],@"target_path",
                            @"jFlash-FTS-1.1.db",@"file_name",
                            nil],FTS_DB_KEY,
                           
                           // Example sentences
                           [NSDictionary dictionaryWithObjectsAndKeys:
                            EXAMPLE_DB_KEY,@"plugin_key",
                            @"50,000+ Example Sentences",@"plugin_name",
                            @"example-sentences",@"plugin_notes_file",
                            @"Adds sentences to practice modes (20MB)",@"plugin_details",
                            @"https://d3580k8bnen6up.cloudfront.net/jFlash-EX-1.1.db.gz",@"target_url",
                            [LWEFile createDocumentPathWithFilename:@"jFlash-EX-1.1.db"],@"target_path",
                            @"jFlash-EX-1.1.db",@"file_name",
                            nil],EXAMPLE_DB_KEY,
                           nil];
  }
  return self;
}


/**
 * Returns a dictionary with KEY => plugin filename of preinstalled plugins
 */
+ (NSDictionary*) preinstalledPlugins;
{
  return [NSDictionary dictionaryWithObjectsAndKeys:JFLASH_CURRENT_CARD_DATABASE,CARD_DB_KEY,nil];
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
  NSMutableDictionary *plugins = [settings objectForKey:APP_PLUGIN];
  NSEnumerator *keyEnumerator = [plugins keyEnumerator];
  NSString *key;
  while (key = [keyEnumerator nextObject])
  {
    NSString* filename = [plugins objectForKey:key];
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
  NSDictionary* dictionaryForFilename = [self findDictionaryContainingObject:filename forKey:@"file_name" inDictionary:_availablePlugins];
  NSString* filePath = [dictionaryForFilename objectForKey:@"target_path"];
  LWE_LOG(@"Loading file: %@ in loadPluginFromFile", filename);
  
  // First, get database instance
  LWEDatabase *db = [LWEDatabase sharedLWEDatabase];
  
  // Make sure we can find the file!
  if (![LWEFile fileExists:filePath]) return NO;
  
  // Test drive the attachment to verify it matches
  if ([db attachDatabase:filePath withName:@"LWEDATABASETMP"])
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
      if ([db attachDatabase:filePath withName:pluginKey])
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
- (BOOL) installPluginWithPath:(NSString *)path
{
  NSString* pluginKey;
  // Downloader gives us absolute paths, but we need to work with relative from this point on
  // so get the filename and go from there
  NSString* filename = [path lastPathComponent];
  if (pluginKey = [self loadPluginFromFile:filename])
  {
    LWE_LOG(@"Registering plugin %@ with filename: %@", pluginKey, filename);
    [self _registerPlugin:pluginKey withFilename:filename];
  }
  else
  {
    return NO;
  }

  // Tell anyone who cares that we've just successfully installed a plugin
  [[NSNotificationCenter defaultCenter] postNotificationName:@"pluginDidInstall" object:self userInfo:[_availablePlugins objectForKey:pluginKey]];
  return YES;
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

/*!
    @method     
    @abstract   Returns the dictionary containing a given object for a given key.
    @discussion naive implementation.  Assumes the dictionary is one deep and the objects are strings
*/
- (NSDictionary*) findDictionaryContainingObject:(NSString*)object forKey:(id)theKey inDictionary:(NSDictionary*)dictionary
{
  for (id key in dictionary) 
  {    
    if([[[dictionary objectForKey:key] objectForKey:theKey] isEqualToString: object])
    {
      return [dictionary objectForKey:key];
    }    
  }
  return nil;
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

#pragma mark -
#pragma mark Privates

/**
 * Register plugin filename with NSUserDefaults
 */
- (void) _registerPlugin:(NSString*)pluginKey withFilename:(NSString*)filename
{
  // Update the settings so we maintain this on startup
  NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
  NSDictionary *pluginSettings = [settings objectForKey:APP_PLUGIN];
  if (pluginSettings)
  {
    // This means we already have a settings database (e.g. not first load)
    LWE_LOG(@"Added %@ key with filename '%@' to NSUserDefaults' plugin key",pluginKey,filename);
    NSMutableDictionary *tmpDict = [NSMutableDictionary dictionaryWithDictionary:pluginSettings];
    [tmpDict setObject:filename forKey:pluginKey];
    [settings setValue:tmpDict forKey:APP_PLUGIN];
  }
  else
  {
    // This should NOT happen
    [NSException raise:@"Plugin register method executed without default settings" format:@"Was passed filename: %@",filename];
  }  
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

@end
