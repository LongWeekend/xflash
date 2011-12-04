//
//  CurrentState.m
//  jFlash
//
//  Created by Mark Makdad on 7/12/09.
//  Copyright 2009 LONG WEEKEND INC.. All rights reserved.
//

#import "CurrentState.h"
#import "UpdateManager.h"

// For private methods
@interface CurrentState ()
- (void) _createDefaultSettings;
- (void) _retrievePlistFromServer;
@end

NSString * const LWEActiveTagDidChange = @"LWEActiveTagDidChange";

/**
 * Maintains the current state of the application (active set, etc).  Is a singleton.
 * Owns the plugin manager (to be debated whether that is the best design or not)
 */
@implementation CurrentState
@synthesize isFirstLoad, pluginMgr, isUpdatable, starredTag, modalTaskViewController;
@synthesize activeTag = _activeTag;

SYNTHESIZE_SINGLETON_FOR_CLASS(CurrentState);

/**
 * Sets the current active study set/tag - also loads cardIds for the tag
 */
- (void) setActiveTag:(Tag*)tag
{
  BOOL firstRun = (_activeTag == nil);
  [tag populateCardIds];
  LWE_ASSERT_EXC((tag.cardCount > 0),@"Whoa, somehow we set a tag that has zero cards!");

  // This code is so we can figure out what our users are studying (only system sets)
  if (tag.tagEditable == 0 && firstRun == NO)
  {
    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:tag.tagId] forKey:@"id"];
    [LWEAnalytics logEvent:LWEActiveTagDidChange parameters:userInfo];
  }

  @synchronized (self)
  {
    [_activeTag release];
    _activeTag = [tag retain];
  }
  
  NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
  [settings setInteger:tag.tagId forKey:@"tag_id"];
  
  // Set the favorites tag, if not already done
  if (self.starredTag == nil)
  {
    self.starredTag = [Tag starredWordsTag];
  }
  
  // Tell everyone to reload their data (only if we're not just starting up)
  if (firstRun == NO)
  {
    [[NSNotificationCenter defaultCenter] postNotificationName:LWEActiveTagDidChange object:_activeTag];
  }
}


/**
 * Returns the current active study set/tag
 */
- (Tag *) activeTag
{
  if (_activeTag == nil || [_activeTag cardCount] == 0)
  {
    NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
    NSInteger storedTagId = [settings integerForKey:@"tag_id"];
    [self setActiveTag:[TagPeer retrieveTagById:storedTagId]];
    NSInteger currentIndex = [settings integerForKey:@"current_index"];
    // Do not use getter here - it may cause an infinite loop if the card count of the active tag is 0 (which should never hapen but)
    [_activeTag setCurrentIndex:currentIndex];
  }
  
  return [[_activeTag retain] autorelease];
}


/**
 * Reloads cardIds for active set
 */
- (void) resetActiveTag
{
  LWE_ASSERT_EXC(_activeTag,@"Call to resetActiveTag but no tag active");
  [self setActiveTag:_activeTag];
}

#pragma mark - LWEPackageDownloaderDelegate Methods

- (void) unpackageFinished:(LWEPackage*)package
{
  NSError *error = nil;
  Plugin *plugin = [package.userInfo objectForKey:@"plugin"];
  [self.pluginMgr installPlugin:plugin error:&error];
  [self.modalTaskViewController dismissModalViewControllerAnimated:YES];
}

- (void) unpackageFailed:(LWEPackage*)package withError:(NSError*)error
{
  LWE_LOG(@"%@",error);
  [self.modalTaskViewController dismissModalViewControllerAnimated:YES];
}

#pragma mark - Initialization

/**
 * Retrieve & initialize settings from NSUserDefaults to CurrentState object
 * It is vital for jFlash that this be the first thing called before ANY user
 * functionality is called to prevent versioning issues
 */
- (void) initializeSettings
{
  NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
  
  // ADD OBSERVER FOR DB COPY!
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(registerDatabaseCopied) name:LWEDatabaseCopyDatabaseDidSucceed object:nil];
   
  // STEP 1 - Migrations for settings for different versions of JFlash
  [UpdateManager performMigrations:settings];

  // STEP 2 - is the database update-able?  Let the update manager tell us
  [self setIsUpdatable:[UpdateManager databaseIsUpdatable:settings]];

  // STEP 3 - Initialize the plugin manager
  self.pluginMgr = [[[PluginManager alloc] init] autorelease];
  
  // STEP 4 - is this first run after a fresh install?  Do we need to freshly create settings?
  if ([settings objectForKey:@"settings_already_created"] == nil)
  {
    [self _createDefaultSettings];
    self.isFirstLoad = YES;
  }
  else
  {
    self.isFirstLoad = NO;
  }
  
  // STEP 5
  // We initialize the plugins manager
	if ([[self class] isTimeForCheckingUpdate])
	{
		/**
		 * This only runs when the program is launched. 
		 * This private methods will be run in the background, because the dictionary which data is coming from the internet sometimes can take quite a few minutes. 
		 * And that process will block the UI. So, if the user click the button "Check For Update" This method will be called from the background, and it will update the badge
		 * number, and all of the data if it has finished.
		 */
    [self checkNewPluginsAsynchronous:YES notifyOnNetworkFail:NO];
	}
}


/** Registers the db_did_finish_copying BOOL value in NSUserDefaults when called */
- (void) registerDatabaseCopied
{
  NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
  [settings setBool:YES forKey:@"db_did_finish_copying"];
}

#pragma mark - Default - First time run.

/** Create & store default settings to NSUserDefaults */
- (void) _createDefaultSettings
{
  LWE_LOG(@"Creating the default settings");
  NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
  
#if defined(LWE_JFLASH)
  [settings setValue:SET_READING_BOTH forKey:APP_READING];
#elif defined(LWE_CFLASH)
  [settings setValue:SET_HEADWORD_TYPE_SIMP forKey:APP_HEADWORD_TYPE];
  [settings setValue:SET_PINYIN_COLOR_ON forKey:APP_PINYIN_COLOR];
#endif
    
  [settings setValue:DEFAULT_THEME forKey:APP_THEME];
  [settings setValue:SET_MODE_QUIZ forKey:APP_MODE];
  [settings setValue:SET_J_TO_E forKey:APP_HEADWORD];
  [settings setValue:LWE_CURRENT_VERSION forKey:APP_DATA_VERSION];
  [settings setValue:LWE_CURRENT_VERSION forKey:APP_SETTINGS_VERSION];
  [settings setInteger:DEFAULT_TAG_ID forKey:@"tag_id"];
  [settings setInteger:DEFAULT_USER_ID forKey:APP_USER];
  [settings setInteger:DEFAULT_FREQUENCY_MULTIPLIER forKey:APP_FREQUENCY_MULTIPLIER];
  [settings setInteger:DEFAULT_MAX_STUDYING forKey:APP_MAX_STUDYING];
  [settings setInteger:DEFAULT_DIFFICULTY forKey:APP_DIFFICULTY];
  [settings setValue:[NSDictionary dictionary] forKey:APP_PLUGIN];
  [settings setValue:[NSDate dateWithTimeIntervalSince1970:0] forKey:PLUGIN_LAST_UPDATE];
  [settings setBool:NO forKey:APP_HIDE_BURIED_CARDS];
  [settings setBool:NO forKey:@"db_did_finish_copying"];
  [settings setBool:YES forKey:@"settings_already_created"];
  [settings synchronize];
}

#pragma mark - Plugin Manager helpers

+ (BOOL) pluginKeyIsLoaded:(NSString *)key
{
  CurrentState *state = [CurrentState sharedCurrentState];
  return [state.pluginMgr pluginKeyIsLoaded:key];
}

+ (Plugin *) availablePluginForKey:(NSString *)key
{
  CurrentState *state = [CurrentState sharedCurrentState];
  return [state.pluginMgr.downloadablePlugins objectForKey:key];
}

+ (Plugin *) loadedPluginForKey:(NSString *)key
{
  CurrentState *state = [CurrentState sharedCurrentState];
  return [state.pluginMgr pluginForKey:key];
}

/**
 * Tells whether update check is necessary
 * \return YES if settings' PLUGIN_LAST_UPDATE is more than LWE_PLUGIN_UPDATE_PERIOD days ago
 */
+ (BOOL) isTimeForCheckingUpdate
{
	NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
	NSDate *date = [settings objectForKey:PLUGIN_LAST_UPDATE];
	date = [date addDays:LWE_PLUGIN_UPDATE_PERIOD];
	NSDate *now = [NSDate date];
	
	//date is earlier than now, means it is for update
	if ([date compare:now] == NSOrderedAscending)
  {
		return YES;
  }
	else 
  {
		return NO;
  }
}

/**
 * Check the new plugin over the website, and looks whether it has a new stuff
 * \param asynch If YES, the URL retrieve will happen on a background thread (the processing afterward will remain on the main thread)
 * \param notifyOnNetworkFail If YES, and network is not available, will prompt a LWEUIAlertView noNetwork alert
 */
- (void)checkNewPluginsAsynchronous:(BOOL)asynch notifyOnNetworkFail:(BOOL)notifyOnNetworkFail
{	
  // Check if they have network first, if so, start the background thread
	if ([LWENetworkUtils networkAvailableFor:LWE_PLUGIN_SERVER])
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


/**
 * Intended to be run in the background so we don't lock the main thread
 */
- (void)_retrievePlistFromServer
{
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  NSString *urlStr = [LWE_PLUGIN_SERVER stringByAppendingString:LWE_PLUGIN_LIST_REL_URL];
  NSDictionary *plist = [[NSDictionary alloc] initWithContentsOfURL:[NSURL URLWithString:urlStr]];
  if (plist)
  {
    // Ask the plugin manager to deal with it. Wait until done because it needs the plist var to stay around
    [self.pluginMgr performSelectorOnMainThread:@selector(processPlistHash:) withObject:plist waitUntilDone:YES];
  }
  [plist release];
  [pool release];
}

#pragma mark -

//! Standard dealloc
- (void) dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [modalTaskViewController release];
  [pluginMgr release];
  [super dealloc];
}
   
@end
