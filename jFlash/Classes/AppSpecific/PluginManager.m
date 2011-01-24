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

@synthesize availableForDownloadPlugins;

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
  if ((self = [super init]))
  {
    // Initialize instance variables
    _loadedPlugins = [[NSMutableDictionary alloc] init];
		_downloadedPlugins = nil;
    self.availableForDownloadPlugins = nil;
    
    // MAKE THIS INSTALL BUGGY (YES as a parameter makes it buggy)
//    [self _updatePluginPaths:YES];

		[self _initAvailableForDownloadPluginsList];
		[self _initDownloadedPluginsList];
	}
  return self;
}

/** 
 * This is new in 1.2, because prior to this, the list dictionary of dictionary for plugin is hardcoded in the code, and now it is moved to the flat file.
 * This method will try to load the available for download plugin list from the user document folder, if it is not there it means the program first launched (after upgrade, or after install).
 * It has default bundle plist file which contains all of the "should be available for download" plugin list file, read from that, and check with the user settings, 
 * if the user has not downloaded the plugin, it means that it should copy the one from the bundle, and populate the path to the plugin, and last step would be write the file back to the DOCUMENT folder.
 * However, if its not the first run, the user should already has the file in the DOCUMENT folder, and just load it from there directly.
 *
 * UPDATE: After given some thought, it would be best to read from file only if the device not connected to the internet, if the device is connected, it should check for update
 * right away.
 */
- (void) _initAvailableForDownloadPluginsList
{
	NSString *docPath = [LWEFile createDocumentPathWithFilename:LWE_AVAILABLE_PLUGIN_PLIST];
  NSString *bundlePath = [LWEFile createBundlePathWithFilename:LWE_AVAILABLE_PLUGIN_PLIST];
	NSDictionary *dict = nil;
	if ([LWEFile fileExists:docPath])
	{
    [self _updatePluginPaths:NO pluginList:LWE_AVAILABLE_PLUGIN_PLIST];
		LWE_LOG(@"Available plugin plist found in the document path");
    dict = [[NSDictionary alloc] initWithContentsOfFile:docPath];
    [self _setAvailableForDownloadPlugins:dict];
    [dict release];
	}
	else if ([LWEFile fileExists:bundlePath])
	{
		if (![LWENetworkUtils networkAvailableFor:LWE_PLUGIN_SERVER_LIST])
		{
			LWE_LOG(@"Available plugin plist found in the bundle path. Because, by the time of checking, the device is not connected to the internet.");
			NSDictionary *userSettingPlugin = [[NSUserDefaults standardUserDefaults] objectForKey:APP_PLUGIN];
			NSMutableDictionary *md = [[NSMutableDictionary alloc] init];
			NSArray *array = [[NSMutableDictionary dictionaryWithContentsOfFile:bundlePath] objectForKey:@"Plugins"];
			
			for (NSDictionary *dct in array)
			{
				//This is assumed that by the time this binary is released, if the user has a plugin, the plugin version is the same as 
				//the version stated in the available for download plugin plist included in the bundle. 
				//This case only happen in the ipod touch device, or devices that does not have internet connection by the time this version (1.2) launched at the very first time. 
				//TODO: Do a version checking to remove the assumption stated above. 
				if ([userSettingPlugin objectForKey:[dct objectForKey:LWEPluginKeyKey]] == nil)
				{
					[dct setValue:[LWEFile createDocumentPathWithFilename:[dct objectForKey:LWEPluginTargetPathKey]] forKey:LWEPluginTargetPathKey];
					[md setValue:dct forKey:[dct objectForKey:LWEPluginKeyKey]];
				}
			}
			
			dict = [[NSDictionary alloc] initWithDictionary:md];
			[md release];

      [self _setAvailableForDownloadPlugins:dict];
			[dict release];
		}
	}
	else 
	{
		LWE_LOG(@"Debug : File for saving the available for download plugin %@ does not exist", LWE_AVAILABLE_PLUGIN_PLIST);
	}
}


/** This is new in 1.2, because prior to this, the list dictionary of dictionary for plugin is hardcoded in the code, and now it is moved to the flat file.
 * This method will try to load the downloaded plugin list from the user document folder, if it is not there it means the program first launched (after upgrade, or after install).
 * It has default bundle plist file which contains all of the "should be there" plugin list file, read from that, and check with the user settings, if the user has downloaded 
 * the plugin, it means that it should copy the one from the bundle, and populate the path to the plugin, and last step would be write the file back to the DOCUMENT folder.
 * However, if its not the first run, the user should already has the file in the DOCUMENT folder, and just load it from there directly.
 */
- (void) _initDownloadedPluginsList
{
  NSString *bundlePath = [LWEFile createBundlePathWithFilename:LWE_DOWNLOADED_PLUGIN_PLIST];
  NSString *docPath = [LWEFile createDocumentPathWithFilename:LWE_DOWNLOADED_PLUGIN_PLIST];

	if ([LWEFile fileExists:docPath])
	{
		LWE_LOG(@"Downloaded plugin plist content found in the document path");
		_downloadedPlugins = [[NSDictionary alloc] initWithContentsOfFile:docPath];
	}
	else if ([LWEFile fileExists:bundlePath])
	{
		LWE_LOG(@"Downloaded plugin plist found in the bundle path");
		NSDictionary *_plugin = [[NSDictionary alloc] initWithContentsOfFile:bundlePath];
		NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];
		NSArray *values = [_plugin allValues];
		NSDictionary *userSettingPlugin = [[NSUserDefaults standardUserDefaults] objectForKey:APP_PLUGIN];
    
		for (NSDictionary *dict in values)
		{
			NSString *key = [dict objectForKey:LWEPluginKeyKey];
			if (([key isEqualToString:CARD_DB_KEY]) || ([userSettingPlugin objectForKey:key]))
			{
				LWE_LOG(@"Added to the list of the downloaded list for key : %@", key);
				NSMutableDictionary *md = [NSMutableDictionary dictionaryWithDictionary:dict];
				NSString *path;
				
				//just a though, cause there are some cases that the plugin suddenly cant be loaded because the number xxxx-xxxx-xxx is changed
				//TODO: Think, is it better to put this when loading the data from the flat file too?
				
				//This is because the card db file will always be in the bundle file, while the other plugin
				//will be in the document path. This is important so that when the PluginManager
				//tries to load the plugin, it points to the right location.
				if ([key isEqualToString:CARD_DB_KEY])
        {
					path = [LWEFile createBundlePathWithFilename:[dict objectForKey:LWEPluginTargetPathKey]];
        }
				else 
        {
					path = [LWEFile createDocumentPathWithFilename:[dict objectForKey:LWEPluginTargetPathKey]];
				}
        
				[md setValue:path forKey:LWEPluginTargetPathKey];
				[dictionary setValue:md forKey:key];
			}
		}
		
		_downloadedPlugins = [dictionary retain];
		[_downloadedPlugins writeToFile:docPath atomically:YES];
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


#pragma mark -
#pragma mark Public Methods - Enable, load, disable plugins

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
  while ((key = [keyEnumerator nextObject]))
  {
    NSString* filename = [plugins objectForKey:key];
		LWE_LOG(@"LOG : Trying to load the installed plugins = %@, with filename = %@", key, filename);
    if ([self loadPluginFromFile:filename afterDownload:NO] == nil)
    {
      LWE_LOG(@"FAILED to load plugin: %@", filename);
      success = NO;
    }
  }
	
	if ([PluginManager isTimeForCheckingUpdate])
	{
		/**
		 * This only runs when the program is launched. 
		 * This private methods will be run in the background, because the dictionary which data is coming from the internet sometimes can take quite a few minutes. 
		 * And that process will block the UI. So, if the user click the button "Check For Update" This method will be called from the background, and it will update the badge
		 * number, and all of the data if it has finished.
		 */
    [self checkNewPluginsAsynchronous:YES notifyOnNetworkFail:NO];
	}
	
  return success;
}


/**
 * Loads a plugin from a file, returns plugin key name
 */
- (NSString*) loadPluginFromFile:(NSString*)filename afterDownload:(BOOL)afterDownload
{
	NSDictionary* pluginForFilename = nil;
	if (!afterDownload)
  {
		pluginForFilename = [self findDictionaryContainingObject:filename forKey:LWEPluginFilenameKey inDictionary:_downloadedPlugins];
  }
  else
  {
		pluginForFilename = [self findDictionaryContainingObject:filename forKey:LWEPluginFilenameKey inDictionary:self.availableForDownloadPlugins];
	}
  NSString *filePath = [pluginForFilename objectForKey:@"plugin_target_path"];
  
  LWE_LOG(@"Loading file: %@ in loadPluginFromFile", filename);
	// First, get database instance
  LWEDatabase *db = [LWEDatabase sharedLWEDatabase];
  
  // Make sure we can find the file - if not, it's probably after the user did a restore.  Try to recover!
  if (![LWEFile fileExists:filePath]) 
	{
    // Now try the relative path????
    [self _updatePluginPaths:NO pluginList:LWE_DOWNLOADED_PLUGIN_PLIST];
    [self _initDownloadedPluginsList];
    
    // And now re-call this, fix the variables so this method will continue to work
    pluginForFilename = [self findDictionaryContainingObject:filename forKey:LWEPluginFilenameKey inDictionary:_downloadedPlugins];
    filePath = [pluginForFilename objectForKey:@"plugin_target_path"];
    
    // Finally try it one more time
    if (![LWEFile fileExists:filePath])
    {
      // FAIL...
      LWE_LOG(@"%@", [NSString stringWithFormat:@"%@ couldnt be found when the file is trying to be loaded", filePath]);
      return nil;
    }
  }
  
  // Test drive the attachment to verify it matches
  if ([db attachDatabase:filePath withName:LWEDatabaseTempAttachName])
  {
    BOOL foundVersionTable = NO;
    NSString* pluginKey = [pluginForFilename objectForKey:@"plugin_key"];
    NSString *version = [db databaseVersionForDatabase:LWEDatabaseTempAttachName];
		if (version != nil)
		{
			//version table exists, and now extract the plugin key (otherwise keep as nil)
			foundVersionTable = YES;
		}
    [db detachDatabase:LWEDatabaseTempAttachName];
    
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
        LWE_LOG(@"Could not re-attach database w/ new name - pluginKey invalid?");
      }
    }
    else
    {
      LWE_LOG(@"Attached database, but could not find version table data");
    }
  }
  else 
  {
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
	
  if ((pluginKey = [self loadPluginFromFile:filename afterDownload:YES]))
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
  [[NSNotificationCenter defaultCenter] postNotificationName:LWEPluginDidInstall object:self userInfo:[_downloadedPlugins objectForKey:pluginKey]];
  return YES;
}

#pragma mark -
#pragma mark Public Methods - Find out about plugin state

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
 * Returns the version string of a plugin, or nil if the key is not a loaded plugin
 */
- (NSString*) versionForLoadedPlugin:(NSString*)key
{
  NSDictionary *dict = [_loadedPlugins objectForKey:key];
  if (dict)
  {
    return [dict objectForKey:@"plugin_version"];
  }
  else
  {
    return nil;
  }
}

//! Gets array of dictionaries with all info about loaded plugins
- (NSArray*) loadedPlugins
{
  return [self _plugins:_loadedPlugins];
}

//! Gets array of NSString keys of plugins
- (NSArray*) loadedPluginsByKey;
{
  NSEnumerator *keyEnumerator = [_loadedPlugins keyEnumerator];
  NSString *key;
  NSMutableArray *tmpArray = [[NSMutableArray alloc] init];
  while ((key = [keyEnumerator nextObject]))
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
  while ((tmpDict = [_loadedPlugins objectForKey:[enumerator nextObject]]))
  {
    [tmpArray addObject:[tmpDict objectForKey:@"name"]];
  }
  // Make immutable copy
  NSArray *returnArray = [NSArray arrayWithArray:tmpArray];
  [tmpArray release];
  return returnArray;
}

- (NSArray*) downloadedPlugins
{
	return [self _plugins:_downloadedPlugins];
}

//! Gets all available plugins as a dictionary
- (NSDictionary*) availablePluginsDictionary
{
  return [NSDictionary dictionaryWithDictionary:self.availableForDownloadPlugins];
}

//! Gets array of dictionaries with available plugins that are not loaded
- (NSArray*) availablePlugins
{
	return [self.availableForDownloadPlugins allValues];
}

#pragma mark -

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

/**
 * Tells whether update check is necessary
 * \return YES if settings' PLUGIN_LAST_UPDATE is more than LWE_PLUGIN_UPDATE_PERIOD days ago
 */
+ (BOOL) isTimeForCheckingUpdate
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


/**
 * Check the new plugin over the website, and looks whether it has a new stuff
 * \param asynch If YES, the URL retrieve will happen on a background thread (the processing afterward will remain on the main thread)
 * \param notifyOnNetworkFail If YES, and network is not available, will prompt a LWEUIAlertView noNetwork alert
 */
- (void)checkNewPluginsAsynchronous:(BOOL)asynch notifyOnNetworkFail:(BOOL)notifyOnNetworkFail
{	
  // Check if they have network first, if so, start the background thread
	if ([LWENetworkUtils networkAvailableFor:LWE_PLUGIN_SERVER_LIST])
	{
    if (asynch)
    {
      [self performSelectorInBackground:@selector(_retrievePlistFromServer) withObject:nil];
    }
    else
    {
      [self _retrievePlistFromServer];
    }

  }
  else if (notifyOnNetworkFail)
  {
    [LWEUIAlertView noNetworkAlert];
  }
}

#pragma mark -
#pragma mark Privates

/**
 * Updates the plugin paths if necessary (for example if they changed after a restore)
 * Passing a YES as a paramater to this method will MESS UP any installation - it is for debugging!
 */
- (void) _updatePluginPaths:(BOOL) debug pluginList:(NSString*)plistFileName
{
  NSString *docPath = [LWEFile createDocumentPathWithFilename:plistFileName];
  NSDictionary *pluginDictionary = [[NSDictionary alloc] initWithContentsOfFile:docPath];
  LWE_LOG(@"Old dictionary: %@",pluginDictionary);

  // Create a new dictionary for messing around
  NSMutableDictionary *newDictionary = [[NSMutableDictionary alloc] init];
  
  NSEnumerator *keyEnumerator = [pluginDictionary keyEnumerator];
  NSString *key = nil;
  NSDictionary *tmpDict = nil;
  while ((key = [keyEnumerator nextObject]))
  {
    tmpDict = [pluginDictionary objectForKey:key];
  
    // Manipulate the plugin_target_path
    NSString *currentPath = [tmpDict valueForKey:@"plugin_target_path"];
    NSString *newPath = nil;
    // If we are debugging, purposefully mess up the path, otherwise fix the sucker
    if (debug)
    {
      newPath = [NSString stringWithFormat:@"/foo%@",currentPath];
    }
    else
    {
      // Cards DB is always in the bundle
      if ([key isEqualToString:CARD_DB_KEY])
      {
        newPath = [LWEFile createBundlePathWithFilename:[tmpDict valueForKey:LWEPluginFilenameKey]];
      }
      else
      {
        newPath = [LWEFile createDocumentPathWithFilename:[tmpDict valueForKey:LWEPluginFilenameKey]];
      }
    }
    
    LWE_LOG(@"FULLPATH BUG: old path was: %@",currentPath);
    LWE_LOG(@"FULLPATH BUG: new path is: %@",newPath);
    
    // Make a muddled dictionary
    NSMutableDictionary *tmpMutableDict = [tmpDict mutableCopy];
    [tmpMutableDict setValue:newPath forKey:@"plugin_target_path"];

    // Copy everything over to the new dictionary
    [newDictionary setValue:tmpMutableDict forKey:[tmpDict valueForKey:@"plugin_key"]];
    [tmpMutableDict release];
  }
  LWE_LOG(@"New dictionary: %@",newDictionary);
  
  [newDictionary writeToFile:docPath atomically:YES];
  [newDictionary release];
  [pluginDictionary release];
}

/**
 * Intended to be run in the background so we don't lock the main thread
 */
- (void)_retrievePlistFromServer
{
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  NSDictionary *dictionary = [[NSDictionary alloc] initWithContentsOfURL:[NSURL URLWithString:LWE_PLUGIN_SERVER_LIST]];
  [pool release];
  [self performSelectorOnMainThread:@selector(_plistDidDownload:) withObject:dictionary waitUntilDone:NO];
}

/**
 * Callback when server plist request is finished
 */
- (void)_plistDidDownload:(NSDictionary*)dictionary
{
  //Set up the variable to be the 
  NSMutableDictionary *downloadablePluginHash = nil;
  if (self.availableForDownloadPlugins != nil)
  {
    downloadablePluginHash = [[NSMutableDictionary alloc] initWithDictionary:self.availableForDownloadPlugins];
  }
  else
  {
    downloadablePluginHash = [[NSMutableDictionary alloc] init];
  }

  // If downloaded plugin is something we can use?
	if (dictionary)
	{
		NSArray *plugins = [dictionary objectForKey:@"Plugins"];
		[self _checkPluginVersionAgainstDownloadedPlist:downloadablePluginHash plugins:plugins];
		
		//Set the available for download plugin dictionary, to be persisted in the flat file, and set the badge.
		[self _setAvailableForDownloadPlugins:downloadablePluginHash];
	}
  [downloadablePluginHash release];

	// This is a rare exception to "I didn't make it so I won't release it".  This is inter-thread, so keep this sucker here
  [dictionary release];
}

/**
 * This handy method will pass in the Dictionary<Dictionary> which each of the dictionary inside is the information about all the list of what the user needs to download,
 * but the user has not downloaded it. The second parameter is the plugin information (up-to-date version) which came from the internet somewhere. 
 *
 */
- (void) _checkPluginVersionAgainstDownloadedPlist: (NSMutableDictionary *) awaitsUpdatePlugins plugins: (NSArray *) plugins
{
  NSDictionary *pluginSettings = [[NSUserDefaults standardUserDefaults] objectForKey:APP_PLUGIN];
  LWEDatabase *db = [LWEDatabase sharedLWEDatabase];
  
  // wraps the checking version in the database with the transaction. 
  [db.dao beginDeferredTransaction];
  for (NSDictionary *plugin in plugins)
  {
    NSString *pluginKey = [plugin objectForKey:LWEPluginKeyKey];
    NSString *installedPlugin = [pluginSettings objectForKey:pluginKey];
    NSString *awaitsUpdate = [awaitsUpdatePlugins objectForKey:pluginKey];
    BOOL needUpdate = NO;
    
    //The user already had the plugin on the user setting, and checks whether thats outdated
    if ((installedPlugin) && (!awaitsUpdate))
    {
      double pluginVersion = [[plugin objectForKey:LWEPluginVersionKey] doubleValue];
      double installedVersion = [[db databaseVersionForDatabase:pluginKey] doubleValue];
      
      LWE_LOG(@"Debug : Installed version %f, plugin version %f, need upgrade? %@", installedVersion, pluginVersion, (pluginVersion > installedVersion) ? @"YES" : @"NO");
      if (pluginVersion > installedVersion)
      {
        needUpdate = YES;
      }
    }
    else
    {
      //The user has not had the update, BUT it might already been in the list of update pluggin awaits the user to update. 
      //in that case, I chose to rewrite the list with the new one anyway. There are only 2 possibilities, it either the new one
      //from the web is the newer version, or the same. It does not matter, we still want it to be on the user awaits update plugin
      //list anyway. 
      needUpdate = YES;
    }
		
    
    //Needss update means it will add the plugin dictionary to the mutable dictionary initialized
    //in the beginning of this method.
    //Before doing that, it also tried to fix the plugin_target_path to be the document path of the device.
    if (needUpdate)
    {
      NSString *plugin_path = [plugin objectForKey:LWEPluginTargetPathKey];
      [plugin setValue:[LWEFile createDocumentPathWithFilename:plugin_path] forKey:LWEPluginTargetPathKey];
      [awaitsUpdatePlugins setValue:plugin forKey:pluginKey];
    }
  }
  [db.dao commit];
}

/**
 * Convinient method to check whether the new update is the updated version. 
 * Its going to return the key of the updated plugin, if the plugin downloaded is an update, not just a fresh install.
 *
 */
- (NSString *)_checkWhetherAnUpdate:(NSString *)path
{
  NSString *result = nil;
	NSDictionary *dict = [self findDictionaryContainingObject:path forKey:LWEPluginTargetPathKey inDictionary:self.availableForDownloadPlugins];
	NSString *keyString = [dict objectForKey:LWEPluginKeyKey];
	//check whether they the user already had it in the user settings.
	NSDictionary *installedPlugin = [[NSUserDefaults standardUserDefaults] objectForKey:APP_PLUGIN];
	NSDictionary *pluginBeingInstalled = [installedPlugin objectForKey:keyString];
	//Means there are stuffs in the user default.
	//Next thing is to check whether the plugin installed in the user device has the
	//updated version, or the downloaded is the updated one. 
	if (pluginBeingInstalled)
	{
		//I dont think we need to check the version again, since If its already in the user settings.
		//It should be an update. Nothing else
		result = keyString;
	}
	return result;
}


/**
 * This is the setter for available for download plugin. 
 * However, unlike the usual setter, it also sets the badge number via notification to the RootViewController
 * and it also persist that in the file. 
 */
- (void)_setAvailableForDownloadPlugins:(NSDictionary *)dict
{
  // Standard setter
  [self setAvailableForDownloadPlugins:dict];
	
  // Additional processing - write out to file
	[self.availableForDownloadPlugins writeToFile:[LWEFile createDocumentPathWithFilename:LWE_AVAILABLE_PLUGIN_PLIST] atomically:YES];
	
	//Try to update the last update in the user setting
	NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
	[settings setObject:[NSDate date] forKey:PLUGIN_LAST_UPDATE];
	
	//Update the badge in the settings. 
	LWE_LOG(@"Debug : New %d update(s)",[dict count]);
	NSNumber *newUpdate = [NSNumber numberWithInt:[dict count]];
	[self performSelector:@selector(_sendUpdateBadgeNotification:) withObject:newUpdate afterDelay:1.0f];
}

/**
 * This method is going to be called to perform a badge number update, and send the notification to whoever cares about badge number update.
 */
- (void)_sendUpdateBadgeNotification:(NSNumber *)badgeNumber
{
	NSDictionary *userDict = [NSDictionary dictionaryWithObject:badgeNumber forKey:@"badge_number"];
	[[NSNotificationCenter defaultCenter] postNotificationName:LWEShouldUpdateSettingsBadge object:self userInfo:userDict];
}

/**
 * This is the handy method to delete the key from the available download for plugin dictionary
 * enable the use to see the updated plugin, and the new number badge of the available download for plugin. 
 */
- (void)_removeFromAvailableDownloadForPlugin:(NSString *)pluginKey
{
	NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithDictionary:[self availableForDownloadPlugins]];
	[dict removeObjectForKey:pluginKey];
	LWE_LOG(@"Called _setAvailableForDownloadPlugins from _removeFromAvailableDownloadForPlugin");
	[self _setAvailableForDownloadPlugins:dict];
  [dict release];
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
  while ((key = [keyEnumerator nextObject]))
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
	if (availableForDownloadPlugins) [availableForDownloadPlugins release];
  if (_loadedPlugins) [_loadedPlugins release];
  [super dealloc];
}

#pragma mark -

NSString * const LWEPluginDidInstall = @"LWEPluginDidInstall";
NSString * const LWEPluginKeyKey = @"plugin_key";
NSString * const LWEPluginNameKey = @"plugin_name";
NSString * const LWEPluginVersionKey = @"plugin_version";
NSString * const LWEPluginFilenameKey = @"plugin_file_name";
NSString * const LWEPluginTargetPathKey = @"plugin_target_path";

@end
