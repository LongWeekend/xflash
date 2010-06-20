//
//  VersionMigrater.m
//  jFlash
//
//  Created by Mark Makdad on 6/6/10.
//  Copyright 2010 Long Weekend Inc. All rights reserved.
//

#import "VersionManager.h"

/**
 * Migrates the databases and et cetera between versions of JFlash
 */
@implementation VersionManager

@synthesize dlHandler, taskMessage, statusMessage;

/** Custom initializer that sets dlHandler to nil */
- (id) init
{
  if (self = [super init])
  {
    // Initialize to point at nothing
    self.dlHandler = nil;
    self.statusMessage = @"";
    self.taskMessage = @"";
    _progress = 0.0f;
    _cancelRequest = NO;
    _migraterState = kMigraterReady;
    _backgroundThreadPool = nil;
  }
  return self;
}


/**
 * Determine's if the user's database is lagging behind the current version
 * This is a static method as it only needs to access NSUserDefaults to return
 */
+ (BOOL) databaseIsUpdatable
{
  // Get the active database name from settings, compare to the current version.
  NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
  NSString *dataVersion = [settings objectForKey:APP_DATA_VERSION];
  if (dataVersion == nil)
  {
    // If dataVersion doesn't exist, this is a fresh install first load
    return NO;
  }
  else
  {
    // Is the active database the current one?
    if ([dataVersion isEqualToString:JFLASH_CURRENT_VERSION])
      return NO;
    else
      return YES;
  }
}


//! Helper method to call notification in main thread
- (void) postMainThreadNotification:(NSNotification*)aNotification
{
  [[NSNotificationCenter defaultCenter] postNotification:aNotification];
}


//! Gets progress
- (float) progress
{
  return _progress;
}


//! Sets progress
- (void) setProgress:(float)progress
{
  _progress = progress;
  NSNotification *aNotification = [NSNotification notificationWithName:@"MigraterStateUpdated" object:nil];
  [self performSelectorOnMainThread:@selector(postMainThreadNotification:) withObject:aNotification waitUntilDone:NO];
}


/**
 * Changes internal state of Migrater class while also firing a notification as such, returns YES on success
 */
- (BOOL) _updateInternalState:(NSInteger)nextState
{
  _migraterState = nextState;
  LWE_LOG(@"State updated to %d",nextState);
  NSNotification *aNotification = [NSNotification notificationWithName:@"MigraterStateUpdated" object:nil];
  [self performSelectorOnMainThread:@selector(postMainThreadNotification:) withObject:aNotification waitUntilDone:NO];
  return YES;
}


/**
 * Updates task message, then fires _updateInternalState: nextState
 */
- (BOOL) _updateInternalState:(NSInteger)nextState withTaskMessage:(NSString*)taskMsg
{
  [self setTaskMessage:taskMsg];
  [self setProgress:0.0f];
  return [self _updateInternalState:nextState];
}


/** Allows task "parent" to call and know what's going on */
- (BOOL) isSuccessState
{
  if (_migraterState == kMigraterSuccess)
    return YES;
  else
    return NO;
}


/** Allows task "parent" to call and know what's going on */
- (BOOL) isFailureState
{
  switch (_migraterState)
  {
    case kMigraterCancelled:
    case kMigraterDownloadFail:
    case kMigraterUpdateSQLFail:
    case kMigraterUnknownFail:
      return YES;
      break;
  }
  return NO;
}


/**
 * Allows us to hide/show buttons in the view based on the current state
 * Delegated from ModalTaskViewController
 */
- (void) willUpdateButtonsInView:(ModalTaskViewController*)sender
{
  // If not ready, don't show start button
  if (_migraterState != kMigraterReady)
  {
    sender.startButton.hidden = YES;
  }
  else
  {
    sender.startButton.hidden = NO;
  }
  
  // If not failed, don't show retry button
  if (![self isFailureState])
  {
    sender.retryButton.hidden = YES;
  }
  else
  {
    sender.retryButton.hidden = NO;
  }
  
  // Do not allow pause during the update at all
  sender.pauseButton.hidden = YES;
}


/**
 * Asks the dlHandler if the downloader is actively retrieving.  Othewrise returns NO
 */
- (BOOL) canPauseTask
{
  if (_migraterState == kMigraterDownloadPlugins || _migraterState == kMigraterDownloadPaused)
  {
    return [[self dlHandler] canPauseTask];
  }
  else
  {
    return NO;
  }
}


/**
 * ModalTask delegate - returns YES on SQL update
 * Task, if downloading, ask dlHandler delegate instead
 * Otherwise NO
 */
- (BOOL) canCancelTask
{
  if (_migraterState == kMigraterDownloadPlugins)
  {
    // Delegate call
    return [[self dlHandler] canCancelTask];
  }
  else if (_migraterState == kMigraterUpdateSQL || _migraterState == kMigraterReady)
  {
    return YES;
  }
  else
  {
    return NO;
  }
}


/**
 * ModalTask delegate - returns YES if we are in failed state, otherwise NO
 */
- (BOOL) canRetryTask
{
  return [self isFailureState];
}


/**
 * Returns YES if the migrater is ready otherwise NO
 */
- (BOOL) canStartTask
{
  if (_migraterState == kMigraterReady)
    return YES;
  else
    return NO;
}


/** ModalTaskDelegate - startTask */
- (void) startTask
{
  if (_migraterState == kMigraterReady)
  {
    [self _updateInternalState:kMigraterOpenDatabase withTaskMessage:NSLocalizedString(@"Preparing database",@"VersionManager.PreparingDatabaseMsg")];
    [self performSelectorInBackground:@selector(_openDatabase:) withObject:[LWEFile createDocumentPathWithFilename:JFLASH_10_USER_DATABASE]];
  }
}


/**
 * Pauses and unpaused, depending on the state
 * Delegate
 */
- (void) pauseTask
{
  if (_migraterState == kMigraterDownloadPlugins && [[self dlHandler] canPauseTask])
  {
    [[self dlHandler] pauseTask];
    [self _updateInternalState:kMigraterDownloadPaused withTaskMessage:@"Download Paused (2/4)"];
  }
  else if (_migraterState == kMigraterDownloadPaused && [[self dlHandler] canStartTask])
  {
    [[self dlHandler] startTask];
    [self _updateInternalState:kMigraterDownloadPaused withTaskMessage:@"Downloading updated database (2/4)"];
  }
}


/**
 * Sends cancel message, depending on state
 */ 
- (void) cancelTask
{
  if (_migraterState == kMigraterDownloadPlugins && [[self dlHandler] canCancelTask])
  {
    [[self dlHandler] cancelTask];
    [self _updateInternalState:kMigraterCancelled withTaskMessage:NSLocalizedString(@"Update Cancelled",@"VersionManager.UpdateCancelledMsg")];
  }
  else if (_migraterState == kMigraterUpdateSQL)
  {
    // On a background thread, so do not tell it directly, use a semaphore
    _cancelRequest = YES;
  }
}


/**
 * Retries
 */
- (void) retryTask
{
  // Close DB
  LWEDatabase *db = [LWEDatabase sharedLWEDatabase];
  [db closeDatabase];
  
  _migraterState = kMigraterReady;
  
  // Reset the downloader
  [[self dlHandler] resetTask];
}


//! Helper method to instantiate
- (void) _initAutorelease
{
  if (_backgroundThreadPool == nil)
  {
    _backgroundThreadPool = [[NSAutoreleasePool alloc] init];
  }
}


/** 
 * Migration - STEP 1
 * Opens the old version database as the main database
 * Calls _loadFTSPlugin on finish
 */
- (void) _openDatabase:(NSString*)filename
{
  [self _initAutorelease];
  
  // Get the database open and ready
  LWEDatabase *db = [LWEDatabase sharedLWEDatabase];
  if (db.databaseOpenFinished)
  {
    // Already open, so close it once to detach any databases and get JUST the USER database
    [db closeDatabase];
  }
  if (![db openDatabase:filename])
  {
    [NSException raise:@"OldDatabaseNotOpened" format:@"Unable to open existing database for 1.0"];
  }
  [self _updateInternalState:kMigraterDownloadPlugins withTaskMessage:NSLocalizedString(@"Connecting to LWE server",@"VersionManager.BeginningDownloadMsg")];
  [self _downloadFTSPlugin];
  [_backgroundThreadPool release];
  return;  
}


/**
 * Migration - STEP 2
 * Downloads & installs the FTS plugin using LWEDownloader & the PluginManager
 * Registers notification observers "LWE_migraterStateUpdated" and "LWEDownloaderProgressUpdated"
 * to capture any failures on the download side
 */
- (void) _downloadFTSPlugin
{
  // Download the FTS file - even if this is unsuccessful, it doesn't hurt the user
  // They can still access (and will access) the old FTS off their main table -- EVEN if this table is attached.
  PluginManager *pm = [[CurrentState sharedCurrentState] pluginMgr];
  NSDictionary *dict = [[pm availablePluginsDictionary] objectForKey:FTS_DB_KEY];
  NSString *targetURL  = [dict objectForKey:@"target_url"];
  NSString *targetPath = [dict objectForKey:@"target_path"];
  LWEDownloader *tmpDlHandler = [[LWEDownloader alloc] initWithTargetURL:targetURL targetPath:targetPath];
  [tmpDlHandler setDelegate:pm];
  [self setDlHandler:tmpDlHandler];
  [tmpDlHandler release];
  
  // Register a listener to observe the LWEDownloader
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_updateDownloadStatus) name:@"LWEDownloaderStateUpdated" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_updateDownloadStatus) name:@"LWEDownloaderProgressUpdated" object:nil];
  
  // Now go
  [[self dlHandler] startTask];
}


/**
 * Class internal method to get the updated status from LWEDownloader and figure out the overall progress
 * Called via the LWEDownloaderProgressUpdated notification
 */
- (void) _updateDownloadStatus
{
  if ([self dlHandler])
  {
    [self setProgress:[[self dlHandler] progress]];
    [self setTaskMessage:[[self dlHandler] taskMessage]];

    // Determine what to do with buttons based on state
    if ([[self dlHandler] isFailureState])
    {
      LWE_LOG(@"Download failed, oh no, what are we doing to do now");
      NSString *tmpTaskMsg = [NSString stringWithFormat:[[self dlHandler] taskMessage]];
      [self _updateInternalState:kMigraterDownloadFail withTaskMessage:tmpTaskMsg];
    }
    else if ([[self dlHandler] isSuccessState])
    {
      LWE_LOG(@"Download succeeded, now it's time to keep going");
      [[NSNotificationCenter defaultCenter] removeObserver:self];
      [self performSelectorInBackground:@selector(_loadPlugins) withObject:nil];
    }
  }
}



/**
 * Migration - STEP 3
 * Tries to load the FTS plugin
 * Will fail the first time around, so calls plugin download
 * On download complete, it will call this method again.
 * After FTS is successfully loaded, will call _updateUserDatabase
 */
- (void) _loadPlugins
{
  _backgroundThreadPool = [[NSAutoreleasePool alloc] init];
  PluginManager *pm = [[CurrentState sharedCurrentState] pluginMgr];

  // Load FTS plugin
  [pm loadInstalledPlugins];
  BOOL isFTSLoaded, isCardDBLoaded;
  isFTSLoaded = [pm pluginIsLoaded:FTS_DB_KEY];
  isCardDBLoaded = [pm pluginIsLoaded:CARD_DB_KEY];
  
  if (isFTSLoaded && isCardDBLoaded)
  {
    [self _updateInternalState:kMigraterUpdateSQL withTaskMessage:NSLocalizedString(@"Merging new dictionary",@"VersionManager.MergingDBMsg")];
    [self _updateUserDatabase];
  }
  else
  {
    // TODO: put something here to pick up on
  }
  [_backgroundThreadPool release];
}


/**
 * Migration - STEP 4
 * Reads SQL from the bundle SQL file and enters a tight C loop to
 * execute it on the open database.
 */
- (void) _updateUserDatabase
{
  // Init variables
  BOOL success = YES;
  FILE *fh = NULL;
  float lclProgress = 0.0f;
  int numRecords = 100000;
  int i = 0;
  char str_buf[256];

  // Get SQL statement file ready
  fh = fopen([[LWEFile createBundlePathWithFilename:JFLASH_10_TO_11_SQL_FILENAME] UTF8String],"r");
  if (fh == NULL)
  {
    [NSException raise:@"SQLStatementFileNotOpened" format:@"Unable to open/read SQL statement file"];
  }
  
  // Run all the statements
  LWEDatabase *db = [LWEDatabase sharedLWEDatabase];  
  db.dao.traceExecution = NO;
  LWE_LOG(@"Starting transaction");
  [db.dao beginTransaction];
  
  LWE_LOG(@"Starting loop");
  while (!feof(fh))
  {
    if (i < 10)
    {
      LWE_LOG(@"%@",[NSString stringWithCString:str_buf encoding:NSUTF8StringEncoding]);
    }
    
    if (_cancelRequest)
    {
      success = NO;
      break;
    }
    
    fgets(str_buf,256,fh);

    i++;
    if ((i % 500) == 0)
    {
      lclProgress = ((float)i / (float)numRecords);
      [self setProgress:lclProgress];
      LWE_LOG(@"i: %d - progress %f",i,lclProgress);
    }
    
    if (![db executeUpdate:[NSString stringWithCString:str_buf encoding:NSUTF8StringEncoding]])
    {
      success = NO;
      LWE_LOG(@"Unable to do SQL: %@",[NSString stringWithCString:str_buf encoding:NSUTF8StringEncoding]);      
    }
  }
  
  // Close the file
  fclose(fh);
  
  if (success)
  {
    [self _updateInternalState:kMigraterSuccess withTaskMessage:@"Finalizing dictionary"];
    LWE_LOG(@"STARTING COMMIT");
    [db.dao commit];
    LWE_LOG(@"Finished transaction");
    
    // The only thing that is really important is that we ONLY execute this code if and when the transaction is complete.
    NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
    [settings setValue:JFLASH_VERSION_1_1 forKey:@"data_version"];
    [self _updateInternalState:kMigraterSuccess withTaskMessage:@"Completed Successfully"];
  }
  else
  {
    [db.dao rollback];
    [self _updateInternalState:kMigraterUpdateSQLFail withTaskMessage:@"Merge error.  Aborting update."];
  }
}

-(void) dealloc
{
  [super dealloc];
}

@end
