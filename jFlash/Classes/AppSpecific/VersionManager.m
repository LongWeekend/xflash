//
//  VersionMigrater.m
//  jFlash
//
//  Created by Mark Makdad on 6/6/10.
//  Copyright 2010 Long Weekend Inc. All rights reserved.
//

#import "VersionManager.h"
#import "FlurryAPI.h"
#import "TagPeer.h"

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

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cancelTask) name:UIApplicationWillTerminateNotification object:nil];
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
  // Handle the start button
  if (_migraterState == kMigraterReady || [self isFailureState])
  {
    sender.startButton.hidden = NO;
  }
  else
  {
    sender.startButton.hidden = YES;
  }

  // Hide the progress indicator if we are making the index or are failed
  if (_migraterState == kMigraterPrepareSQL || _migraterState == kMigraterReady || [self isFailureState])
  {
    sender.progressIndicator.hidden = YES;
  }
  else
  {
    sender.progressIndicator.hidden = NO;
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
  else if (_migraterState == kMigraterPrepareSQL || _migraterState == kMigraterFinalizeSQL)
  {
    return NO;
  }
  else
  {
    return YES;
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
  if (_migraterState == kMigraterReady || [self canRetryTask])
    return YES;
  else
    return NO;
}


/** ModalTaskDelegate - startTask */
- (void) startTask
{
  if ([self canStartTask] || [VersionManager databaseIsUpdatable])
  {
    _cancelRequest = NO;
    [self _updateInternalState:kMigraterOpenDatabase withTaskMessage:NSLocalizedString(@"Opening Dictionary",@"VersionManager.PreparingDatabaseMsg")];
    [self performSelector:@selector(_checkPlugin) withObject:nil afterDelay:0.1f];
#if defined(APP_STORE_FINAL)
    [FlurryAPI logEvent:@"mergeAttempted"];
#endif
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
  // TODO: this KNOWS too much about the downloader - maybe a call to [self canCancelTask]?
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
  _migraterState = kMigraterReady;
  
  // Reset the downloader
  [[self dlHandler] resetTask];
}


/** 
 * Migration - STEP 1
 */
- (void) _checkPlugin
{
  // Determine the next step - do they already have FTS?
  PluginManager *pm = [[CurrentState sharedCurrentState] pluginMgr];
  if ([pm pluginIsLoaded:FTS_DB_KEY] && [pm pluginIsLoaded:CARD_DB_KEY])
  {
    // SKIP to STEP 3
    [self performSelectorInBackground:@selector(_updateUserDatabase) withObject:nil];
  }
  else
  {
    // STEP 2
    [self _downloadFTSPlugin];
  }
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
  [self _updateInternalState:kMigraterDownloadPlugins withTaskMessage:NSLocalizedString(@"Connecting to our server",@"VersionManager.BeginningDownloadMsg")];
  
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
    if ([[self dlHandler] isFailureState] && _migraterState != kMigraterCancelled)
    {
      LWE_LOG(@"Download failed, oh no, what are we doing to do now");
      NSString *tmpTaskMsg = [[self dlHandler] taskMessage];
      [self _updateInternalState:kMigraterDownloadFail withTaskMessage:tmpTaskMsg];
    }
    else if ([[self dlHandler] isSuccessState])
    {
      LWE_LOG(@"Download succeeded, now it's time to keep going");
      [[NSNotificationCenter defaultCenter] removeObserver:self];
      // STEP 3
      [self performSelectorInBackground:@selector(_updateUserDatabase) withObject:nil];
    }
  }
}


/**
 * Migration - STEP 3
 * Reads SQL from the bundle SQL file and enters a tight C loop to
 * execute it on the open database.
 */
- (void) _updateUserDatabase
{
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  // Init variables
  BOOL success = YES;
  FILE *fh = NULL;
  float lclProgress = 0.0f;
  int numRecords = 12768;
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
  
  // Do the INDEX!!
  [self _updateInternalState:kMigraterPrepareSQL withTaskMessage:NSLocalizedString(@"Preparing new data (~75 seconds)",@"VersionManager.PreparingDBMsg")];
  [db executeUpdate:@"CREATE INDEX IF NOT EXISTS card_tag_link_tag_card_index ON card_tag_link(card_id,tag_id)"];

  // Get rid of this so I can get an exclusive lock on the DB
  [db detachDatabase:FTS_DB_KEY];
  [db detachDatabase:CARD_DB_KEY];
  

  LWE_LOG(@"Starting transaction");
  [db.dao beginTransaction];
  [self _updateInternalState:kMigraterUpdateSQL withTaskMessage:NSLocalizedString(@"Merging Data (~60 seconds)",@"VersionManager.MergingDBMsg")];

  db.dao.traceExecution = NO;
  
  LWE_LOG(@"Starting loop");
  while (!feof(fh))
  {
    if (_cancelRequest)
    {
      success = NO;
      break;
    }
    
    fgets(str_buf,256,fh);

    i++;
    if ((i % 50) == 0)
    {
      lclProgress = ((float)i / (float)numRecords);
      [self setProgress:lclProgress];
      LWE_LOG(@"i: %d - progress %f",i,lclProgress);
    }
    
    if (![db executeUpdate:[NSString stringWithCString:str_buf encoding:NSUTF8StringEncoding]])
    {
      success = NO;
      LWE_LOG(@"Unable to do SQL: %@",[NSString stringWithCString:str_buf encoding:NSUTF8StringEncoding]);
      #if defined(APP_STORE_FINAL)
        NSDictionary *dataToSend = [NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithCString:str_buf encoding:NSUTF8StringEncoding],@"sql",nil];
        [FlurryAPI logEvent:@"mergeFail" withParameters:dataToSend];
      #endif
      break;
    }
  }
  
  // Close the file
  fclose(fh);

  if (success)
  {
    [self _updateInternalState:kMigraterFinalizeSQL withTaskMessage:@"Finalizing (~10 seconds)"];
    LWE_LOG(@"STARTING COMMIT");
    [db.dao commit];
    LWE_LOG(@"Finished transaction");
    
    // The only thing that is really important is that we ONLY execute this code if and when the transaction is complete.
    NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
    [settings setValue:JFLASH_VERSION_1_1 forKey:@"data_version"];
    #if defined(APP_STORE_FINAL)
      [FlurryAPI logEvent:@"mergeSuccess" withParameters:nil];
    #endif

    // TODO: refactor out a "on success method"
    // This is kind of a hack to put here?
    [TagPeer recacheCountsForUserTags];
    
    CurrentState *state = [CurrentState sharedCurrentState];
    [state resetActiveTag];

    // Update internal state
    [self _updateInternalState:kMigraterSuccess withTaskMessage:@"Completed Successfully"];
  }
  else
  {
    [self _rollback:db];
    if (!_cancelRequest) 
    {
      [self _updateInternalState:kMigraterUpdateSQLFail withTaskMessage:@"Merge error: LWE has been notified!"];
    }
  }
  
  // Re-attach the cards & FTS database
  PluginManager *pm = [[CurrentState sharedCurrentState] pluginMgr];
  [pm loadInstalledPlugins];
  [pool release];
}


//! Rolls back an ongoing transaction
- (void) _rollback: (LWEDatabase*) db
{
  if ([db.dao inTransaction])
  {
    [db.dao rollback];
  }
}


-(void) dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [super dealloc];
}

@end
