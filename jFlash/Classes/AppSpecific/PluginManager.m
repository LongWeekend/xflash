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

NSString * const LWEShouldUpdateSettingsBadge	= @"LWEShouldUpdateSettingsBadge";

@interface PluginManager ()
- (void)_initAvailableForDownloadPluginsList;
- (void)_initDownloadedPluginsList;

- (void) _registerPlugin:(Plugin *)plugin;
- (BOOL) _loadDatabasePlugin:(Plugin *)plugin error:(NSError **)error;
@end

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
		_downloadedPlugins = nil; //[NSMutableArray array];
    self.availableForDownloadPlugins = nil;

		[self _initAvailableForDownloadPluginsList];
		[self _initDownloadedPluginsList];
    
    [self addObserver:self forKeyPath:@"availableForDownloadPlugins" options:NSKeyValueObservingOptionNew context:NULL];
	}
  return self;
}

/** 
 * This method will try to load the "available for download" plugin list from the user document folder,
 * if it is not there it means the program first launched (after upgrade, or after install).
 *
 * It has default bundle plist file which contains all of the "should be available for download"
 * plugin list file, read from that, and check with the user settings, if the user has not downloaded
 * the plugin, it means that it should copy the one from the bundle, and populate the path to the plugin,
 * and last step would be write the file back to the DOCUMENT folder.
 *
 * However, if its not the first run, the user should already has the file in the DOCUMENT folder, and
 * just load it from there directly.
 *
 * UPDATE: After given some thought, it would be best to read from file only if the device not
 * connected to the internet, if the device is connected, it should check for update right away.
 */

- (void) _initAvailableForDownloadPluginsList
{
	NSString *docPath = [LWEFile createDocumentPathWithFilename:LWE_AVAILABLE_PLUGIN_PLIST];
  NSString *bundlePath = [LWEFile createBundlePathWithFilename:LWE_AVAILABLE_PLUGIN_PLIST];
  
  BOOL docPathExists = [LWEFile fileExists:docPath];
  BOOL bundlePathExists = [LWEFile fileExists:bundlePath];
  LWE_ASSERT_EXC((docPathExists || bundlePathExists), @"PLIST must exist somewhere!  Checked: %@ AND %@",docPath,bundlePath);
    
	if (docPathExists)
	{
    self.availableForDownloadPlugins = [NSMutableDictionary dictionaryWithContentsOfFile:docPath];
	}
	else if (bundlePathExists)
	{
		if ([LWENetworkUtils networkAvailableFor:LWE_PLUGIN_SERVER] == NO)
		{
			NSDictionary *installedPluginsDict = [[NSUserDefaults standardUserDefaults] objectForKey:APP_PLUGIN];
			NSArray *plugins = [[NSDictionary dictionaryWithContentsOfFile:bundlePath] objectForKey:@"Plugins"];
			
			NSMutableDictionary *availablePlugins = [NSMutableDictionary dictionary];
			for (NSDictionary *pluginHash in plugins)
			{
        Plugin *plugin = [Plugin pluginWithDictionary:pluginHash];
				if ([installedPluginsDict objectForKey:plugin.pluginId] == nil)
				{
					[availablePlugins setValue:plugin forKey:plugin.pluginId];
				}
			}
      self.availableForDownloadPlugins = availablePlugins;
		}
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

  BOOL docPathExists = [LWEFile fileExists:docPath];
  BOOL bundlePathExists = [LWEFile fileExists:bundlePath];
  LWE_ASSERT_EXC((docPathExists || bundlePathExists), @"PLIST must exist somewhere!  Checked: %@ AND %@",docPath,bundlePath);
  
  _downloadedPlugins = [[NSMutableArray alloc] init];
	if (docPathExists)
	{
    NSArray *plugins = [[NSDictionary dictionaryWithContentsOfFile:docPath] allValues];
    for (NSDictionary *pluginHash in plugins)
    {
      [_downloadedPlugins addObject:[Plugin pluginWithDictionary:pluginHash]];
    }
	}
	else if (bundlePathExists)
	{
    // Check this once
    NSDictionary *userSettingPlugin = [[NSUserDefaults standardUserDefaults] objectForKey:APP_PLUGIN];

		NSArray *pluginHashes = [[NSDictionary dictionaryWithContentsOfFile:bundlePath] allValues];
		for (NSDictionary *pluginHash in pluginHashes)
		{
      Plugin *plugin = [Plugin pluginWithDictionary:pluginHash];
      BOOL pluginInSettings = ([userSettingPlugin objectForKey:plugin.pluginId] != nil);
      BOOL isCardDB = [plugin.pluginId isEqualToString:CARD_DB_KEY];
      
      // If Cards DB or already in settings (somehow??!)
			if (isCardDB || pluginInSettings)
			{
        [_downloadedPlugins addObject:plugin];
			}
		}
    
    // Now write to to the docs path so we have it for next time
		[_downloadedPlugins writeToFile:docPath atomically:YES];
	}
}

#pragma mark - Public Methods - Enable, load, disable plugins

/**
 * Takes the plugin out of active use. NOOP for file-based add-ons
 */
- (BOOL) disablePlugin:(Plugin*)plugin
{
  // First, make sure the plugin is actually loaded
  BOOL returnVal = NO;
  if ([_loadedPlugins objectForKey:plugin.pluginId] && plugin.isDatabasePlugin)
  {
    LWEDatabase *db = [LWEDatabase sharedLWEDatabase];
    if ([db detachDatabase:plugin.name])
    {
      [_loadedPlugins removeObjectForKey:plugin.pluginId];
      returnVal = YES;
    }
  }
  return returnVal;
}


/**
 * Load all plugins from settings file, after loading all of the downloaded plugin.
 * It also checks whether this is the right time for checking the new update. 
 */
- (BOOL) loadInstalledPlugins
{
  BOOL success = YES;
  NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
  NSDictionary *plugins = [settings objectForKey:APP_PLUGIN];
  for (NSString *pluginKey in plugins)
  {
    // Re-instantiate the plugins here
    NSData *data = [plugins objectForKey:pluginKey];
    Plugin *plugin = (Plugin*)[NSKeyedUnarchiver unarchiveObjectWithData:data];
    
    // Now try to load it
    NSError *error = nil;
    success = (success && [self loadPlugin:plugin error:&error]);
  }
  return success;
}  


/**
 * Loads a plugin from a file, returns plugin key name
 */
- (BOOL) loadPlugin:(Plugin *)plugin error:(NSError **)error;
{
  // You can't reload a plugin that's already loaded.
  if ([_loadedPlugins objectForKey:plugin.pluginId])
  {
    return YES;
  }
  
  // If it's a directory, just make sure it exists only.
  BOOL pathExists = [LWEFile fileExists:[plugin fullPath]];
  if (pathExists == NO)
  {
    // TODO: MORE ROBUST CODE HERE PLEEEZE
    // Make sure we can find the file - if not, it's probably after the user did a restore.  Try to recover!
    if (error != NULL)
    {
      *error = [NSError errorWithCode:5 localizedDescription:@"Cannot find plugin file/directory."];
    }
    return NO;
  }
  
  BOOL returnVal = YES;
  
  // Test drive database plugins to verify an OK plugin
  if (plugin.isDatabasePlugin)
  {
    returnVal = [self _loadDatabasePlugin:plugin error:error];
  }
  
  // If we were successful, add to the array
  if (returnVal)
  {
    [_loadedPlugins setValue:plugin forKey:plugin.pluginId];
  }
  return returnVal;
}

- (BOOL) _loadDatabasePlugin:(Plugin *)plugin error:(NSError **)error
{
  LWE_ASSERT_EXC(plugin.isDatabasePlugin, @"You must pass a database plugin to use this method.");
  LWEDatabase *db = [LWEDatabase sharedLWEDatabase];
  
  // 1) Can we attach the database?
  if ([db attachDatabase:[plugin fullPath] withName:LWEDatabaseTempAttachName] == NO)
  {
    // Fail and return!
    *error = [NSError errorWithCode:1 localizedDescription:@"Failed to attach database"];
    return NO;
  }
  
  // 2) Does it pass a version test?
  NSString *version = [db databaseVersionForDatabase:LWEDatabaseTempAttachName];
  [db detachDatabase:LWEDatabaseTempAttachName];
  if (version == nil)
  {
    *error = [NSError errorWithCode:2 localizedDescription:@"Attached database, but could not find version table data"];
    return NO;
  }
  
  // 3) Reattach with proper name
  if ([db attachDatabase:[plugin fullPath] withName:plugin.pluginId] == NO)
  {		  
    *error = [NSError errorWithCode:3 localizedDescription:@"Could not re-attach database w/ new name - pluginId invalid?"];
    return NO;
  }
  return YES;
}

/**
 * Installs a plugin.
 * Returns YES on success, no on failure (with error)
 */
- (BOOL) installPlugin:(Plugin *)plugin error:(NSError **)error;
{
  LWE_ASSERT_EXC((plugin && [plugin isKindOfClass:[Plugin class]]), @"Don't be like that, fool. I take plugins.");
  
  // 1. Get our previous version if we have one, disable it
  Plugin *oldPlugin = [_loadedPlugins objectForKey:plugin.pluginId];
  if (oldPlugin)
  {
    [self disablePlugin:oldPlugin];
  }
  
  // 2. Load it -- quick return on failure
  if ([self loadPlugin:plugin error:error] == NO)
  {
    // Well, put the old one back - no need to keep track of the error
    [self loadPlugin:oldPlugin error:NULL];
    return NO;
  }
  
  // 3. Register it
  [self _registerPlugin:plugin];
  
  // 4. Set not to be backed up
  BOOL isNotBackedUp = [LWEFile addSkipBackupAttributeToItemAtPath:[plugin fullPath]];
  LWE_ASSERT_EXC(isNotBackedUp, @"Failed to set skip backup attribute for file at %@", plugin.filePath);
  
  // 5. Be nice, delete the old plugin
  if (oldPlugin)
  {
    [LWEFile deleteFile:oldPlugin.filePath];
  }
  
  // 6. Update the downloaded plugins array.  Also write it to disk to mark this plugin as "downloaded"
  [_downloadedPlugins addObject:plugin];
  [_downloadedPlugins writeToFile:[LWEFile createDocumentPathWithFilename:LWE_DOWNLOADED_PLUGIN_PLIST] atomically:YES];
  
  // 7. Finally, remove from available downloads
  [self.availableForDownloadPlugins removeObjectForKey:plugin.pluginId];
  
  // 8. Tell anyone who cares that we've just successfully installed a plugin
  [[NSNotificationCenter defaultCenter] postNotificationName:LWEPluginDidInstall object:plugin userInfo:nil];

  return YES;
}

#pragma mark - Public Methods - Find out about plugin state

/**
 * Returns a dictionary with KEY => plugin filename of preinstalled plugins
 */
+ (NSDictionary *) preinstalledPlugins;
{
  return [NSDictionary dictionaryWithObjectsAndKeys:LWE_CURRENT_CARD_DATABASE,CARD_DB_KEY,nil];
}

- (NSDictionary *) downloadedPlugins
{
  return (NSDictionary *)[[_downloadedPlugins retain] autorelease];
}

//! Returns the version string of a plugin, or nil if the key is not a loaded plugin
- (NSString *) versionForLoadedPlugin:(NSString*)key
{
  NSString *returnVal = nil;
  for (Plugin *plugin in _loadedPlugins)
  {
    if ([plugin.pluginId isEqualToString:key])
    {
      returnVal = plugin.version;
    }
  }
  return returnVal;
}

//! Tells whether or not a plugin is in the dictionary as loaded
- (BOOL) pluginKeyIsLoaded:(NSString *)pluginKey
{
  return ([_loadedPlugins objectForKey:pluginKey] != nil);
}

- (Plugin *)pluginForKey:(NSString *)pluginKey
{
  return [_loadedPlugins objectForKey:pluginKey];
}
#pragma mark - 

- (void) processPlistHash:(NSDictionary*)plistHash
{
  LWE_ASSERT_EXC(plistHash, @"You must pass a proper hash to this method!");
  for (NSDictionary *availPluginHash in [plistHash objectForKey:@"Plugins"])
  {
    // There are 3 cases we would want to incorporate a new value:
    // 1) When there is an update to an installed plugin,
    // 2) When there is an update to an uninstalled plugin,
    // 3) When there is a brand new plugin we knew nothing about
    
    Plugin *availPlugin = [Plugin pluginWithDictionary:availPluginHash];
    Plugin *waitingToDownloadPlugin = [self.availableForDownloadPlugins objectForKey:availPlugin.pluginId];
    Plugin *currPlugin = [_loadedPlugins objectForKey:availPlugin.pluginId];
    
    // Determine whether case 1) or 2) applies
    BOOL installedPluginNeedsUpdate = (currPlugin && [availPlugin isNewVersionOfPlugin:currPlugin]);
    BOOL waitingToInstallPluginNeedsUpdate = (waitingToDownloadPlugin && [availPlugin isNewVersionOfPlugin:waitingToDownloadPlugin]);
    BOOL isNewPlugin = ((currPlugin == nil) && (waitingToDownloadPlugin == nil));
    
    if (installedPluginNeedsUpdate || waitingToInstallPluginNeedsUpdate || isNewPlugin)
    {
      [self.availableForDownloadPlugins setValue:availPlugin forKey:availPlugin.pluginId];
    }
  }
}


#pragma mark - KVO for available plugins dictionary

/**
 * This is the setter for available for download plugin. 
 * However, unlike the usual setter, it also sets the badge number via notification to the RootViewController
 * and it also persist that in the file. 
 */
- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
  // Additional processing - write out to file
	[self.availableForDownloadPlugins writeToFile:[LWEFile createDocumentPathWithFilename:LWE_AVAILABLE_PLUGIN_PLIST] atomically:YES];
	
	//Update the badge in the settings. 
  //	LWE_LOG(@"Debug : New %d update(s)",[dict count]);
	NSNumber *badgeNumber = [NSNumber numberWithInt:[self.availableForDownloadPlugins count]];
	NSDictionary *userDict = [NSDictionary dictionaryWithObject:badgeNumber forKey:@"badge_number"];
	[[NSNotificationCenter defaultCenter] postNotificationName:LWEShouldUpdateSettingsBadge object:self userInfo:userDict];
}

#pragma mark -

/**
 * Register plugin filename with NSUserDefaults
 *
 * Returns NO means that the system user setting has already had the key, so this is a plugin update
 * YES means this is a refresh plugin install.
 *
 */
- (void) _registerPlugin:(Plugin *)plugin
{
  // Update the settings so we maintain this on startup
  NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
  NSDictionary *pluginSettings = [settings objectForKey:APP_PLUGIN];
  LWE_ASSERT_EXC(pluginSettings,@"Whoa, how can we run this method without default plugin settings?");
  
  // We have to change one key, so create a mutable dict.  Kind of a waste, but.  Serialize the plugin
  NSMutableDictionary *tmpDict = [NSMutableDictionary dictionaryWithDictionary:pluginSettings];
  [tmpDict setObject:[NSKeyedArchiver archivedDataWithRootObject:plugin] forKey:plugin.pluginId];
  [settings setValue:tmpDict forKey:APP_PLUGIN];
  [settings synchronize];
}

#pragma mark - Memory Management

- (void)dealloc
{
  [self removeObserver:self forKeyPath:@"availableForDownloadPlugins"];
  
	[availableForDownloadPlugins release];
  [_downloadedPlugins release];
  [_loadedPlugins release];
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
