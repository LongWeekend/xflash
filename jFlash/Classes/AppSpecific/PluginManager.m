//
//  PluginManager.m
//  jFlash
//
//  Created by Mark Makdad on 6/3/10.
//  Copyright 2010 Long Weekend Inc. All rights reserved.
//

#import "PluginManager.h"
#import "RootViewController.h"
#import "Reachability.h"

@implementation PluginManager

@synthesize availableForDownloadPlugins = _availableForDownloadPlugins;

/**
 * Customized initializer - the available plugin dictionary is defined in this method
 *
 * In this intializer, it also loads the availableForDownload plist file (to persist the available plugin to download)
 * and also downloaded plist file (to persist the list of downloaded plugin).
 * If, both of the plist does not exist, we provide one with the bundle of the app. Load from there, and
 * write it to the document immediately. That case only happens in the first time the program runs.
 *
 */
- (id) init
{
  if (self = [super init])
  {
    _loadedPlugins = [[NSMutableDictionary alloc] init];
		[self _initAvailableForDownloadPluginsList];
		[self _initDownloadedPluginsList];
	}
  return self;
}

- (void) _initAvailableForDownloadPluginsList
{
	_availableForDownloadPlugins = nil;
	NSString *path = nil;
	NSDictionary *dict = nil;
	if ([LWEFile fileExists:[LWEFile createDocumentPathWithFilename:LWE_AVAILABLE_PLUGIN_PLIST]])
	{
		LWE_LOG(@"Available plugin plist found in the document path");
		path = [LWEFile createDocumentPathWithFilename:LWE_AVAILABLE_PLUGIN_PLIST];
		
		if (path != nil)
		{
			dict = [[NSDictionary alloc]
							initWithContentsOfFile:path];
			[self _setAvailableForDownloadPlugins:dict];
			[dict release];
		}			
	}
	//TODO: Rendy, please review this again, it works, but is it really necessary? or is there any more ellegant way to do it?
	else if ([LWEFile fileExists:[LWEFile createBundlePathWithFilename:LWE_AVAILABLE_PLUGIN_PLIST]])
	{
		if (![self _checkNetworkToURL:[NSURL URLWithString:LWE_PLUGIN_SERVER_LIST]])
		{
			LWE_LOG(@"Available plugin plist found in the bundle path");
			path = [LWEFile createBundlePathWithFilename:LWE_AVAILABLE_PLUGIN_PLIST];
			NSMutableDictionary *md = [[NSMutableDictionary alloc] init];
			
			NSArray *array = [[NSMutableDictionary dictionaryWithContentsOfFile:path] objectForKey:@"Plugins"];
			
			for (NSDictionary *dct in array)
			{
				[dct setValue:[LWEFile createDocumentPathWithFilename:[dct objectForKey:@"plugin_target_path"]] forKey:@"plugin_target_path"];
				[md setValue:dct forKey:[dct objectForKey:@"plugin_key"]];
			}
			
			dict = [[NSDictionary alloc] 
							initWithDictionary:md];
			[self performSelector:@selector(_setAvailableForDownloadPlugins:) withObject:dict afterDelay:2];
			[dict release];
			[md release];
		}
	}
	else 
	{
		LWE_LOG(@"Debug : File for saving the available for download plugin %@ does not exist", LWE_AVAILABLE_PLUGIN_PLIST);
	}
}

- (void) _initDownloadedPluginsList
{
	NSString *pathForDownloadedPlugin = nil;
	if ([LWEFile fileExists:[LWEFile createDocumentPathWithFilename:LWE_DOWNLOADED_PLUGIN_PLIST]])
	{
		pathForDownloadedPlugin = [LWEFile createDocumentPathWithFilename:LWE_DOWNLOADED_PLUGIN_PLIST];
		_downloadedPlugins = [[NSDictionary alloc] 
													initWithContentsOfFile:pathForDownloadedPlugin];
		LWE_LOG(@"Downloaded plugin plist content found in the document path : %@", _downloadedPlugins);
	}
	else if ([LWEFile fileExists:[LWEFile createBundlePathWithFilename:LWE_DOWNLOADED_PLUGIN_PLIST]])
	{
		LWE_LOG(@"Downloaded plugin plist found in the bundle path");
		pathForDownloadedPlugin = [LWEFile createBundlePathWithFilename:LWE_DOWNLOADED_PLUGIN_PLIST];
		NSDictionary *_plugin = [[NSDictionary alloc] initWithContentsOfFile:pathForDownloadedPlugin];
		NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];
		NSArray *values = [_plugin allValues];
		NSDictionary *userSettingPlugin = [[NSUserDefaults standardUserDefaults] objectForKey:APP_PLUGIN];
		for (NSDictionary *dict in values)
		{
			NSString *key = [dict objectForKey:@"plugin_key"];
			if (([key isEqualToString:@"CARD_DB"]) || ([userSettingPlugin objectForKey:key]))
			{
				LWE_LOG(@"Added to the list of the downloaded list for key : %@", key);
				NSMutableDictionary *md = [NSMutableDictionary dictionaryWithDictionary:dict];
				NSString *path;
				
				//This is because the card db file will always be in the bundle file, while the other plugin
				//will be in the document path. This is important so that when the PluginManager
				//tries to load the plugin, it points to the right location.
				if ([key isEqualToString:@"CARD_DB"])
					path = [LWEFile createBundlePathWithFilename:[dict objectForKey:@"plugin_target_path"]];
				else 
					path = [LWEFile createDocumentPathWithFilename:[dict objectForKey:@"plugin_target_path"]];
				
				[md setValue:path forKey:@"plugin_target_path"];
				[dictionary setValue:md forKey:key];
			}
		}
		
		_downloadedPlugins = [dictionary retain];
		[_downloadedPlugins writeToFile:[LWEFile createDocumentPathWithFilename:LWE_DOWNLOADED_PLUGIN_PLIST] atomically:YES];
		LWE_LOG(@"This is the list of what the user has downloaded in the previous version, and now its going to persist it in the flat file : %@", _downloadedPlugins);
		[dictionary release];
		[_plugin release];
	}
	
}


/**
 * Returns a dictionary with KEY => plugin filename of preinstalled plugins
 */
+ (NSDictionary*) preinstalledPlugins;
{
  return [NSDictionary dictionaryWithObjectsAndKeys:JFLASH_CURRENT_CARD_DATABASE, CARD_DB_KEY,nil];
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

# pragma mark -
# pragma mark Should be subclassed later

/** 
 * Convenience method to allow custom logic for versions
 * TODO subclass
 */
- (BOOL) searchPluginIsLoaded
{
  NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
  BOOL plugin = [self pluginIsLoaded:FTS_DB_KEY];
  return (plugin || [[settings objectForKey:APP_DATA_VERSION] isEqualToString:JFLASH_VERSION_1_0]);
}


/** 
 * Convenience method to allow custom logic for versions
 * TODO subclass
 */
- (BOOL) examplesPluginIsLoaded
{
  BOOL plugin = [self pluginIsLoaded:EXAMPLE_DB_KEY];  
  return plugin;
}

#pragma mark -
#pragma mark Plugin mechanism, disable, loadPlugin, etc. 

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
 * Load all plugins from settings file, after loading all of the downloaded plugin.
 * It also checks whether this is the right time for checking the new update. 
 */
- (BOOL) loadInstalledPlugins
{
  BOOL success = YES;
  // Add each plugin database if it exists
  NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
  NSMutableDictionary *plugins = [settings objectForKey:APP_PLUGIN];
	LWE_LOG(@"This is the APP_PLUGIN in the NSUserDefaults : %@", plugins);
  NSEnumerator *keyEnumerator = [plugins keyEnumerator];
  NSString *key;
  while (key = [keyEnumerator nextObject])
  {
    NSString* filename = [plugins objectForKey:key];
		LWE_LOG(@"LOG : Trying to load the installed plugins = %@, with filename = %@", key, filename);
    if ([self loadPluginFromFile:filename afterDownload:NO] == nil)
    {
      LWE_LOG(@"FAILED to load plugin: %@", filename);
      success = NO;
    }
  }
	
	double start = [[NSDate date] timeIntervalSince1970];
	LWE_LOG(@"LOG: Start Checking Update");
	//Checks whether this is the time for update
	if ([self isTimeForCheckingUpdate])
	{
		LWE_LOG(@"LOG : Today is the time for checking update");
		[self checkNewPluginwithNotificationForFailNetwork:NO];
	}
	double end = [[NSDate date] timeIntervalSince1970];
	LWE_LOG(@"LOG: Check new plugin is finished, it took %f time for downloading and checking", (end-start));
	
  return success;
}


/**
 * Loads a plugin from a file, returns plugin key name
 */
- (NSString*) loadPluginFromFile:(NSString*)filename afterDownload:(BOOL)afterDownload
{
	NSDictionary* pluginForFilename = nil;
	if (!afterDownload)
		pluginForFilename = [self findDictionaryContainingObject:filename forKey:@"plugin_file_name" inDictionary:_downloadedPlugins];
  else 
		pluginForFilename = [self findDictionaryContainingObject:filename forKey:@"plugin_file_name" inDictionary:self.availableForDownloadPlugins];
	
	
	NSString* filePath = [pluginForFilename objectForKey:@"plugin_target_path"];
  LWE_LOG(@"Loading file: %@ in loadPluginFromFile", filename);
	// First, get database instance
  LWEDatabase *db = [LWEDatabase sharedLWEDatabase];
  
  // Make sure we can find the file!
  if (![LWEFile fileExists:filePath]) 
	{
		return NO;
		NSString *str = [NSString stringWithFormat:@"%@ couldnt be found when the file is trying to be loaded", filePath];
		LWE_LOG(@"%@", str);
		//TODO: Remove upon production
		UIAlertView *alert = [[UIAlertView alloc]
													initWithTitle:@"Error" 
													message:str 
													delegate:nil 
													cancelButtonTitle:@"OK" 
													otherButtonTitles:nil];
		[alert show];
		[alert release];
	}
  
  // Test drive the attachment to verify it matches
  if ([db attachDatabase:filePath withName:@"LWEDATABASETMP"])
  {
		LWE_LOG(@"DEBUG : file %@ is now attached as LWEDATABASETMP to be checked out", filePath);
    NSString* pluginKey = nil;
		double version = [self _versionInMainDb:[db dao] forDbName:@"LWEDATABASETMP"];
		BOOL foundVersionTable = NO;
		if (version != 0.0f)
		{
			//version table exists, and now extract the plugin key
			pluginKey = [pluginForFilename objectForKey:@"plugin_key"];
			foundVersionTable = YES;
		}
    // Now detach the database
    [db detachDatabase:@"LWEDATABASETMP"];
    
    if (foundVersionTable)
    {
      LWE_LOG(@"Found version table, plugin file is OK");
			// Reattach with proper name and register
      if ([db attachDatabase:filePath withName:pluginKey])
      {		  
				[_loadedPlugins setObject:pluginForFilename forKey:pluginKey];
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

#pragma mark -
#pragma mark LWEDownloader delegate method

/**
 * LWEDownloader delegate method - installs a plugin database
 */
- (BOOL) installPluginWithPath:(NSString *)path
{
  NSString* pluginKey;
  // Downloader gives us absolute paths, but we need to work with relative from this point on
  // so get the filename and go from there
  NSString* filename = [path lastPathComponent];
	
	LWE_LOG(@"LOG : The download has just finished, now checking whther the download is an updated version, or a refresh plugin download");
	NSString *updatedKey = [self _checkWhetherAnUpdate:path];
	NSString *oldPluginPathFileName = nil;
	if (updatedKey)
	{
		oldPluginPathFileName = [[_downloadedPlugins objectForKey:updatedKey] objectForKey:@"plugin_target_path"];
		LWE_LOG(@"This is an update plugin, path of the old plugin file : %@", oldPluginPathFileName);
		//Detach the old database
		[[LWEDatabase sharedLWEDatabase] detachDatabase:updatedKey];
	}
	
  if (pluginKey = [self loadPluginFromFile:filename afterDownload:YES])
  {
		//If plugin key does exists, means it sucess load the new plugin (no matter its a fresh installed plugin, or the
		//update plugin
    LWE_LOG(@"Registering plugin %@ with filename: %@", pluginKey, filename);
		[self _registerPlugin:pluginKey withFilename:filename];
		
		//After it registered, make sure it deletes the data from the available for download plugin, and 
		//do some cleaning.
		//If it is an update, delete the old one after a successful update
		if (updatedKey)
		{
			LWE_LOG(@"After a successful installation of the update, delete the old file of the plugin : %@", oldPluginPathFileName);
			[LWEFile deleteFile:oldPluginPathFileName];
		}
		
		//Now update the downloaded plugin file and variable, so that the next time the program runs, 
		//it shows the downloaded plugin as "has been downloaded"
		LWE_LOG(@"Write the just downloaded plugin : %@ to the file. This is the detail : %@", pluginKey, [self.availableForDownloadPlugins objectForKey:pluginKey]);
		[_downloadedPlugins setValue:[self.availableForDownloadPlugins objectForKey:pluginKey] forKey:pluginKey];
		[_downloadedPlugins writeToFile:[LWEFile createDocumentPathWithFilename:LWE_DOWNLOADED_PLUGIN_PLIST] atomically:YES];
		LWE_LOG(@"This is the result of the _downloadedPlugins content after being modified, and overwrite : %@", _downloadedPlugins);
		
		[self _removeFromAvailableDownloadForPlugin:pluginKey];
  }
  else
  {
		//Means install failed?
		//Then how if its an update plugin, not a fresh installed plugin? NOOO....
		//Return back the old detached database
		if (updatedKey)
		{
			[[LWEDatabase sharedLWEDatabase] attachDatabase:oldPluginPathFileName withName:updatedKey];
			LWE_LOG(@"Installed update has just failed. Attach the old database, with the old database path.(Backup plan)");
		}

    return NO;
  }

  // Tell anyone who cares that we've just successfully installed a plugin
  [[NSNotificationCenter defaultCenter] postNotificationName:@"pluginDidInstall" object:self userInfo:[_downloadedPlugins objectForKey:pluginKey]];
  return YES;
}

#pragma mark -

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
/*- (NSArray*) allAvailablePlugins
{
  return [self _plugins:_availablePlugins];
}
*/

//! Gets array of dictionaries with available plugins that are not loaded
- (NSArray*) availablePlugins
{
	return [self.availableForDownloadPlugins allValues];
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
  return [NSDictionary dictionaryWithDictionary:self.availableForDownloadPlugins];
}

- (BOOL)isTimeForCheckingUpdate
{
	//Debug purposes, to bypass and try to update everyday. 
	//return YES;
	NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
	NSDate *date = [settings objectForKey:PLUGIN_LAST_UPDATE];
	date = [date addDays:LWE_PLUGIN_UPDATE_PERIOD];
	NSDate *now = [NSDate date];
	
	//date is earlier than now, means it is for update
	if ([date compare:now] == NSOrderedAscending)
		return YES;
	else 
		return NO;
}

//!Check the new plugin over the website, and looks whether it has a new stuff
- (void)checkNewPluginwithNotificationForFailNetwork:(BOOL)doesNeedNotify
{	
	if ([self _checkNetworkToURL:[NSURL URLWithString:LWE_PLUGIN_SERVER_LIST]])
	{
		//Set up the variable to be the 
		NSMutableDictionary *awaitsUpdatePlugins = nil;
		if (_availableForDownloadPlugins != nil)
			awaitsUpdatePlugins = [[NSMutableDictionary alloc] initWithDictionary:_availableForDownloadPlugins];
		else
			awaitsUpdatePlugins = [[NSMutableDictionary alloc] init];
		
		//Download the list of new plugin from the internet 
		NSDictionary *dictionary = [[NSDictionary alloc]
																initWithContentsOfURL:[NSURL URLWithString:LWE_PLUGIN_SERVER_LIST]];
		NSArray *plugins = [dictionary objectForKey:@"Plugins"];
		
		//This is how we get the information about the installed plugin on the device
		//This gets the information from the user default, app plugin key.
		NSDictionary *pluginSettings = [[NSUserDefaults standardUserDefaults] objectForKey:APP_PLUGIN];
		FMDatabase *db = [[LWEDatabase sharedLWEDatabase] dao];
		
		//wraps the checking version in the database with the transaction. 
		[db beginDeferredTransaction];
		for (NSDictionary *plugin in plugins)
		{
			NSString *pluginKey = [plugin objectForKey:@"plugin_key"];
			NSString *installedPlugin = [pluginSettings objectForKey:pluginKey];
			NSString *awaitsUpdate = [awaitsUpdatePlugins objectForKey:pluginKey];
			BOOL needUpdate = NO;
			
			//The user already had the plugin on the user setting, and checks whether thats outdated
			if ((installedPlugin) && (!awaitsUpdate))
			{
				double pluginVersion = [[plugin objectForKey:@"plugin_version"] doubleValue];
				double installedVersion = [self _versionInMainDb:db forDbName:pluginKey];
				
				LWE_LOG(@"Debug : Installed version %f, plugin version %f, need upgrade? %@", installedVersion, pluginVersion, (pluginVersion > installedVersion) ? @"YES" : @"NO");
				//Yap, its updated, need a new update
				if (pluginVersion > installedVersion)
				{
					needUpdate = YES;
				}
			}
			//The user has not had the update, BUT it might already been in the list of update pluggin awaits the user to update. 
			//in that case, I chose to rewrite the list with the new one anyway. There are only 2 possibilities, it either the new one
			//from the web is the newer version, or the same. It does not matter, we still want it to be on the user awaits update plugin
			//list anyway. 
			else
			{
				needUpdate = YES;
			}
			
			//Needss update means it will add the plugin dictionary to the mutable dictionary initialized
			//in the beginning of this method.
			//Before doing that, it also tried to fix the plugin_target_path to be the document path of the device.
			if (needUpdate)
			{
				NSString *plugin_path = [plugin objectForKey:@"plugin_target_path"];
				[plugin setValue:[LWEFile createDocumentPathWithFilename:plugin_path] forKey:@"plugin_target_path"];
				[awaitsUpdatePlugins setValue:plugin forKey:pluginKey];
			}
		}
		[db commit];
		[dictionary release];
		
		//Set the available for download plugin dictionary, to be persisted in the flat file, and set the badge.
		LWE_LOG(@"Call _setAvailableForDownloadPlugins from _checkNewPluginWithNotificationForFailNetwork");
		[self _setAvailableForDownloadPlugins:awaitsUpdatePlugins];
		[awaitsUpdatePlugins release];
	}
	else if (doesNeedNotify)
	{
		UIAlertView *alert = [[UIAlertView alloc]
													initWithTitle:@"Network unavailable" 
													message:@"Please check for your network" 
													delegate:nil 
													cancelButtonTitle:@"OK" 
													otherButtonTitles:nil];
		[alert show];
		[alert release];
	}
}

#pragma mark -
#pragma mark Privates

/**
 * Convinient method to check whether the new update is the updated version. 
 * Its going to return the key of the updated plugin, if the plugin downloaded is an update, not just a fresh install.
 *
 */
- (NSString *)_checkWhetherAnUpdate:(NSString *)path
{
  NSString *result = nil;
	NSDictionary *dict = [self findDictionaryContainingObject:path forKey:@"plugin_target_path" inDictionary:self.availableForDownloadPlugins];
	NSString *keyString = [dict objectForKey:@"plugin_key"];
	//check whether they the user already had it in the user settings.
	NSDictionary *installedPlugin = [[NSUserDefaults standardUserDefaults] objectForKey:APP_PLUGIN];
	NSDictionary *pluginBeingInstalled = [installedPlugin objectForKey:keyString];
	//Means there are stuffs in the user default.
	//Next thing is to check whether the plugin installed in the user device has the
	//updated version, or the downloaded is the updated one. 
	if (pluginBeingInstalled)
	{
		//Check the version on the installed version.
		/*double versionInTheUserDevice = [self _versionInMainDb:[[LWEDatabase sharedLWEDatabase]dao] forDbName:keyString];
		double downloadedVersion;
		if (versionInTheUserDevice < downloadedVersion)
			isUpdate = YES;*/
		
		//I dont think we need to check the version again, since If its already in the user settings.
		//It should be an update. Nothing else
		result = keyString;
	}
	return result;
}

/**
 * This method is a wrapper method to check the reachability, whether the phone now is connnected to internet, before performing any internet request. 
 */
- (BOOL)_checkNetworkToURL:(NSURL *)url
{
	Reachability *reachability = [Reachability reachabilityWithHostName:[url host]];
	NetworkStatus status = [reachability currentReachabilityStatus];
	if (status == NotReachable)
	{
		return NO;
	}
	return YES;
}

/**
 * This is the handy function to return the version of specific key of the attached database in the main
 * database. It assumed that the database is already attached, and there is a version table. 
 */
- (double)_versionInMainDb:(FMDatabase *)db forDbName:(NSString *)dbName
{
	NSString *query = [[NSString alloc] initWithFormat:@"SELECT v.version FROM \"%@\".\"version\" v LIMIT 1", dbName];
	FMResultSet *rs = [db executeQuery:query];
	[query release];

	double version = 0.0f;
	while ([rs next])
	{
		version = [[rs stringForColumn:@"version"] doubleValue];
	}
	[rs close];
	
	return version;
}

/**
 * This is the setter for available for download plugin. 
 * However, unlike the usual setter, it also sets the badge number via notification to the RootViewController
 * and it also persist that in the file. 
 */
- (void)_setAvailableForDownloadPlugins:(NSDictionary *)dict
{
	//Release the previous available for download dictionary, if it happens to have memory allocated.
	if (_availableForDownloadPlugins != nil)
	{
		[_availableForDownloadPlugins release];
	}
	
	//persist the update to a file
	_availableForDownloadPlugins = [dict retain];
	[dict writeToFile:[LWEFile createDocumentPathWithFilename:LWE_AVAILABLE_PLUGIN_PLIST] atomically:YES];
	
	//Try to update the last update in the user setting
	NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
	[settings setObject:[NSDate date] forKey:PLUGIN_LAST_UPDATE];
	
	//Update the badge in the settings. 
	LWE_LOG(@"Debug : New %d update(s)",[dict count]);
	NSNumber *newUpdate = [NSNumber numberWithInt:[dict count]];
	[self performSelector:@selector(_sendUpdateBadgeNotification:) withObject:newUpdate afterDelay:0.3f];
}

/**
 * This method is going to be called to perform a badge number update, and send the notification to whoever cares about badge number update.
 */
- (void)_sendUpdateBadgeNotification:(NSNumber *)badgeNumber
{
	NSDictionary *userDict = [NSDictionary dictionaryWithObject:badgeNumber
																											 forKey:@"badge_number"];
	[[NSNotificationCenter defaultCenter] postNotificationName:LWEShouldUpdateSettingsBadge object:self userInfo:userDict];
}

/**
 * This is the handy method to delete the key from the available download for plugin dictionary
 * enable the use to see the updated plugin, and the new number badge of the available download for plugin. 
 */
- (void)_removeFromAvailableDownloadForPlugin:(NSString *)pluginKey
{
	NSMutableDictionary *dict = [[NSMutableDictionary alloc] 
															 initWithDictionary:self.availableForDownloadPlugins];
	[dict removeObjectForKey:pluginKey];
	LWE_LOG(@"Called _setAvailableForDownloadPlugins from _removeFromAvailableDownloadForPlugin");
	[self _setAvailableForDownloadPlugins:dict];
}


/**
 * Register plugin filename with NSUserDefaults
 *
 * Returns NO means that the system user setting has already had the key, so this is a plugin update
 * YES means this is a refresh plugin install.
 *
 */
- (void)_registerPlugin:(NSString*)pluginKey withFilename:(NSString*)filename
{
  // Update the settings so we maintain this on startup
  NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
  NSDictionary *pluginSettings = [settings objectForKey:APP_PLUGIN];
  if (pluginSettings)
  {
		LWE_LOG(@"Added %@ key with filename '%@' to NSUserDefaults plugin key", pluginKey, filename);
		NSMutableDictionary *tmpDict = [NSMutableDictionary dictionaryWithDictionary:pluginSettings];
		[tmpDict setObject:filename forKey:pluginKey];
		[settings setValue:tmpDict forKey:APP_PLUGIN];
		[settings synchronize];
		
		LWE_LOG(@"After updated the APP_PLUGIN key in the NSUserDefaults : %@", [settings objectForKey:APP_PLUGIN]);
  }
  else
  {
    // This should NOT happen
    [NSException raise:@"Plugin register method executed without default settings" format:@"Was passed filename: %@",filename];
  }  
}


// Internal helper class that does the heavy lifting for loadedPlugins
- (NSArray*)_plugins:(NSDictionary*)_pluginDictionary
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

#pragma mark -
#pragma mark Memory Management

- (void)dealloc
{
  [super dealloc];
	if (_availableForDownloadPlugins)
		[_availableForDownloadPlugins release];
  _loadedPlugins = nil;
}

#pragma mark -

@end
